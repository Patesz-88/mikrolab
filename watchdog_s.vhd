library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------
entity watchdog is
    generic (
        countdown: integer range 0 to 128 :=128-- kérdéses érték
    );

    port (
        clk:            in  std_logic;
        reset_n:        in  std_logic;
        rx:             in  std_logic;
        cout:           out std_logic
    );
end entity watchdog;
--------------------------------------------------
architecture rtl of watchdog is
    
    signal counter:     integer range 0 to countdown;
    
begin

    L_COUNTER: process (clk, reset_n)
    begin
        if ( reset_n = '0' ) then counter <= 0;
        elsif ( rising_edge(clk) ) then
            if (rx='1') then
                
                counter <= countdown;
                elsif(counter > 0 )then
                counter <= counter - 1;
                
                
            end if;
        end if;
    end process;
    
    L_OUTPUT: cout <= '1' when counter = 0 else '0' ;

end architecture rtl;
--------------------------------------------------
