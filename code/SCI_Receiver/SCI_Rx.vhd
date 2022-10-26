--=============================================================================
--Library Declarations:
--=============================================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.math_real.all;

--=============================================================================
--Entity Declaration:
--=============================================================================

entity SCI_Rx is
    Port ( Clk : in STD_LOGIC; --clock
           RsRx  : in  STD_LOGIC; --received bit stream
           rx_shift : out STD_LOGIC; --for testing 
           rx_data : out STD_LOGIC_VECTOR (7 downto 0); -- data byte
           rx_done_tick : out  STD_LOGIC );
   end SCI_Rx;

architecture behavioral_architecture of SCI_Rx is
    constant BAUD_PERIOD : integer :=87;--baud rate of 115,200 and clock of 10 MHz 
    --constant BAUD_PERIOD : integer := 104; --baud rate of 9600 and clock of 1 MHz 
    Signal shift_register : STD_LOGIC_VECTOR (9 downto 0):= (others => '0'); --10 bit shift register 
    Signal Baud_Counter : unsigned(8 downto 0) := (others => '0');--counts up to baud period to set off tc tick
    Signal Bit_Counter : unsigned(8 downto 0) := (others => '0');--keeps track of how many bits have been shifted since line was first pulled low
    type state_type is (idle, count_init, start, wait_shift, shift, load, done);
    Signal curr_state, next_state : state_type := idle;
    Signal clr_baud : STD_LOGIC := '0'; --clears baud counter
    Signal clr_bit : STD_LOGIC := '0';--clears bit counter
    Signal clr_shift : STD_LOGIC := '0'; --clears shift register
    Signal half_tc_baud : STD_LOGIC := '0'; --flag goes high when baud counter reaches half of baud period to signal middle of start bit
    Signal tc_baud : STD_LOGIC := '0'; --flag goes high when tc counter reaches tc period
    Signal tc_bit : STD_LOGIC := '0'; --flag goes high when tc counter reaches 9 (ten bits would have been shifted
    Signal shift_en : STD_LOGIC := '0';-- monopulse signal which enables the shift register to shift bits
    Signal load_en : STD_LOGIC := '0';--enables the shift register load its bits into the output register
   

begin
	--BAUD COUNTER TO IMPLEMENT BAUD RATE BY COUNTING TO BAUD PERIOD
    baud_counter_proc : process(clk)
    begin 
        if rising_edge(clk) then 
            tc_baud <= '0';
            half_tc_baud <= '0';
            if (clr_baud = '0') then
                Baud_Counter <= Baud_Counter + 1;
                if (Baud_Counter = ((BAUD_PERIOD-1)/2)) then --set half_tc_baud flag when baud counter counts to half of the baud period
                    half_tc_baud <= '1';
                end if;
                if (Baud_Counter = BAUD_PERIOD-1) then--set tc_baud flag when baud counter counts to the baud period
                    tc_baud <= '1';
                end if;
            else
                Baud_Counter <= (others => '0'); --if clr_baud goes high, reset baud counter
            end if;
        end if;
    end process baud_counter_proc;
    
    --BIT COUNTER TO KEEP TRACK OF HOW MANY BITS HAVE BEEN SHIFTED ONTO THE BIT REGISTER
    bit_counter_proc : process(clk)
    begin
        if rising_edge(clk) then 
            tc_bit <= '0';
            if (clr_bit = '0') then
                if (shift_en = '1') then --whenever the monopulse shift enable signal goes high, increment bit counter by one
                    Bit_Counter <= Bit_Counter + 1; 
                    if(Bit_Counter = 9) then --this would mean that 10 bits had been shifted onto the shift register
                        tc_bit <= '1';
                    end if;
                end if;
            else --if clr_bit goes high, reset bit counter
                Bit_Counter <= (others => '0');
            end if;
        end if;
    end process bit_counter_proc;
    
    --LOGIC DETERMINING NEXT STATE GIVEN CURRENT STATE AND INPUTS
    NextStateLogic: process(curr_state, RsRx, half_tc_baud, tc_baud, tc_bit)
    begin
        next_state <= curr_state;
        case curr_state is
            when idle =>
                if RsRx = '0' then --if the input line is pulled low when in idle state, that signals a start bit
                    next_state <= count_init;
                end if;
            when count_init =>
                if half_tc_baud = '1' then --the first time, we count to half the baud period to get to the middle of the start bit
                    next_state <= start;
                end if;
            when start => --shift the start bit 
                next_state <= wait_shift;
            when wait_shift => 
                if tc_baud = '1' then --keep shifting bits onto the shift register whenever the tc_baud flag is asserted
                    next_state <= shift;
                elsif tc_bit = '1' then --load middle eight bits onto the output register when 10 bits have been shifted into shift register
                    next_state <= load;
                end if;
            when shift =>
                next_state <= wait_shift;
            when load =>
            	next_state <= done;
            when done => --when shifting is done, return to the idle state
            	next_state <= idle;
             
        end case;
    end process NextStateLogic;
    
    --PROCESS DETERMINING THE OUTPUT OF THE FSM GIVEN ITS CURRENT STATE
    OutputLogic: process(curr_state)
    begin
        clr_baud <= '1';
        clr_bit <= '1';
        clr_shift <= '1';
        shift_en <= '0';
        load_en <= '0';
        rx_done_tick <= '0';

        case curr_state is
            when idle => 
                clr_baud <= '1';
                clr_bit <= '1';
                clr_shift <= '1';
                shift_en <= '0';
            when count_init => 
                clr_baud <= '0';
                clr_bit <= '0';
                clr_shift <= '0';
            when start => 
                shift_en <= '1';
                clr_baud <= '1';
                clr_bit <= '0';
            when wait_shift =>
                clr_baud <= '0';
                shift_en <= '0';
                clr_bit <= '0';
            when shift =>
                clr_baud <= '1';
                shift_en <= '1';
                clr_bit <= '0';
            when load =>
                load_en <= '1';
                clr_baud <= '1';
                clr_bit <= '1';
            when done =>
            	rx_done_tick <= '1';
        end case;
    end process OutputLogic;
    
    --PROCESS UPDATING THE CURRENT STATE WITH THE NEXT STATE ON THE RISING EDGE OF THE CLOCK 
    StateUpdate : process(clk)
    begin
        if rising_edge(clk) then
            curr_state <= next_state;
            if shift_en = '1' then  --shift bits into shift register whenever the shift_en monopulse signal occurs
                shift_register <= RsRx & shift_register(9 downto 1);
            end if;
            if load_en = '1' then --load middle eight bits onto the output register when 10 bits have been shifted into shift register 
                rx_data <= shift_register(8 downto 1);
            end if;
        end if;
    end process StateUpdate;

    rx_shift <= shift_en;

end behavioral_architecture;
