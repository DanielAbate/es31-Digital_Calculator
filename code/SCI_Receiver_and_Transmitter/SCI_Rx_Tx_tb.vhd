--------------------------------------------------------------------------------
-- Course:	 		Engs 31 16S
--
-- Create Date:   17:11:39 07/25/2009
-- Design Name:   
-- Module Name:   SerialRx_tb.vhd
-- Project Name:  Lab5
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SerialRx
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
 
ENTITY SCI_Rx_Tx_tb IS
END SCI_Rx_Tx_tb;
 
ARCHITECTURE behavior OF SCI_Rx_Tx_tb IS 
 COMPONENT SCI_Tx IS
    PORT ( 	clk			: 	in 	STD_LOGIC;
		Parallel_in	: 	in 	STD_LOGIC_VECTOR(7 downto 0);
        New_data	:	in	STD_LOGIC;
        Tx			:	out STD_LOGIC);
end COMPONENT;

COMPONENT SCI_Rx IS
Port ( Clk : in STD_LOGIC; --clock
           RsRx  : in  STD_LOGIC; --received bit stream
           rx_shift : out STD_LOGIC; --for testing 
           rx_data : out STD_LOGIC_VECTOR (7 downto 0); -- data byte
           rx_done_tick : out  STD_LOGIC );
   end COMPONENT;
   
   
   signal clk : std_logic := '0';
   signal RsRx_sig : std_logic := '1';
   signal rx_data_sig : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
   signal rx_done_tick_sig : std_logic := '0';
   signal Tx_sig : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 10ns;		-- 100 MHz clock
   constant clk_period_sim : time := 100us;	
	
	-- Data definitions
-- 	constant bit_time : time := 104us;		-- 9600 baud
	constant bit_time : time := 8.7us;		-- 115,200 baud
	
	constant TxData : std_logic_vector(7 downto 0) := "01101001"; --0xe9
    

	

BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: SCI_Tx PORT MAP (
          clk => clk,
          Parallel_in => rx_data_sig,
          New_data =>  rx_done_tick_sig,
          Tx => Tx_sig
        );
   dut: SCI_Rx PORT MAP (
        clk => clk,
        RsRx => RsRx_sig, 
        rx_shift => open, 
        rx_data => rx_data_sig, 
        rx_done_tick => rx_done_tick_sig
        );
          

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
		wait for 100 us;
		wait for 10.25*clk_period_sim;		
		
		RsRx_sig <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx_sig <= Txdata(bitcount);--send 0xe9
			wait for bit_time;
		end loop;
		
		RsRx_sig <= '1';		-- Stop bit
		wait for 200 us;
		
		RsRx_sig <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			RsRx_sig <= not( Txdata(bitcount));--send 0x16
			wait for bit_time;
		end loop;
		
		RsRx_sig <= '1';		-- Stop bit
		
		wait;
   end process;
END;
