library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------------------------------------
entity testbench_top is
end entity testbench_top;

architecture top_testbench of testbench_top is
  constant clk_p: 	time 			:= 5 ns;
  constant cpb:         integer   := 50;

  signal clk:			std_logic 	:= '0';
  signal reset_n:	std_logic	:= '0';
  signal get_char: std_logic_vector(15 downto 0);
  signal intr: std_logic;
  signal req: std_logic:='0';
  
  signal rx: std_logic := '1';
  
  begin
  
  TOP: entity work.ps2_topmodule(topmodule)
   port map(
  clk =>  clk,
  as_reset_n => reset_n,
  
  rx => rx,
  
  get_char => get_char,
  user_logic_intr_output => intr,
  char_req => req
  );
  
  CLOCK: process begin 
  wait for clk_p/2;
  clk 		    <= not clk;
  end process;
  TEST: process begin
  wait for 4*clk_p;
  reset_n <= '1';
  wait for 4*clk_p;
  
  --new packet
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'a'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  --NEW PACKET
  wait for 5*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --'a'*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 4*cpb*clk_p;
  
  wait for 4*cpb*clk_p;
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --shift
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  --new packet
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '1';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'h'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  
  --new packet*/
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '1';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'h'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --shift
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  
 --new packet*/
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'e'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  --new packet
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  --NEW PACKET
  wait for 5*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'e'
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 4*cpb*clk_p;
  
    
end process;
  
end architecture;
