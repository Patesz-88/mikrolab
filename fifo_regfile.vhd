---------------------------------------------------------------------------------------------------
-- Project name: Reusable
-- Submodule/macrocell name: Regular Bytestream DAQ protocol (RBDP)
-- File name: fifo_regfile.vhd
-- Author: Péter Horváth
-- Version: 1.2

---------------------------------------------------------------------------------------------------
-- THE PRESENT SOFTWARE IS THE PROPERTY OF C3S ELECTRONICS DEVELOPMENT LLC.
-- THE CONTENT SHALL NOT BE DISTRIBUTED, SOLD OR REPUBLISHED
-- WITHOUT THE PERMISSION OF C3S ELECTRONICS DEVELOPMENT LLC.
---------------------------------------------------------------------------------------------------

-- Description:

--	The module describes a general-purpose circular buffer.
--	The FIFO depth and word size are synthesis parameters.
--	The content is NOT intended to be implemented using Block-RAM.

---------------------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------------------------
entity fifo_regfile is
	generic (
		data_bits:							integer range 8 to 16;				-- The number of bits in a single word.
		data_bytes:							integer range 1 to 16				-- The number of words stored in the FIFO.
	);
	
	port (
		clk:							in	std_logic;
		as_reset_n:						in	std_logic;
		
		clear_n:						in	std_logic;
		
		-- pop interface
		empty:							out	std_logic;									-- Active-HIGH status output.
		read_strobe:					in	std_logic;									-- Active-HIGH control pulse.
		read_data:						out	std_logic_vector (data_bits-1 downto 0);
		
		-- push interface
		full:							out	std_logic;									-- Active-HIGH status output.
		write_strobe:					in	std_logic;									-- Active-HIGH control pulse.
		write_data:						in	std_logic_vector (data_bits-1 downto 0)
	);
end entity fifo_regfile;
---------------------------------------------------------------------------------------------------
architecture rtl of fifo_regfile is

	type content_t is array (0 to data_bytes-1) of std_logic_vector (data_bits-1 downto 0);
	signal content: content_t;

begin

	L_FIFO: process ( clk, as_reset_n )
	
		variable read_pointer:	integer range 0 to data_bytes-1;
		variable write_pointer:	integer range 0 to data_bytes-1;
		variable vfull:			std_logic;
		variable vempty:		std_logic;
	
	begin
		
		if ( as_reset_n = '0' ) then
			read_pointer := 0;
			write_pointer := 0;
			vfull := '0';
			vempty := '1';
			content <= ( others => ( others => '0' ) );
			empty <= '1';
			full <= '0';
			read_data <= ( others => '0' );
		elsif ( rising_edge(clk) ) then
		
			-----------
			-- WRITE --
			-----------
		
			if ( write_strobe = '1' and vfull /= '1' ) then
				
				-- write data to the FIFO
				content(write_pointer) <= write_data;
				
				-- adjust write pointer
				if ( write_pointer = (data_bytes-1) ) then
					write_pointer := 0;
				else
					write_pointer := write_pointer + 1;
				end if;
				
				-- adjust flags
				if ( write_pointer = read_pointer ) then vfull := '1'; else vfull := '0'; end if;
				vempty := '0';
				
			end if;
			
			----------
			-- READ --
			----------
			
			if ( read_strobe = '1' and vempty /= '1' ) then
				
				-- read data from the FIFO
				read_data <= content(read_pointer);
				
				-- adjust read pointer
				if ( read_pointer = (data_bytes-1) ) then
					read_pointer := 0;
				else
					read_pointer := read_pointer + 1;
				end if;

				-- adjust flags
				if ( write_pointer = read_pointer ) then vempty := '1'; else vempty := '0'; end if;
				vfull := '0';
				
			end if;
			
			-----------
			-- CLEAR --
			-----------
			
			if ( clear_n = '0' ) then
				read_pointer := 0;
				write_pointer := 0;
				vfull := '0';
				vempty := '1';
				content <= ( others => ( others => '0' ) );
				empty <= '1';
				full <= '0';
				read_data <= ( others => '0' );
			end if;
		
			empty <= vempty;
			full <= vfull;
			
		
		end if;
		
	end process;

end architecture rtl;
---------------------------------------------------------------------------------------------------