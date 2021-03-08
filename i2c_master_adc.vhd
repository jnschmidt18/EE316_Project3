----------------------------------------------------------------------------------
-- Company: Clarkson University
-- Engineer: Tarak Patel
--           Team 6
-- Create Date: 03/04/2021 02:42:46 PM
-- Design Name: ADC i2c Master
-- Module Name: i2c_master_adc - logic
-- Project Name: Project 3
-- Target Devices: Cora Z7-10
-- Tool Versions: Xilinx Vivado 2019.1
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity i2c_master_adc is
    Generic(
        i_clk : integer := 125000000; -- input clock frequency in Hz
        bus_clk : integer := 100000); -- clock frequency of scl in Hz
    Port ( clk : in STD_LOGIC; --system clock
           reset_n : in STD_LOGIC; --reset (active low)
           ena : in STD_LOGIC; -- latch in command
           addr : in STD_LOGIC_VECTOR(6 downto 0); --address of target slave (ADC)
           rw : in STD_LOGIC; -- 0:write 1:read
           data_wr : in STD_LOGIC_VECTOR(7 downto 0); --data to write to slave (ADC)
           busy : out STD_LOGIC;
           data_rd : out STD_LOGIC_VECTOR(7 downto 0); --data read from slave (ADC)
           ack_error : buffer STD_LOGIC; --flag if improper acknowldgment from slave
           sda : inout STD_LOGIC; --serial data output of i2c bus
           scl : inout STD_LOGIC); -- serial clock input of i2c bus
end i2c_master_adc;

architecture logic of i2c_master_adc is
    constant divider : integer := (i_clk / bus_clk) / 4;
    type fsm is (ready,start,command,slv_ack1,wr,rd,slv_ack2,mstr_ack,stop); --states for state machine
    signal state : fsm;
    signal data_clk : std_logic; --clock for data
    signal prev_data_clk : std_logic; --previous data clock
    SIGNAL data_clk_m    : STD_LOGIC; --data clock during previous system clock  
    signal scl_clk : std_logic; --internal scl
    signal scl_ena : std_logic := '0'; --enable internal scl to output
    signal sda_int : std_logic := '1'; --internal sda
    signal sda_ena_n :std_logic;
    signal addr_rw : std_logic_vector(7 downto 0);
    signal data_tx : std_logic_vector(7 downto 0);
    signal data_rx : std_logic_vector(7 downto 0);
    signal bit_cnt : integer range 0 to 7 := 7; -- signal tracks bit number in the transaction
    signal stretch : std_logic := '0'; --identifies if slave is stretching scl
