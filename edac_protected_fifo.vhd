library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------------------------
entity edac_protected_fifo is
	generic (
		metastable_filter_bypass_push:					boolean;
		metastable_filter_bypass_pop:					boolean;
		metastable_filter_bypass_flush:					boolean;
		metastable_filter_bypass_reset_error_flags_n:	boolean;
		memory_model:									string;
		address_width:									integer range 2 to 8;
		data_width:										integer range 2 to 16;
		edac_latency:									integer range 1 to 10;
		prot_bram_scrubber_present:						boolean;
		prot_bram_scrb_prescaler_width:					integer range 1 to 18;
		prot_bram_scrb_timer_width:						integer range 1 to 24;
		init_from_file:									boolean;
		initfile_path:									string;
		initfile_format:								string
	);
	
	port (
		clk:						in	std_logic;
		raw_reset_n:				in	std_logic;
		flush:						in	std_logic;
		flush_ack:					out	std_logic;
		push:						in	std_logic;
		push_ack:					out	std_logic;
		push_performed:				out	std_logic;
		pop:						in	std_logic;
		pop_ack:					out	std_logic;
		pop_performed:				out	std_logic;
		full:						out	std_logic;
		empty:						out	std_logic;
		data_in:					in	std_logic_vector (data_width-1 downto 0);
		data_out:					out	std_logic_vector (data_width-1 downto 0);
		free_space:					out	std_logic_vector (address_width downto 0);
		reset_error_flags_n:		in	std_logic;
		reset_error_flags_n_ack:	out	std_logic;
		uncorrectable_error:		out	std_logic
	);
end entity edac_protected_fifo;
---------------------------------------------------------------------------------------------------
architecture rtl of edac_protected_fifo is

	-- Reset synchronizer resources
	signal ff_reset_n:						std_logic;
	signal as_reset_n:						std_logic;
			
	-- Metastable filter resources		
	signal ff_flush:						std_logic;
	signal flush_filtered:					std_logic;
	signal flush_internal:					std_logic;
	signal ff_push:							std_logic;
	signal push_filtered:					std_logic;
	signal push_internal:					std_logic;
	signal ff_push_internal:				std_logic;
	signal push_internal_rising_edge:		std_logic;
	signal ff_pop:							std_logic;
	signal pop_filtered:					std_logic;
	signal pop_internal:					std_logic;
	signal ff_pop_internal:					std_logic;
	signal pop_internal_rising_edge:		std_logic;
	signal ff_reset_error_flags_n:			std_logic;
	signal reset_error_flags_n_filtered:	std_logic;
	signal reset_error_flags_n_internal:	std_logic;
	
	-- FIFO logic resources
	signal we_edacram:						std_logic;
	signal re_edacram:						std_logic;
	signal waddress_edacram:				std_logic_vector (address_width-1 downto 0);
	signal raddress_edacram:				std_logic_vector (address_width-1 downto 0);
	signal data_2_edacram:					std_logic_vector (data_width-1 downto 0);
	signal free_space_in_fifo:  			integer range 0 to 2**address_width;

