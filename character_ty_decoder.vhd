library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
----------------------------------
entity character_ty_decoder is
    generic (
        data_bit: integer range 8 to 16;
        shift: integer range 0 to 16
    );

    port(
        clk:        in std_logic;
        reset_n:    in std_logic;
        data_in:    in std_logic_vector (data_bit-1 downto 0);
        data_out:   out std_logic_vector (15 downto 0);
        c_type:     out std_logic_vector (1 downto 0)
    );


end entity character_ty_decoder;
------------------------------
architecture rtl of character_ty_decoder is
    
begin

    L_DECODER: process (clk,reset_n)
    begin
        if(reset_n= '0')then
            data_out <=0;
            c_type <=0;
        elsif (rising_edge(clk))then

            case data_in is
                when "16" |"F016"=>  -- 1
                    data_out<= x"31";
                when "1E" |"F01E"=>  -- 2

                when "26" |"F026"=>  -- 3

                when "25" |"F025"=>  -- 4

                when "2E" |"F02E"=>  -- 5

                when "36" |"F036"=>  -- 6

                when "3D" |"F03D"=>  -- 7

                when "3E" |"F03E"=>  -- 8

                when "46" |"F046"=>  -- 9

                when "45" |"F045"=>  -- 0
        
            end case;

        end if;
    end process;


end architecture rtl;