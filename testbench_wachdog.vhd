library ieee;
use ieee.std_logic_1164.all;
--------------------------------------------------
entity testbench_wachdog is
end entity testbench_wachdog;
--------------------------------------------------
architecture behavior of testbench_counter is

    constant clock_period:  time := 100 ns;
    
    signal clk:             std_logic := '0';
    signal reset_n:         std_logic := '0';
    signal rx:              std_logic := '1';
    signal cout:            std_logic;

begin

    L_DUT:  entity work.whachdog(rtl)
                port map (
                    clk         => clk,
                    reset_n     => reset_n,
                    rx          => rx,
                    cout        => cout
                );

    L_TEST_SEQUENCE: process
    begin
        wait for 200 ns;  
        reset_n <= '1';
        wait for 500 ns;
        rx <= '0';
        wait for 100 ns;
        rx <= '1';
        wait for 100 ns;
        rx <= '0';
        
        
    end process;
    
    -- create clock
    L_CLOCK: process
    begin
        wait for clock_period / 2;
        clk <= not clk;
    end process;

end architecture behavior;
--------------------------------------------------
