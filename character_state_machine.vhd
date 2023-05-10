library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------
entity character_state_machine is
port(
  clk: in std_logic;
  reset_n: in std_logic;
  
  timeout: in std_logic;
  
  got_key_up: in std_logic;
  got_shift: in std_logic;
  
  ascii_in: in std_logic_vector(7  downto 0);
  
  wd_kick: out std_logic;
  
  capital: out std_logic;
  
  data_out: out std_logic_vector(15 downto 0);
  write:    out std_logic
);
end entity character_state_machine;
architecture char_SM of character_state_machine is
  signal is_shift_down: std_logic;
  signal await_key_up: std_logic;
  signal last_char: std_logic_vector(7 downto 0);
  
  signal counter: integer;
  
  begin
    
  FSM: process(clk, reset_n) begin
if('0' = reset_n) then 
    capital <= '0';
    data_out <= "0000000000000000";
    write <= '0'; 
    is_shift_down <= '0';
    await_key_up <= '0';
    last_char <= "00000000";
    counter <= 0;
    wd_kick <= '1';
elsif(rising_edge(clk)) then
    wd_kick <= '1';
    write <= '0';
    if("00000000" = ascii_in) then
      wd_kick <= '0';
      if('1' = got_key_up) then await_key_up <= '1';
   	  elsif('1' = got_shift) then is_shift_down <= not await_key_up; await_key_up <= '0';
 	    end if;
 	  elsif('1' = await_key_up and last_char = ascii_in) then
 	    wd_kick <= '0';
 	    counter <= counter - 1;
 	    data_out <= "00000000"&last_char;
 	    write <= '1';
 	    last_char <= "00000000";
 	    await_key_up <= '0';
 	  elsif('1' = await_key_up) then
 	    wd_kick <= '0';
 	    counter <= counter - 1;
 	    data_out <= "00000010"&ascii_in;
 	    write <= '1';
 	    await_key_up <= '0';
 	  elsif('1' = timeout and ("00000000" /= last_char)) then
 	    data_out <= "00000001"&last_char;
 	    last_char <= "00000000";
 	    wd_kick <= '0';
 	  elsif((last_char /= ascii_in) and ("00000000" /= last_char)) then
 	    wd_kick <= '0'; 
 	    data_out <= "00000100"&last_char;
 	    write <= '1';
 	    last_char <= ascii_in;
 	  else last_char <= ascii_in; counter <= counter + 1; end if;
 	  capital <= is_shift_down;
end if;

end process;
 
end architecture;