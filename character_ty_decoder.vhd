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
        state:      in std_logic;
        data_in:    in std_logic_vector (data_bit-1 downto 0);
        data_out:   out std_logic_vector (15 downto 0);
        c_type:     out std_logic_vector (1 downto 0)
    );


end entity character_ty_decoder;
------------------------------
architecture rtl of character_ty_decoder is
    signal ps2_code     :STD_LOGIC_VECTOR(7 downto 0);
    signal ascii        :STD_LOGIC_VECTOR(7 downto 0);
begin

    L_DECODER: process (clk,reset_n)
    begin
        if(reset_n= '0')then
            data_out <="0000000000000000";
            c_type <="0";
        elsif (rising_edge(clk))then
          ps2_code<=data_in;
            case ps2_code is
                when x"16" => data_out<= x"31"; -- 1
                when x"1E" => data_out<= x"32"; -- 2
                when x"26" => data_out<= x"33"; -- 3
                when x"25" => data_out<= x"34"; -- 4
                when x"2E" => data_out<= x"35"; -- 5
                when x"36" => data_out<= x"36"; -- 6
                when x"3D" => data_out<= x"37"; -- 7
                when x"3E" => data_out<= x"38"; -- 8
                when x"46" => data_out<= x"39"; -- 9
                when x"45" => data_out<= x"30"; -- 0
                WHEN OTHERS => NULL;
                end case;

            IF(state = '0') THEN  --letter is lowercase
                CASE ps2_code IS              
                  WHEN x"1C" => ascii <= x"61"; --a
                  WHEN x"32" => ascii <= x"62"; --b
                  WHEN x"21" => ascii <= x"63"; --c
                  WHEN x"23" => ascii <= x"64"; --d
                  WHEN x"24" => ascii <= x"65"; --e
                  WHEN x"2B" => ascii <= x"66"; --f
                  WHEN x"34" => ascii <= x"67"; --g
                  WHEN x"33" => ascii <= x"68"; --h
                  WHEN x"43" => ascii <= x"69"; --i
                  WHEN x"3B" => ascii <= x"6A"; --j
                  WHEN x"42" => ascii <= x"6B"; --k
                  WHEN x"4B" => ascii <= x"6C"; --l
                  WHEN x"3A" => ascii <= x"6D"; --m
                  WHEN x"31" => ascii <= x"6E"; --n
                  WHEN x"44" => ascii <= x"6F"; --o
                  WHEN x"4D" => ascii <= x"70"; --p
                  WHEN x"15" => ascii <= x"71"; --q
                  WHEN x"2D" => ascii <= x"72"; --r
                  WHEN x"1B" => ascii <= x"73"; --s
                  WHEN x"2C" => ascii <= x"74"; --t
                  WHEN x"3C" => ascii <= x"75"; --u
                  WHEN x"2A" => ascii <= x"76"; --v
                  WHEN x"1D" => ascii <= x"77"; --w
                  WHEN x"22" => ascii <= x"78"; --x
                  WHEN x"35" => ascii <= x"79"; --y
                  WHEN x"1A" => ascii <= x"7A"; --z
                  WHEN OTHERS => NULL;
                END CASE;
              ELSE                                     --letter is uppercase
                CASE ps2_code IS            
                  WHEN x"1C" => ascii <= x"41"; --A
                  WHEN x"32" => ascii <= x"42"; --B
                  WHEN x"21" => ascii <= x"43"; --C
                  WHEN x"23" => ascii <= x"44"; --D
                  WHEN x"24" => ascii <= x"45"; --E
                  WHEN x"2B" => ascii <= x"46"; --F
                  WHEN x"34" => ascii <= x"47"; --G
                  WHEN x"33" => ascii <= x"48"; --H
                  WHEN x"43" => ascii <= x"49"; --I
                  WHEN x"3B" => ascii <= x"4A"; --J
                  WHEN x"42" => ascii <= x"4B"; --K
                  WHEN x"4B" => ascii <= x"4C"; --L
                  WHEN x"3A" => ascii <= x"4D"; --M
                  WHEN x"31" => ascii <= x"4E"; --N
                  WHEN x"44" => ascii <= x"4F"; --O
                  WHEN x"4D" => ascii <= x"50"; --P
                  WHEN x"15" => ascii <= x"51"; --Q
                  WHEN x"2D" => ascii <= x"52"; --R
                  WHEN x"1B" => ascii <= x"53"; --S
                  WHEN x"2C" => ascii <= x"54"; --T
                  WHEN x"3C" => ascii <= x"55"; --U
                  WHEN x"2A" => ascii <= x"56"; --V
                  WHEN x"1D" => ascii <= x"57"; --W
                  WHEN x"22" => ascii <= x"58"; --X
                  WHEN x"35" => ascii <= x"59"; --Y
                  WHEN x"1A" => ascii <= x"5A"; --Z
                  WHEN OTHERS => NULL;
                END CASE;
              END IF;
            

        end if;
    end process;


end architecture rtl;