begin

  --generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  	:  INTEGER RANGE 0 TO divider*4;  --timing for clock generation
            
  BEGIN
    IF(reset_n = '0') THEN                --reset asserted
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      prev_data_clk <= data_clk;          --store previous value of data clock
      IF(count = divider*4-1) THEN        --end of timing cycle
        count := 0;                       --reset timer
      ELSIF(stretch = '0') THEN           --clock stretching from slave not detected
        count := count + 1;               --continue clock generation timing
      END IF;
      CASE count IS
        WHEN 0 TO divider-1  =>            --first 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '0';
        WHEN divider to divider*2-1 =>    --second 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 to divider*3-1 =>  --third 1/4 cycle of clocking
          scl_clk <= '1';                 --release scl
          IF(scl = '0') THEN              --detect if slave is stretching clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    --last 1/4 cycle of clocking
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;

  --state machine and writing to sda during scl low (data_clk rising edge)
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 --reset asserted
      state <= ready;                      --return to initial state
      busy <= '1';                         --indicate not available
      scl_ena <= '0';                      --sets scl high impedance
      sda_int <= '1';                      --sets sda high impedance
      ack_error <= '0';                    --clear acknowledge error flag
      bit_cnt <= 7;                        --restarts data bit counter
      data_rd <= "00000000";               --clear data read port
    ELSIF(clk'EVENT AND clk = '1') THEN
      IF(data_clk = '1' AND prev_data_clk = '0') THEN  --data clock rising edge
        CASE state IS
          WHEN ready =>                      --idle state
            IF(ena = '1') THEN               --transaction requested
              busy <= '1';                   --flag busy
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              state <= start;                --go to start bit
            ELSE                             --remain idle
              busy <= '0';                   --unflag busy
              state <= ready;                --remain idle
            END IF;
          WHEN start =>                      --start bit of transaction
            busy <= '1';                     --resume busy if continuous mode
            sda_int <= addr_rw(bit_cnt);     --set first address bit to bus
            state <= command;                --go to command
          WHEN command =>                    --address and command byte of transaction
            IF(bit_cnt = 0) THEN             --command transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              state <= slv_ack1;             --go to slave acknowledge (command)
            ELSE                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
              state <= command;              --continue with command
            END IF;
          WHEN slv_ack1 =>                   --slave acknowledge bit (command)
            IF(addr_rw(0) = '0') THEN        --write command
              sda_int <= data_tx(bit_cnt);   --write first bit of data
              state <= wr;                   --go to write byte
            ELSE                             --read command
              sda_int <= '1';                --release sda from incoming data
              state <= rd;                   --go to read byte
            END IF;
          WHEN wr =>                         --write byte of transaction
            busy <= '1';                     --resume busy if continuous mode
            IF(bit_cnt = 0) THEN             --write byte transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
--    added the following line to make sure busy = 0 in the slv_ack2 state              
              busy <= '0';                   --continue is accepted    (modified by CU)          
              state <= slv_ack2;             --go to slave acknowledge (write)
            ELSE                             --next clock cycle of write state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= data_tx(bit_cnt-1); --write next bit to bus
              state <= wr;                   --continue writing
            END IF;
          WHEN rd =>                         --read byte of transaction
            busy <= '1';                     --resume busy if continuous mode
            IF(bit_cnt = 0) THEN             --read byte receive finished
              IF(ena = '1' AND addr_rw = addr & rw) THEN  --continuing with another read at same address
                sda_int <= '0';              --acknowledge the byte has been received
              ELSE                           --stopping or continuing with a write
                sda_int <= '1';              --send a no-acknowledge (before stop or repeated start)
              END IF;
              bit_cnt <= 7;                  --reset bit counter for "byte" states
--    added the following line to make sure busy = 0 in the mstr_ack state              
              busy <= '0';                   --continue is accepted    (modified by CU)              
              data_rd <= data_rx;            --output received data
              state <= mstr_ack;             --go to master acknowledge
            ELSE                             --next clock cycle of read state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              state <= rd;                   --continue reading
            END IF;
          WHEN slv_ack2 =>                   --slave acknowledge bit (write)
            IF(ena = '1') THEN               --continue transaction
--            busy <= '0';                   --continue is accepted   (modified by CU)           
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              IF(addr_rw = addr & rw) THEN   --continue transaction with another write
                busy <= '1';                 --resume busy in the wr state (modified by CU)             
                sda_int <= data_wr(bit_cnt); --write first bit of data
                state <= wr;                 --go to write byte
              ELSE                           --continue transaction with a read or new slave
                state <= start;              --go to repeated start
              END IF;
            ELSE                             --complete transaction
            busy <= '0';                   --unflag busy  (modified by CU)
            sda_int <= '1';                --sets sda high impedance (modified by CU)             
            state <= stop;                 --go to stop bit
            END IF;
          WHEN mstr_ack =>                   --master acknowledge bit after a read
            IF(ena = '1') THEN               --continue transaction
--            busy <= '0';                   --continue is accepted   (modified by CU)
              addr_rw <= addr & rw;          --collect requested slave address and command
              data_tx <= data_wr;            --collect requested data to write
              IF(addr_rw = addr & rw) THEN   --continue transaction with another read
                busy <= '1';                 --resume busy in the wr state (modified by CU)               
                sda_int <= '1';              --release sda from incoming data
                state <= rd;                 --go to read byte
              ELSE                           --continue transaction with a write or new slave
                state <= start;              --repeated start
              END IF;    
            ELSE                             --complete transaction
              busy <= '0';                   --unflag busy  (modified by CU)
              sda_int <= '1';                --sets sda high impedance (modified by CU)
              state <= stop;                 --go to stop bit                             
            END IF;
          WHEN stop =>                       --stop bit of transaction
--              busy <= '0';                   --unflag busy  (modified by CU)           
              state <= ready;                --go to idle state
        END CASE;    
      ELSIF(data_clk = '0' AND prev_data_clk = '1') THEN  --data clock falling edge
        CASE state IS
          WHEN start =>                  
            IF(scl_ena = '0') THEN                  --starting new transaction
              scl_ena <= '1';                       --enable scl output
              ack_error <= '0';                     --reset acknowledge error output
            END IF;
          WHEN slv_ack1 =>                          --receiving slave acknowledge (command)
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN rd =>                                --receiving slave data
            data_rx(bit_cnt) <= sda;                --receive current slave data bit
          WHEN slv_ack2 =>                          --receiving slave acknowledge (write)
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN stop =>
            scl_ena <= '0';                         --disable scl
          WHEN OTHERS =>
            NULL;
        END CASE;
      END IF;
    END IF; 
  END PROCESS;  


  --set sda output
  data_clk_m <= prev_data_clk and data_clk;         -- Modification added at CU
  WITH state SELECT
    sda_ena_n <= data_clk WHEN start,       --generate start condition
                 NOT data_clk_m WHEN stop,  --generate stop condition (modification added at CU)
                 sda_int WHEN OTHERS;       --set to internal sda signal     
      
  --set scl and sda outputs
  scl <= '0' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE 'Z';
  sda <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
  
-- Following two signals will be used for tristate obuft (did not work)
--  scl <= '1' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE '0';
--  sda <= '1' WHEN sda_ena_n = '0' ELSE '0';
end logic;
