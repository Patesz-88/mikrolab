library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------------------------------------
entity testbench_fifo is
end entity testbench_fifo;
-----------------------------------------------------------------------------------
architecture buffer_testbench of testbench_fifo is 

constant clk_p: 	time 			:= 5 ns;

signal clk:			std_logic 	:= '0';
signal reset_n:	std_logic	:= '0';

signal push:		std_logic	:= '0';
signal data_in: 	std_logic_vector(15 downto 0) := x"0000";

signal pop:			std_logic	:= '0';
signal data_out:	std_logic_vector(15 downto 0) := x"0000";

signal empty:		std_logic	:=	'0';

begin

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
		raw_reset_n 	=> reset_n,
		push 				=>	push,
		data_in 			=> data_in,
		pop 				=>	pop,
		data_out 		=> data_out,
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
CLOCK: process begin 
wait for clk_p/2;
clk 		    <= not clk;
end process;
TEST: process begin
wait for 4*clk_p;
reset_n 	 <= '1';
wait for 2*clk_p;
data_in 	 <= x"0101";
wait for 2*clk_p;
push		    <= '1';
wait for 1*clk_p;
data_in 	 <= x"1010";
wait for 1*clk_p;
push 		   <= '0';
wait for 1*clk_p;
push		    <= '1';
wait for 1*clk_p;
push 		   <= '0';
wait for 4*clk_p;
pop       <= '1';
wait for 1*clk_p;
pop       <= '0';
wait for 2*clk_p;
data_in   <= x"1001";
push      <= '1';
pop       <= '1';
wait for 2*clk_p;
push      <= '0';
pop       <= '0';
wait for 4*clk_p;
data_in 	 <= x"1111";
push      <= '1';
wait for 1*clk_p;
push      <= '0';
wait for 1*clk_p;
pop       <= '1';
wait for 4*clk_p;
data_in 	 <= x"0110";
push      <= '1';
wait for 1*clk_p;
push      <= '0';
wait for 1*clk_p;
data_in 	 <= x"0000";
push      <= '1';
wait for 1*clk_p;
pop       <= '0';
wait for 1*clk_p;
push      <= '0';
wait for 2*clk_p;
pop       <= '1';
wait for 1*clk_p;
pop       <= '0';
wait for 1*clk_p;
pop       <= '1';
wait for 1*clk_p;
pop       <= '0';
wait for 1*clk_p;
pop       <= '1';
wait for 1*clk_p;
pop       <= '0';
wait for 4*clk_p;
pop       <= '1';
wait for 1*clk_p;
pop       <= '0';



end process;

end architecture;