begin

	assert ( memory_model = "UNPROTECTED_REG" or memory_model = "UNPROTECTED_BRAM" or memory_model = "PROTECTED_BRAM" ) report "Memory model error!" severity failure;

	-- Reset circuitry: Active-LOW asynchronous assert, synchronous deassert with meta-stable filter.
	L_RESET_CIRCUITRY:	process ( clk, raw_reset_n )
	begin
		if ( raw_reset_n = '0' ) then
			ff_reset_n <= '0';
			as_reset_n <= '0';
		elsif ( rising_edge(clk) ) then
			ff_reset_n <= '1';
			as_reset_n <= ff_reset_n;
		end if;
	end process;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	L_METASTABLE_FILTER_BLOCK: process ( clk, as_reset_n )
	begin
		if ( as_reset_n = '0' ) then
			ff_flush <= '0';
			flush_filtered <= '0';
			ff_push <= '0';
			push_filtered <= '0';
			ff_pop <= '0';
			pop_filtered <= '0';
			ff_reset_error_flags_n <= '0';
			reset_error_flags_n_filtered <= '0';
		elsif ( rising_edge(clk) ) then
			ff_flush <= flush;
			flush_filtered <= ff_flush;
			ff_push <= push;
			push_filtered <= ff_push;
			ff_pop <= pop;
			pop_filtered <= ff_pop;
			ff_reset_error_flags_n <= reset_error_flags_n;
			reset_error_flags_n_filtered <= ff_reset_error_flags_n;
		end if;
	end process;
	
	L_METASTABLE_FILTER_BYPASS: block
	begin
		flush_internal <= flush when metastable_filter_bypass_flush = true else flush_filtered;
		push_internal <= push when metastable_filter_bypass_push = true else push_filtered;
		pop_internal <= pop when metastable_filter_bypass_pop = true else pop_filtered;
		reset_error_flags_n_internal <= reset_error_flags_n when metastable_filter_bypass_reset_error_flags_n = true else reset_error_flags_n_filtered;
	end block;
	
	L_METASTABLE_FILTER_ACKNOWLEDGE: block
	begin
		push_ack <= push_internal;
		pop_ack <= pop_internal;
		flush_ack <= flush_internal;
		reset_error_flags_n_ack <= reset_error_flags_n_internal;
	end block;
	
	L_PUSHPOP_EDGE_DETECTORS: block
	begin
		process ( clk, as_reset_n )
		begin
			if ( as_reset_n = '0' ) then
				ff_push_internal <= '0';
				ff_pop_internal <= '0';
			elsif ( rising_edge(clk) ) then
				ff_push_internal <= push_internal;
				ff_pop_internal <= pop_internal;
			end if;
		end process;
		push_internal_rising_edge <= not ff_push_internal and push_internal;
		pop_internal_rising_edge <= not ff_pop_internal and pop_internal;
	end block;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	L_FIFO_2_EDACRAM_ADAPTER: process ( clk, as_reset_n )
		
		variable read_pointer:			unsigned (address_width-1 downto 0);
		variable write_pointer:			unsigned (address_width-1 downto 0);
		variable vfull:					std_logic;
		variable vempty:				std_logic;
		variable v_free_space_in_fifo:	integer range 0 to 2**address_width;
	
	begin
		if ( as_reset_n = '0' ) then
			vfull := '0'; vempty := '1';
			read_pointer := ( others => '0' );
			write_pointer := ( others => '0' );
			full <= '0';
			empty <= '1';
			waddress_edacram <= (others => '0');
			raddress_edacram <= (others => '0');
			data_2_edacram <= (others => '0');
			we_edacram <= '0';
			re_edacram <= '0';
			free_space_in_fifo <= 2**address_width - 1;
			v_free_space_in_fifo := 2**address_width - 1;
		elsif ( rising_edge(clk) ) then
		
			we_edacram <= '0';
			re_edacram <= '0';
			
			if ( flush_internal = '1' ) then
				vfull := '0'; vempty := '1';
				read_pointer := ( others => '0' );
				write_pointer := ( others => '0' );
				full <= '0';
				empty <= '1';
				waddress_edacram <= (others => '0');
				raddress_edacram <= (others => '0');
				data_2_edacram <= (others => '0');
				we_edacram <= '0';
				re_edacram <= '0';
				free_space_in_fifo <= 2**address_width - 1;
				v_free_space_in_fifo := 2**address_width - 1;
			else
			
				if ( push_internal_rising_edge = '1' and vfull /= '1' ) then
					-- write data into the error FIFO
					we_edacram <= '1';
					waddress_edacram <= std_logic_vector(write_pointer);
					data_2_edacram <= data_in;
					write_pointer := write_pointer + 1;
					v_free_space_in_fifo := v_free_space_in_fifo - 1;
					if ( write_pointer = read_pointer - 1 ) then vfull := '1'; else vfull := '0'; end if;
					vempty := '0';
				end if;
				
				if ( pop_internal_rising_edge = '1' and vempty /= '1' ) then
					-- read data from the error FIFO
					re_edacram <= '1';
					raddress_edacram <= std_logic_vector(read_pointer);
					read_pointer := read_pointer + 1;
					v_free_space_in_fifo := v_free_space_in_fifo + 1;
					if ( write_pointer = read_pointer ) then vempty := '1'; else vempty := '0'; end if;
					vfull := '0';
				end if;
			
				full <= vfull;
				free_space_in_fifo <= v_free_space_in_fifo;
				empty <= vempty;
			
			end if;
			
		end if;
	end process;
	
	free_space <= std_logic_vector(to_unsigned(free_space_in_fifo, address_width + 1));

	--------------------------------------------------------
    --------------------------------------------------------
    --------------------------------------------------------
	
	L_MEM_UNPROTECTED_REG:	if ( memory_model = "UNPROTECTED_REG" ) generate
		L_EDACRAM:	entity work.edac_protected_ram(unprotected_reg)
						generic map (
							address_width 						=> address_width,
							data_width 							=> data_width,
							edac_latency 						=> edac_latency,
							prot_bram_registered_in				=> false,
							prot_bram_registered_out			=> true,
							prot_bram_scrubber_present			=> prot_bram_scrubber_present,
							prot_bram_scrb_prescaler_width		=> prot_bram_scrb_prescaler_width,
							prot_bram_scrb_timer_width			=> prot_bram_scrb_timer_width,
							init_from_file						=> init_from_file,
							initfile_path						=> initfile_path,
							initfile_format						=> initfile_format
						)
							
						port map (
							clk					=> clk,
							as_reset_n			=> as_reset_n,
							reset_error_flags_n	=> reset_error_flags_n_internal,
							uncorrectable_error	=> uncorrectable_error,
							correctable_error	=> open,
							we					=> we_edacram,
							we_ack				=> push_performed,
							re					=> re_edacram,
							re_ack				=> pop_performed,
							write_address 		=> waddress_edacram,
							read_address		=> raddress_edacram,
							data_in				=> data_2_edacram,
							data_out			=> data_out,
							error_injection								=> "00",
							force_scrubbing								=> '0',
							scrubber_invalid_state_error				=> open,
							scrubber_recover_fsm_n						=> '1',
							dbg_scrubber_invalid_state_error_injection 	=> '0'
						);
	end generate;
	
	L_MEM_UNPROTECTED_BRAM:	if ( memory_model = "UNPROTECTED_BRAM" ) generate
		L_EDACRAM:	entity work.edac_protected_ram(unprotected_bram)
						generic map (
							address_width 						=> address_width,
							data_width 							=> data_width,
							edac_latency 						=> edac_latency,
							prot_bram_registered_in				=> false,
							prot_bram_registered_out			=> true,
							prot_bram_scrubber_present			=> prot_bram_scrubber_present,
							prot_bram_scrb_prescaler_width		=> prot_bram_scrb_prescaler_width,
							prot_bram_scrb_timer_width			=> prot_bram_scrb_timer_width,
							init_from_file						=> init_from_file,
							initfile_path						=> initfile_path,
							initfile_format						=> initfile_format
						)
							
						port map (
							clk					=> clk,
							as_reset_n			=> as_reset_n,
							reset_error_flags_n	=> reset_error_flags_n_internal,
							uncorrectable_error	=> uncorrectable_error,
							correctable_error	=> open,
							we					=> we_edacram,
							we_ack				=> push_performed,
							re					=> re_edacram,
							re_ack				=> pop_performed,
							write_address 		=> waddress_edacram,
							read_address		=> raddress_edacram,
							data_in				=> data_2_edacram,
							data_out			=> data_out,
							error_injection								=> "00",
							force_scrubbing								=> '0',
							scrubber_invalid_state_error				=> open,
							scrubber_recover_fsm_n						=> '1',
							dbg_scrubber_invalid_state_error_injection 	=> '0'
						);
	end generate;
	
	L_MEM_PROTECTED_BRAM:	if ( memory_model = "PROTECTED_BRAM" ) generate
		L_EDACRAM:	entity work.edac_protected_ram(protected_bram)
						generic map (
							address_width 						=> address_width,
							data_width 							=> data_width,
							edac_latency 						=> edac_latency,
							prot_bram_registered_in				=> false,
							prot_bram_registered_out			=> true,
							prot_bram_scrubber_present			=> prot_bram_scrubber_present,
							prot_bram_scrb_prescaler_width		=> prot_bram_scrb_prescaler_width,
							prot_bram_scrb_timer_width			=> prot_bram_scrb_timer_width,
							init_from_file						=> init_from_file,
							initfile_path						=> initfile_path,
							initfile_format						=> initfile_format
						)
							
						port map (
							clk					=> clk,
							as_reset_n			=> as_reset_n,
							reset_error_flags_n	=> reset_error_flags_n_internal,
							uncorrectable_error	=> uncorrectable_error,
							correctable_error	=> open,
							we					=> we_edacram,
							we_ack				=> push_performed,
							re					=> re_edacram,
							re_ack				=> pop_performed,
							write_address 		=> waddress_edacram,
							read_address		=> raddress_edacram,
							data_in				=> data_2_edacram,
							data_out			=> data_out,
							error_injection								=> "00",
							force_scrubbing								=> '0',
							scrubber_invalid_state_error				=> open,
							scrubber_recover_fsm_n						=> '1',
							dbg_scrubber_invalid_state_error_injection 	=> '0'
						);
	end generate;

end architecture rtl;
---------------------------------------------------------------------------------------------------