-- Code your design here

----------------------------------------------------------------------------------
-- Company: 			Engs 31 22S
-- 
-- Create Date:    	    05/26/2022
-- Design Name: 		Final project (SCI interface)
-- Module Name:    	    SerialTx - Behavioral 
-- Project Name: 		
-- Target Devices: 	    
-- Tool versions: 	   
-- Description: 		Serial asynchronous transmitter for 
--
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

ENTITY SCI_Tx IS
PORT ( 	clk			: 	in 	STD_LOGIC;
		Parallel_in	: 	in 	STD_LOGIC_VECTOR(7 downto 0);
        New_data	:	in	STD_LOGIC;
        Tx			:	out STD_LOGIC);
end SCI_Tx;


ARCHITECTURE behavior of SCI_Tx is


--Datapath elements

--constant BAUD_PERIOD : integer := 104; --baud rate of 9600 and clock of 1 MHz 
constant BAUD_PERIOD : integer := 87;--baud rate of 115,200 and clock of 10 MHz 

signal Shift_Reg : std_logic_vector(9 downto 0) := (others => '1');
signal Baud_Counter : unsigned(8 downto 0) := (others => '0'); -- 9 bits are needed to represent 391.
signal Bit_Counter : unsigned(4 downto 0) := (others => '0');


signal baud_tc, bit_tc: std_logic := '0';  -- baud counter terminal count


--Queue(for storing data inputted data) signals

type regfile is array(0 to 7) of std_logic_vector(7 downto 0);
signal Queue_reg : regfile:= (others => (others => '0'));
--signal data_out : std_logic_vector(7 downto 0) := (others => '0');  -- data out from queue
signal W_ADDR : integer := 0;   -- write address
signal R_ADDR : integer := 0;   -- read address
signal full : std_logic := '0';
signal empty : std_logic := '1';
signal read : std_logic ;



BEGIN


--Datapath
datapath : process(clk)
begin
	if rising_edge(clk) then
    	
        --Baud Counter
        baud_tc <= '0';
        Baud_Counter <= Baud_Counter + 1;
        if (Baud_Counter = BAUD_PERIOD-1) then
        	baud_tc <= '1';
            Baud_Counter <= (others => '0');
        end if;
        -- not sure here!! Come back
        if (read = '1') then
        	Baud_Counter <= (others => '0');
        end if;
        
        --Bit Counter
        bit_tc <= '0';    
        if baud_tc = '1' then   --  if a new iput is loaded in
        	Bit_Counter <= Bit_Counter + 1; -- increment bit cntr
        	if Bit_Counter = 9 then  --if 8 bits shifted
            	Bit_Counter <= (others => '0');
        		bit_tc  <= '1';
            end if;
        end if;
        
        --Shift Register
        read <= '0';
        if (bit_tc = '1' and empty = '0') then 
        --load data into shift register
            Shift_Reg <= '1' & Queue_reg(R_ADDR) & '0'; -- concatenate data from quue
            --bit_counter <= "0000";   -- clear the bit counter
            read <= '1';
        elsif (baud_tc = '1') then  -- enable shift
            Shift_Reg <= '1' & Shift_Reg(9 downto 1); --shift the bits and add an idle bit to the MSB 
        end if;


--queue_proc : process(clk):
--begin
	--if rising_edge(clk) then 
      
        -- Writing to queue
        if New_data = '1' and full = '0' then  -- if not full and there's incoming data
           empty <= '0';
            --add item to queue at a particular address
            Queue_reg(W_ADDR) <= Parallel_in;  --store the parallel data into register
            W_ADDR <= W_ADDR + 1; -- increment address
        	if (R_ADDR = W_ADDR + 1) then
        		full <= '1';
            end if;
            if W_ADDR = 7 then
            	W_ADDR <= 0;
                if R_ADDr = 0 then
                	full <= '1';
                end if;
            end if;
         end if;
          
         if read = '1' and empty = '0' then  -- if not full and there's incoming data
           full <= '0';
            --add item to queue at a particular address
            R_ADDR <= R_ADDR + 1; -- increment address
            Queue_reg(R_ADDR) <= (others => '0');  --store the parallel data into register
            
        	if (W_ADDR = R_ADDR + 1) then
        		empty <= '1';
            end if;
            if R_ADDR = 7 then
            	R_ADDR <= 0;
                if W_ADDr = 0 then
                	empty <= '1';
                end if;
            end if;
          end if;
      --end if;
--end process queue_proc;
   end if;
end process datapath;
Tx <= Shift_Reg(0);


end behavior;
        
        
