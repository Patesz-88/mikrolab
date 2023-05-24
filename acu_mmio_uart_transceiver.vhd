library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.uart_transceiver_globals_pkg.all;
---------------------------------------------------------------------------------------------------
entity acu_mmio_uart_transceiver is
	generic (
		metastable_filter_bypass_recover_fsm_n:	boolean							:= false;
		metastable_filter_bypass_acu:			boolean							:= false;
		generate_intr_on_uart_reception:		boolean							:= true;
		clk_pulses_per_baud:			    	integer range 50 to 200000		:= 434;
		transmit_receiver_error_codes:	    	boolean							:= false;
		data_bits:								integer range 8 to 16			:= 8;
		odd_parity_on:							boolean							:= true;
		
		address_ready_2_read:					integer range 0 to 65535;
		address_ready_2_write:					integer range 0 to 65535;
		address_data:							integer range 0 to 65535;
		address_error_code:						integer range 0 to 65535;
		address_recover_transceiver:			integer range 0 to 65535
	);
	
	port (
		clk:						in	std_logic;
		raw_reset_n:				in	std_logic;
		
		-- ACU memory-mapped I/O interface
		read_strobe_from_acu:		in	std_logic;
		write_strobe_from_acu:		in	std_logic;
		ready_2_acu:				out	std_logic;
		address_from_acu:			in	std_logic_vector (15 downto 0);
		data_from_acu:				in	std_logic_vector (15 downto 0);
		data_2_acu:					out	std_logic_vector (15 downto 0);
		
		-- ACU interrupt interface
		intr_rqst:					out	std_logic;
		intr_ack:					in	std_logic;
		
		-- UART PHY
		rx:							in	std_logic;
		tx:							out	std_logic;
		
		-- FSM error interface
		invalid_state_error:		out	std_logic;
		recover_fsm_n:				in	std_logic;
		recover_fsm_n_ack:			out	std_logic
	);
end entity acu_mmio_uart_transceiver;
---------------------------------------------------------------------------------------------------
architecture rtl of acu_mmio_uart_transceiver is

	-- Reset synchronizer resources
	signal ff_reset_n:						std_logic;
	signal as_reset_n:						std_logic;
		
	-- Metastable filter resources	
	signal ff_write_strobe_from_acu:		std_logic;
	signal write_strobe_from_acu_filtered:	std_logic;
	signal write_strobe_from_acu_internal:	std_logic;
	signal ff_read_strobe_from_acu:			std_logic;
	signal read_strobe_from_acu_filtered:	std_logic;
	signal read_strobe_from_acu_internal:	std_logic;
	signal ff_recover_fsm_n:				std_logic;
	signal recover_fsm_n_filtered:			std_logic;
	signal recover_fsm_n_internal:			std_logic;
	signal ff_intr_ack:						std_logic;
	signal intr_ack_filtered:				std_logic;
	signal intr_ack_internal:				std_logic;
	
	-- Interrupt generation resources
	signal intr_ready_2_read:				std_logic;
	signal intr_ready_2_read_d:				std_logic;
	signal intr_ready_2_read_rising:		std_logic;
	
	type state_t is (
		idle,
		write_ut,
		recover_transceiver,
		read_ut,
		read_ready_2_read,
		read_ready_2_write,
		read_error_code,
		wait_for_deassert_strobes,
		error
	);
	signal state: state_t;
	-- attribute syn_preserve: boolean;
	-- attribute syn_preserve of state:signal is true;
	
	signal cs:								std_logic;
	signal s_data_2_acu:					std_logic_vector (data_bits-1 downto 0);
	signal s_ready_2_acu:					std_logic;
	signal ut_ready_2_read:					std_logic;
	signal ut_read_strobe:					std_logic;
	signal ut_data_out:						std_logic_vector (data_bits-1 downto 0);
	signal ut_ready_2_write:				std_logic;
	signal ut_write_strobe:					std_logic;
	signal ut_data_in:						std_logic_vector (data_bits-1 downto 0);
	signal ut_receiver_error_code:			std_logic_vector (2 downto 0);
	signal ut_transmitter_error:			std_logic;
	signal ut_invalid_state_error:			std_logic;
	signal adapter_invalid_state_error:		std_logic;
	signal adapter_recover_transceiver_n:	std_logic;
	signal recover_n_2_ut:					std_logic;
	
