library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------------------------
entity buffer_interface is
	generic(
		depth: integer range 0 to 65535;
		
	);
	port (
		clk:						in	std_logic;
		reset_n:					in	std_logic;
		put_char:				in std_logic_vector(15 downto 0);
		get_char:				out std_logic_vector(15 downto 0);
		user_logic_intr		out std_logic
		);
		
architecture character_buffer of buffer_interface is
	signal char_out: 			std_logic_vector(15 downto 0);
	signal char_in:			std_logic_vector(15 downto 0);
	signal intr:				std_logic;
	signal space:  			integer range 0 to 2**depth;