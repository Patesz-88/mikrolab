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





end architecture rtl;