begin

	assert address_ready_2_read /= address_ready_2_write report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_read /= address_data report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_read /= address_error_code report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_read /= address_recover_transceiver report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_write /= address_data report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_write /= address_error_code report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_ready_2_write /= address_recover_transceiver report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_data /= address_error_code report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_data /= address_recover_transceiver report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	assert address_error_code /= address_recover_transceiver report "ACU MMIO UART TRANSCEIVER ADDRESSING ERROR!" severity failure;
	
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
	
	L_METASTBLE_FILTER_BLOCK: process ( clk, as_reset_n )
	begin
		if ( as_reset_n = '0' ) then
			ff_write_strobe_from_acu <= '0';
			write_strobe_from_acu_filtered <= '0';
			ff_read_strobe_from_acu <= '0';
			read_strobe_from_acu_filtered <= '0';
			ff_recover_fsm_n <= '1';
			recover_fsm_n_filtered <= '1';
			ff_intr_ack <= '0';
			intr_ack_filtered <= '0';
		elsif ( rising_edge(clk) ) then
			ff_write_strobe_from_acu <= write_strobe_from_acu;
			write_strobe_from_acu_filtered <= ff_write_strobe_from_acu;
			ff_read_strobe_from_acu <= read_strobe_from_acu;
			read_strobe_from_acu_filtered <= ff_read_strobe_from_acu;
			ff_recover_fsm_n <= recover_fsm_n;
			recover_fsm_n_filtered <= ff_recover_fsm_n;
			ff_intr_ack <= intr_ack;
			intr_ack_filtered <= ff_intr_ack;
		end if;
	end process;
	
	L_METASTABLE_FILTER_BYPASS: block
	begin
		write_strobe_from_acu_internal <= write_strobe_from_acu when metastable_filter_bypass_acu = true else write_strobe_from_acu_filtered;
		read_strobe_from_acu_internal <= read_strobe_from_acu when metastable_filter_bypass_acu = true else read_strobe_from_acu_filtered;
		recover_fsm_n_internal <= recover_fsm_n when metastable_filter_bypass_recover_fsm_n = true else recover_fsm_n_filtered;
		intr_ack_internal <= intr_ack when metastable_filter_bypass_acu = true else intr_ack_filtered;
	end block;
	
	L_METASTABLE_FILTER_ACKNOWLEDGE: block
	begin
		recover_fsm_n_ack <= recover_fsm_n_internal;
	end block;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	L_INTR_GENERATION: block
	begin
		
		intr_ready_2_read <= ut_ready_2_read when generate_intr_on_uart_reception = true else '0';
		
		process ( clk, as_reset_n )
		begin
			if ( as_reset_n = '0' ) then
				intr_ready_2_read_d <= '0';
				intr_rqst <= '0';
			elsif ( rising_edge(clk) ) then
				intr_ready_2_read_d <= intr_ready_2_read;
				
				if ( intr_ack_internal = '1' ) then
					intr_rqst <= '0';
				elsif ( intr_ready_2_read_rising = '1' ) then
					intr_rqst <= '1';
				end if;
				
			end if;
		end process;
		intr_ready_2_read_rising <= intr_ready_2_read and not intr_ready_2_read_d;
		
	end block;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	L_LOCAL_ADDRESS_DECODER: block
	begin
		cs <= '1' when (unsigned(address_from_acu) = address_ready_2_read or
						unsigned(address_from_acu) = address_ready_2_write or
						unsigned(address_from_acu) = address_data or
						unsigned(address_from_acu) = address_error_code or
						unsigned(address_from_acu) = address_recover_transceiver) else '0';
		ready_2_acu <= s_ready_2_acu when cs = '1' else '0';
		data_2_acu(data_bits-1 downto 0) <= s_data_2_acu when cs = '1' else (others => '0');
		data_2_acu(15 downto data_bits) <= (others => '0');
	end block;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	L_ACU_2_UART_ADAPTER: process ( clk, as_reset_n )
	begin
		if ( as_reset_n = '0' ) then
			state <= idle;
			s_ready_2_acu <= '0';
			s_data_2_acu <= (others => '0');
			ut_read_strobe <= '0';
			ut_write_strobe <= '0';
			ut_data_in <= (others => '0');
			adapter_invalid_state_error <= '0';
			adapter_recover_transceiver_n <= '1';
		elsif ( rising_edge(clk) ) then
			case state is
				when idle	=>	s_ready_2_acu <= '1';
								
								-- Handle ACU writes
								if ( write_strobe_from_acu_internal = '1' and cs = '1' ) then
									
									s_ready_2_acu <= '0';
									
									if ( unsigned(address_from_acu) = address_data ) then
										state <= write_ut;
									elsif ( unsigned(address_from_acu) = address_recover_transceiver ) then
										state <= recover_transceiver;
									else
										state <= wait_for_deassert_strobes;
									end if;
									
								end if;
								
								-- Handle ACU reads
								if ( read_strobe_from_acu_internal = '1' and cs = '1') then
									
									s_ready_2_acu <= '0';
									
									if ( unsigned(address_from_acu) = address_ready_2_read ) then
										state <= read_ready_2_read;
									elsif ( unsigned(address_from_acu) = address_ready_2_write ) then
										state <= read_ready_2_write;
									elsif ( unsigned(address_from_acu) = address_error_code ) then
										state <= read_error_code;
									else
										state <= read_ut;
									end if;
									
								end if;
				
				----------------------------------------------------------------------------------------------
				
				when write_ut	=>	ut_data_in <= data_from_acu(data_bits-1 downto 0);
									ut_write_strobe <= '1';
									state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
				
				when recover_transceiver	=>	adapter_recover_transceiver_n <= '0';
												state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
				
				when read_ut	=>	s_data_2_acu <= ut_data_out;
									ut_read_strobe <= '1';
									state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
								
				when read_ready_2_read	=>	s_data_2_acu(0) <= ut_ready_2_read;
											s_data_2_acu(data_bits-1 downto 1) <= (others => '0');
											state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
				
				when read_ready_2_write	=>	s_data_2_acu(0) <= ut_ready_2_write;
											s_data_2_acu(data_bits-1 downto 1) <= (others => '0');
											state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
				
				when read_error_code	=>	s_data_2_acu(3) <= ut_transmitter_error;
											s_data_2_acu(2 downto 0) <= ut_receiver_error_code;
											s_data_2_acu(data_bits-1 downto 4) <= (others => '0');
											state <= wait_for_deassert_strobes;
				
				----------------------------------------------------------------------------------------------
				
				when wait_for_deassert_strobes	=>	ut_write_strobe <= '0';
													adapter_recover_transceiver_n <= '1';
													ut_read_strobe <= '0';
													if ( read_strobe_from_acu_internal = '0' and write_strobe_from_acu_internal = '0' ) then
														state <= idle;
													end if;
													
				----------------------------------------------------------------------------------------------
				
				when error	=>	-- reset all
								s_ready_2_acu <= '0';
								s_data_2_acu <= (others => '0');
								ut_read_strobe <= '0';
								ut_write_strobe <= '0';
								ut_data_in <= (others => '0');
								adapter_recover_transceiver_n <= '1';
								
								if ( recover_fsm_n_internal = '0' ) then
									adapter_invalid_state_error <= '0';
									state <= idle;
								end if;
								
				when others	=>	adapter_invalid_state_error <= '1';
								state <= error;
			end case;
		end if;
	end process;
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	recover_n_2_ut <= recover_fsm_n_internal and adapter_recover_transceiver_n;
	
	L_UART_TRANSCEIVER:	entity work.uart_transceiver(rtl)
							generic map (
								metastable_filter_bypass_host		=> true,
								metastable_filter_bypass_recover	=> metastable_filter_bypass_recover_fsm_n,
								clk_pulses_per_baud					=> clk_pulses_per_baud,
								transmit_receiver_error_codes		=> transmit_receiver_error_codes,
								data_bits							=> data_bits,
								odd_parity_on						=> odd_parity_on
							)
							
							port map (
								clk								=> clk,
								raw_reset_n						=> raw_reset_n,
								rx								=> rx,
								tx								=> tx,
								got_falling_edge_on_rx			=> open,
								ready_2_read					=> ut_ready_2_read,
								read_strobe						=> ut_read_strobe,
								read_strobe_ack					=> open,
								data_out						=> ut_data_out,
								ready_2_write					=> ut_ready_2_write,
								write_strobe					=> ut_write_strobe,
								write_strobe_ack				=> open,
								data_in							=> ut_data_in,
								recover_receiver_n				=> recover_n_2_ut,
								recover_receiver_n_ack			=> open,
								recover_transmitter_n			=> recover_n_2_ut,
								recover_transmitter_n_ack		=> open,
								receiver_error_code				=> ut_receiver_error_code,
								transmitter_error				=> ut_transmitter_error,
								dbg_falling_edge_rx				=> open,
								dbg_error_code_send_request		=> open,
								dbg_receiver_error_code_sent	=> open,
								dbg_state_rx					=> open,
								dbg_state_tx					=> open,
								dbg_parity_error_injection		=> '0'
							);
							
	ut_invalid_state_error <= '1' when ut_receiver_error_code = e_rec_invalid_state_error or ut_transmitter_error = '1' else '0';
	
	--------------------------------------------------------
	--------------------------------------------------------
	--------------------------------------------------------
	
	invalid_state_error <= 	adapter_invalid_state_error or ut_invalid_state_error;

end architecture rtl;
---------------------------------------------------------------------------------------------------