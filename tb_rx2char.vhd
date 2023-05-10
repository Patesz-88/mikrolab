library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-----------------------------------------------------------------------------------
entity testbench_ps2_to_ascii is
end entity testbench_ps2_to_ascii;
-----------------------------------------------------------------------------------
architecture ps2_to_ascii_testbench of testbench_ps2_to_ascii is 

constant clk_p: 	     time 		   := 5 ns;
constant data_bits:   integer   := 8;
constant baude_rate:  integer   := 9600;
--constant cpb:         integer   := 20833;
constant cpb:         integer   := 50;

signal clk:			      std_logic := '1';
signal reset_n:	    std_logic	:= '0';

signal wd_kick:  std_logic;
signal timeout: std_logic;

signal ps2_in: std_logic_vector (7 downto 0) := "00000000";

signal ascii_out: std_logic_vector (7 downto 0) := "00000000";
signal char_out: std_logic_vector (15 downto 0) := "0000000000000000";

signal state: std_logic;
signal got_shift: std_logic;
signal got_key_up: std_logic;
signal write: std_logic;

begin
  
DECODER: entity work.character_ty_decoder(rtl)
  port map(
        clk => clk,
        reset_n => reset_n,
        state => state,
        data_in => ps2_in,
        data_out => ascii_out,
        shift => got_shift,
        release => got_key_up
);

FSM: entity work.character_state_machine(char_SM)
  port map(
        clk => clk,
        reset_n => reset_n,
        timeout => timeout,
        got_key_up => got_key_up,
        got_shift => got_shift,
        ascii_in => ascii_out,
        wd_kick => wd_kick,
        capital => state,
        data_out => char_out,
        write => write
  );
  
  WD: entity work.watchdog(rtl)
  generic map(
            countdown => 8
    )

    port map (
                    clk         => clk,
                    reset_n     => reset_n,
                    rx          => wd_kick,
                    cout        => timeout
                );
  
  CLOCK: process begin 
  wait for clk_p/2;
  clk 		    <= not clk;
  end process;
  
  TEST: process begin
  wait for 4*clk_p;
  reset_n <= '1';
  ps2_in <= x"1C";
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  
  wait for 4*clk_p;
  ps2_in <= x"12";
  wait for 4*clk_p;
  ps2_in <= x"1C";
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"12";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  
  wait for 4*clk_p;
  ps2_in <= x"12";
  wait for 4*clk_p;
  ps2_in <= x"1C";

  wait for 10*clk_p;
  
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"12";
  wait for 2*clk_p;
  ps2_in <= x"1C";

  wait for 10*clk_p;

  wait for 4*clk_p;
  ps2_in <= x"00";
  wait for 2*clk_p;
  ps2_in <= x"1C";
  
  
  
  end process;
  



end architecture;