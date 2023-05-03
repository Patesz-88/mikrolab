library ieee;
use ieee.std_logic_1164.all;
--------------------------------------------------
entity testbench_character_ty_decoder is
end entity testbench_character_ty_decoder;
--------------------------------------------------
architecture behavior of testbench_character_ty_decoder is


    constant clock_period:  time := 100 ns;
    
    signal clk:             std_logic := '0';
    signal reset_n:         std_logic := '0';
    signal state:           std_logic := '0';
    signal data_in:         std_logic_vector (7 downto 0):="00000000";
    signal data_out:        std_logic_vector (7 downto 0):="00000000";
    signal shift:           std_logic:='0';
    signal release:         std_logic:='0';

begin

    L_DUT:  entity work.character_ty_decoder(rtl)


    port map (
        clk        => clk,
        reset_n    => reset_n,
        state      => state,
        data_in     =>data_in,
        data_out   => data_out,
        shift      => shift,
        release    => release
    );

    L_TEST_SEQUENCE: process
    begin
        wait for 200 ns;  
        reset_n <= '1';
        wait for 200 ns;data_in <= b"00101110";
        wait for 100 ns;data_in <= b"01000100";
        
        wait for 100 ns;
        state <='1';
        wait for 100 ns;data_in <= b"01000100";
        wait for 200 ns;data_in <= b"00101110";
        wait for 200 ns;data_in <=b"00011010";
        wait for 200 ns;data_in <=b"00000000";
        wait for 200 ns;data_in <=b"00011010";
        wait for 200 ns;data_in <=b"00010010";
        wait for 200 ns;data_in <= b"00101110";


        wait for 10000 ns;
        
        
    end process;
     -- create clock
     L_CLOCK: process
     begin
         wait for clock_period / 2;
         clk <= not clk;
     end process;
 
 end architecture behavior;