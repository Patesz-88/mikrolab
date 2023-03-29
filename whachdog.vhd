library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--------------------------------------------------
entity counter is
    generic (
        countdown: integer := 256; -- kérdéses érték
        reg_size:  integer range 0 to 6534;
    );
    port (
        clk:            in  std_logic;
        reset_n:        in  std_logic;
        rx:             in  std_logic;
        cout:           out std_logic;
    );
end entity counter;
--------------------------------------------------
architecture rtl of counter is
    
    signal counter:     std_logic_vector (reg_size downto 0) := (others => '0');
    
begin

    L_COUNTER: process (clk, reset_n)
    begin
        if ( reset_n = '0' ) then counter <= (others => '0');
        elsif ( rising_edge(clk) ) then
            if (rx=0) then
                
                counter <= countdown;
                else
                counter <= std_logic_vector(unsigned(counter) - 1);
                
                
            end if;
        end if;
    end process;
    
    L_OUTPUT: cout <= counter;

end architecture rtl;
--------------------------------------------------
