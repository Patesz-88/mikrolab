library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity serial2paralel is
	generic (
	  data_bits: integer range 1 to 16
	  );
	  port(
	    clk:     in  std_logic;
	    reset_n: in  std_logic;
	    clk_ps2: in  std_logic;
	    rx:      in  std_logic;
	    
	    wd_kick: out std_logic;
	    data:    out std_logic_vector (data_bits-1 downto 0)
	    );
end entity serial2paralel;

architecture ps2_in of serial2paralel is
  signal data_in: unsigned(data_bits-1 downto 0);
  signal strobe:  std_logic;
  signal parity: std_logic;
  begin
    SERIAL_IN: process (clk_ps2, strobe, reset_n)
      variable count: integer;
      
    begin
      if(reset_n = '0') then
          data_in <= (others => '0');
          data <= (others => '0');
          wd_kick <= '1';
          count := 0;
      elsif ( falling_edge(clk_ps2)) then
        if (strobe = '1') then
            count := 0;
            wd_kick <= '0';
        elsif (count < 10) then
            count := count +  1;
            wd_kick <= '1';
        end if;
        CASE count IS
        
WHEN 0 => strobe <= '1';
          
        WHEN 1 => data_in <= data_in(data_bits-2 downto 0) & rx;
            	     WHEN 2 => data_in <= data_in(data_bits-2 downto 0) & rx;
                          WHEN 3 => data_in <= data_in(data_bits-2 downto 0) & rx;
                              WHEN 4 => data_in <= data_in(data_bits-2 downto 0) & rx;
              
                                WHEN 5 => data_in <= data_in(data_bits-2 downto 0) & rx;
                                   WHEN 6 => data_in <= data_in(data_bits-2 downto 0) & rx;
                                     WHEN 7 => data_in <= data_in(data_bits-2 downto 0) & rx;
                                      WHEN 8 => data_in <= data_in(data_bits-2 downto 0) & rx;
                      
                                      WHEN 9 => parity <= rx;
                        
                                      WHEN 10 => strobe <= '0';
                      
                                      WHEN OTHERS => NULL;
         END CASE;
      end if;
end process;
end architecture;
    