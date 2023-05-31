library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------
entity ps2_topmodule is
  port(
  clk: in std_logic;
  as_reset_n: in std_logic;
  
  rx: in std_logic;
  
  get_char: out std_logic_vector(15 downto 0);
  is_empty: out std_logic;
  char_req: in std_logic
  );
  
end entity ps2_topmodule;

architecture topmodule of ps2_topmodule is
  
  constant baude_rate:  integer   := 9600;
--constant cpb:         integer   := 20833;
  constant cpb:         integer   := 50;
  
  signal wd_kick: std_logic;
  signal ready: std_logic;
  signal rx2bus_and_p: std_logic_vector(8 downto 0);
  signal rx2bus:  std_logic_vector(7 downto 0);
  signal timeout: std_logic;
  signal state: std_logic;
  signal ascii: std_logic_vector (7 downto 0);
  signal got_shift: std_logic;
  signal got_key_up: std_logic;
  signal char: std_logic_vector (15 downto 0);
  signal write2fifo: std_logic;
  signal parity: std_logic;
  signal empty: std_logic;
  
  --signal rx_ready: std_logic;
  signal ready_ack: std_logic;
    
  
  begin
  
  RECIEVER: entity work.uart_transceiver(rtl)
  generic  map(
    metastable_filter_bypass_host     => false,
		metastable_filter_bypass_recover  => false,
		clk_pulses_per_baud              => cpb,
		transmit_receiver_error_codes	   => true,
		data_bits							                 => 9,
		odd_parity_on						              => false
  )
  port map(
    clk						                    => clk,
		raw_reset_n					             => as_reset_n,
                    
		rx							        	       => rx,
		tx						   		             => open,
                
		got_falling_edge_on_rx			    => wd_kick,
		ready_2_read				             => ready,
		read_strobe				              => ready_ack,
		read_strobe_ack				          => open,
		data_out					        	       => rx2bus_and_p,
		ready_2_write			    	    	   => open,
		write_strobe				             => '0',
		write_strobe_ack				         => open,
		data_in					                 => (others => '0'),
                
		recover_receiver_n 		        => '1',
		recover_receiver_n_ack			    => open,
		recover_transmitter_n		      => '1',
		recover_transmitter_n_ack	   => open,
		receiver_error_code		        => open,
		transmitter_error	         	 => open,
        
    dbg_falling_edge_rx          => open,  
    dbg_error_code_send_request  => open,
    dbg_receiver_error_code_sent => open,
    dbg_state_rx                 => open,
    dbg_state_tx                 => open,
		dbg_parity_error_injection	  => '0'
  );
  DECODER: entity work.character_ty_decoder(rtl)
  port map(
        clk => clk,
        reset_n => as_reset_n,
        state => state,
        data_in => rx2bus,
        data_out => ascii,
        shift => got_shift,
        release => got_key_up,
        rx_ready => ready,
        ready_ack => ready_ack
);

FSM: entity work.character_state_machine(char_SM)
  port map(
        clk => clk,
        reset_n => as_reset_n,
        timeout => timeout,
        got_key_up => got_key_up,
        got_shift => got_shift,
        ascii_in => ascii,
        wd_kick => open,
        capital => state,
        data_out => char,
        write => write2fifo
  );
  
  WD: entity work.watchdog(rtl)
  generic map(
            countdown => 1024
    )

    port map (
                    clk         => clk,
                    reset_n     => as_reset_n,
                    rx          => wd_kick,
                    cout        => timeout
                );
  
  
  BUF: entity work.edac_protected_fifo(rtl)
  generic map(
    metastable_filter_bypass_push                 => true,
		metastable_filter_bypass_pop                  => true,
		metastable_filter_bypass_flush                => true,
		metastable_filter_bypass_reset_error_flags_n  => true,
		memory_model                                  => "UNPROTECTED_BRAM",
		address_width 									                       => 8,
		data_width                                    => 16,
		edac_latency  								                        => 6,
		prot_bram_scrubber_present                    => false,
		prot_bram_scrb_prescaler_width                => 1,
		prot_bram_scrb_timer_width                    => 1,
		init_from_file                                => false,
		initfile_path                                 => "",
		initfile_format                               => ""
  )
	port map(
		clk 				=> clk,
		raw_reset_n 	=> as_reset_n,
		push 				=>	write2fifo,
		data_in 			=> char,
		pop 				=>	char_req,
		data_out 		=> get_char,
		empty 			=>	empty,
		
---------------------------------------------------------------------------
		flush							=>	'0' 	,
		flush_ack					=>	open 	,
		push_ack						=>	open	,
		push_performed				=>	open 	,
		pop_ack						=>	open 	,
		pop_performed				=>	open 	,
		full							=>	open 	,
		free_space					=>	open 	,
		reset_error_flags_n		=>	'1'	,
		reset_error_flags_n_ack	=>	open 	,
		uncorrectable_error		=>	open 	
--------------------------------------------------------------------------
	);
  
  is_empty <= empty;
  
  PARITY_CHECK: process(rx2bus_and_p) 
  variable tmp: STD_LOGIC;
  begin
  for i in 0 to 7 loop
    tmp := rx2bus_and_p(8) xor rx2bus_and_p(i);
  end loop;
  parity <= tmp;
  end process;
              
  DATA_INTEGRITY: process (clk, as_reset_n)
  --variable parity: std_logic;
  begin
    if('0' = parity) then
     rx2bus <= rx2bus_and_p(7 downto 0);
   end if;
  end process;
  
  
end architecture;
    