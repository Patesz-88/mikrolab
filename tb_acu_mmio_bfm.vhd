library ieee;
use ieee.std_logic_1164.all;
---------------------------------------------------------------------------------------------------
entity tb_acu_mmio_bfm is
end entity tb_acu_mmio_bfm;
---------------------------------------------------------------------------------------------------
architecture behavior of tb_acu_mmio_bfm is

	signal generate_read_cycle:						std_logic	 					:= '0';
	signal generate_write_cycle:					std_logic						:= '0';
	signal address:									std_logic_vector (15 downto 0) 	:= (others => '0');
	signal data_2_write:							std_logic_vector (15 downto 0)	:= (others => '0');
	signal data_read:								std_logic_vector (15 downto 0);
	signal busy:									std_logic;
	signal interrupt_received_and_acknowledged:		std_logic;
	
	signal clk_bfm:									std_logic						:= '0';
	signal clk_uart:								std_logic						:= '1';
	signal raw_reset_n:								std_logic						:= '1';
	signal uart_intr_rqst:							std_logic;
	signal acu_intr_ack:							std_logic;
	signal acu_write_strobe:						std_logic;
	signal acu_read_strobe:							std_logic;
	signal uart_ready:								std_logic;
	signal acu_address:								std_logic_vector (15 downto 0);
	signal acu_data:								std_logic_vector (15 downto 0);
	signal uart_data:								std_logic_vector (15 downto 0);
	signal rx:										std_logic						:= '1';
	signal tx:										std_logic;


  constant clk_p: 	time 			:= 20 ns;
  constant cpb:         integer   := 50;
begin

	L_CLOCK_BFM: process
	begin
		wait for 32 ns;
		loop
			wait for 10 ns;
			clk_bfm <= not clk_bfm;
		end loop;
	end process;

	L_CLOCK_UART: process
	begin
		wait for 25 ns;
		clk_uart <= not clk_uart;
	end process;

	L_ACU_MMIO_BFM:	entity work.acu_mmio_bfm(behavior)
						port map (
							generate_read_cycle						=> generate_read_cycle,
							generate_write_cycle					=> generate_write_cycle,
							address									=> address,
							data_2_write							=> data_2_write,
							data_read								=> data_read,
							busy									=> busy,
							interrupt_received_and_acknowledged		=> interrupt_received_and_acknowledged,
							clk										=> clk_bfm,
							intr_rqst								=> uart_intr_rqst,
							intr_ack								=> acu_intr_ack,
							write_strobe							=> acu_write_strobe,
							read_strobe								=> acu_read_strobe,
							dmem_ready								=> uart_ready,
							address_2_dmem							=> acu_address,
							data_from_dmem							=> uart_data,
							data_2_dmem								=> acu_data
						);
	
	
	L_MMIO_USER_MODULE: entity work.acu_mmio_peripheral_template(ps2_keyboard_controller)
	generic map(
	metastable_filter_bypass_acu => false,
	metastable_filter_bypass_recover_fsm_n => false,
	generate_intr => true,
	my_address_1 =>							4,
	my_address_2 =>							5
	
	)
	port map(
	 clk => clk_bfm,
		raw_reset_n=> raw_reset_n,
		
		-- ACU memory-mapped I/O interface
		read_strobe_from_acu => acu_read_strobe,
		write_strobe_from_acu => acu_write_strobe,
		ready_2_acu					=> uart_ready,
											address_from_acu			=> acu_address,
											data_from_acu				=> acu_data,
											data_2_acu					=> uart_data,
											intr_rqst					=> uart_intr_rqst,
											intr_ack					=> acu_intr_ack,
											rx							=> rx,
		-- ...
		-- ...
		-- ...
		
		-- FSM error interface
		invalid_state_error			=> open,
											recover_fsm_n				=> '1',
											recover_fsm_n_ack			=> open
	);
	  
										
	L_TEST_SEQUENCE: process
	begin
	
		wait for 230 ns;
		raw_reset_n <= '0';
		wait for 450 ns;
		raw_reset_n <= '1';
		
		wait for 1 us;
		
		address <= X"0005";		
		generate_read_cycle <= '1';
		wait until falling_edge(busy);
		generate_read_cycle <= '0';
		
		wait for 4*clk_p;
  
  --new packet
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'a'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  --NEW PACKET
  wait for 5*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --'a'*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 4*cpb*clk_p;
  
  wait for 4*cpb*clk_p;
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --shift
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  --new packet
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '1';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'h'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  
  --new packet*/
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '1';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'h'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  --new packet*/
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
   --shift
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  
  wait for 5*cpb*clk_p;
  
 --new packet*/
  wait for 1*cpb*clk_p;
  rx <= '0';            --start bit
  
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'e'
  
  wait for 1*cpb*clk_p;
  rx <= '0';            --parity bit: even
  
  wait for 1*cpb*clk_p;
  rx <= '1';            --stop bit(s)
  
  wait for 4*cpb*clk_p;
  --new packet
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  --key up
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
  --NEW PACKET
  wait for 5*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  --data bits
  rx <= '0';  --LSB
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '1';
  wait for 1*cpb*clk_p;
  rx <= '0';
  wait for 1*cpb*clk_p;
  rx <= '0';  --MSB
  --'e'
  
  wait for 1*cpb*clk_p;
  rx <= '0';
  
  wait for 1*cpb*clk_p;
  rx <= '1';
		
		wait for 1 us;
		
		address <= X"0004";		-- ready to write
		generate_read_cycle <= '1';
		wait until falling_edge(busy);
		generate_read_cycle <= '0';
		 
		wait for 1 us;
		
		address <= X"0005";		
		generate_read_cycle <= '1';
		wait until falling_edge(busy);
		generate_read_cycle <= '0';
	
		wait;
	end process;

end architecture behavior;
---------------------------------------------------------------------------------------------------