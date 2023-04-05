library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------------------------------------
entity testbench_uart is
end entity testbench_uart;
-----------------------------------------------------------------------------------
architecture uart_testbench of testbench_uart is 

constant clk_p: 	     time 		   := 5ns;
constant data_bits:   integer   := 8;
constant baude_rate:  integer   := 9600;

signal clk:			      std_logic := '0';
signal reset_n:	    std_logic	:= '0';

signal rx:		        std_logic := '1';

signal wd_kick      std_logic := '1';

signal data_out:	   std_logic_vector (data_bits-1 downto 0);
signal ready:       std_logic := '0';

signal get_data:    std_logic := '0';
signal handshake:   std_logic := '0';

begin

RECIEVER: entity work.uart_transciever(rtl)
  generic  map(
    metastable_filter_bypass_host     => true,
		metastable_filter_bypass_recover  => true,
		clk_pulses_per_baud:              => baude_rate,
		transmit_receiver_error_codes:	   => true,
		data_bits:							                 => data_bits,
		odd_parity_on:						              => true
  )
  port map(
    clk:						                    => clk,
		raw_reset_n:					             => reset_n,
                    
		rx:							        	       => rx,
		tx:						   		             => open,
                
		got_falling_edge_on_rx:			    => not wd_kick,
		ready_2_read:				             => ready,
		read_strobe:				              => get_data,
		read_strobe_ack:				          => open,
		data_out:					        	       => data_out,
		ready_2_write:			    	    	   => open,
		write_strobe:				             => '0',
		write_strobe_ack:				         => open,
		data_in:					                 => '0',
                
		recover_receiver_n: 		        => '1',
		recover_receiver_n_ack:			    => open,
		recover_transmitter_n:		      => '1',
		recover_transmitter_n_ack:	   => open,
		receiver_error_code:		        => open,
		transmitter_error:	         	 => open,
        
    dbg_falling_edge_rx:          => open,  
    dbg_error_code_send_request:  => open,
    dbg_receiver_error_code_sent: => open,
    dbg_state_rx:                 => open,
    dbg_state_tx:                 => open,
		dbg_parity_error_injection:	  => '0'
  )
