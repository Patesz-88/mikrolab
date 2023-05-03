library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------
entity character_state_machine is
generic(
  data_bits: integer range 8 to 16
);
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
elsif(rising_edge(clk)) then
    write <= '0';
    if("00000000" = ascii_in) then
      if('1' = got_key_up) then await_key_up <= '1';
   	  elsif('1' = got_shift) then is_shift_down <= not await_key_up; await_key_up <= '0';
 	    end if;
 	  elsif('1' = await_key_up and last_char = ascii_in) then
 	    counter <= counter - 1;
 	    data_out <= "00000000"&last_char;
 	    write <= '1';
 	  elsif('1' = await_key_up) then
 	    counter <= counter - 1;
 	    data_out <= "00000010"&ascii_in;
 	    write <= '1';
 	  elsif('1' = timeout) then
 	    data_out <= "00000001"&last_char;
 	  elsif(not last_char = ascii_in) then 
 	    data_out <= "00000100"&last_char;
 	    write <= '1';
 	    last_char <= ascii_in;
 	  else last_char <= ascii_in; counter <= counter + 1; end if;
end if;

end process;
  
end architecture;