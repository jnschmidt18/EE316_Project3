----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Josiah Schmidt
-- 
-- Create Date: 03/02/2021 02:23:55 PM
-- Design Name: 
-- Module Name: i2c_lcd_driver - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity i2c_lcd_driver is
generic
(
  C_CLK_FREQ_MHZ : integer := 50                      -- System clock frequency in MHz
);
port
(
  I_CLK          : in std_logic;                      -- System clk frequency of (C_CLK_FREQ_MHZ)
  I_RESET_N      : in std_logic;                      -- System reset (active low)

  I_DISP_ENABLE  : in std_logic;                      -- Whether the lcd is on '1' or off '0'

  I_DISPLAY_DATA : in std_logic_vector(15 downto 0);  -- Data to be displayed
  O_BUSY         : out std_logic;                     -- Busy signal from I2C master

  IO_I2C_SDA     : inout std_logic;                   -- Serial data of i2c bus
  IO_I2C_SCL     : inout std_logic                    -- Serial clock of i2c bus
);
end i2c_lcd_driver;

architecture Behavioral of i2c_lcd_driver is

  ----------------
  -- Components --
  ----------------
  component i2c_master is
  generic
  (
    input_clk : integer := 50_000_000;               -- Input clock speed from user logic in Hz
    bus_clk   : integer := 400_000                   -- Speed the i2c bus (scl) will run at in Hz
  );
  port
  (
    clk       : in     std_logic;                    -- System clock
    reset_n   : in     std_logic;                    -- Active low reset
    ena       : in     std_logic;                    -- Latch in command
    addr      : in     std_logic_vector(2 downto 0); -- Address of target slave
    rw        : in     std_logic;                    -- '0' is write, '1' is read
    data_wr   : in     std_logic_vector(3 downto 0); -- Data to write to slave
    busy      : out    std_logic;                    -- Indicates transaction in progress
    data_rd   : out    std_logic_vector(3 downto 0); -- Data read from slave
    ack_error : buffer std_logic;                    -- Flag if improper acknowledge from slave
    sda       : inout  std_logic;                    -- Serial data output of i2c bus
    scl       : inout  std_logic                     -- Serial clock output of i2c bus
  );
  end component i2c_master;

  constant C_CLK_FREQ_HZ         : integer := C_CLK_FREQ_MHZ * 1_000_000;
  constant C_I2C_BUS_CLK_FREQ_HZ : integer := 100_000;
  constant C_I2C_LCD_ADDR        : std_logic_vector(2 downto 0) := "000"; 
  constant C_WR_BYTE_INDEX_MAX   : integer := 12;
  constant C_WR_BYTE_READY_INDEX : integer := 7;

  type T_LCD_STATE is (READY_STATE, WRITE_STATE, WAIT_STATE, NEXT_STATE);
  signal s_lcd_curr_state       : T_LCD_STATE := READY_STATE;
  
  signal s_display_data_latched : std_logic_vector(15 downto 0);
  signal s_lcd_enable           : std_logic;
  signal s_wr_data_byte_index   : integer;

  signal s_wr_data_byte         : std_logic_vector(3 downto 0);

  signal s_lcd_wr               : std_logic;  --'0' is write, '1' is read
  signal s_lcd_address          : std_logic_vector(2 downto 0) := C_I2C_LCD_ADDR;
  signal s_lcd_busy             : std_logic;

begin
  I2C_MASTER_INST:i2c_master
  generic map
  (
    input_clk => C_CLK_FREQ_HZ,
    bus_clk   => C_I2C_BUS_CLK_FREQ_HZ
  )
  port map
  (
    clk       => I_CLK,
    reset_n   => I_RESET_N,
    ena       => s_lcd_enable,
    addr      => s_lcd_address,
    rw        => s_lcd_wr,
    data_wr   => s_wr_data_byte,
    busy      => s_lcd_busy,
    data_rd   => open,
    ack_error => open,
    sda       => IO_I2C_SDA,
    scl       => IO_I2C_SCL
  );

  I2C_STATE_MACHINE: process (I_CLK, I_RESET_N)
  begin
    if (I_RESET_N = '0') then
      s_lcd_curr_state             <= READY_STATE;
      
  elsif (rising_edge(I_CLK)) then
        -- I2C lcd state machine logic
        case s_lcd_curr_state is
          when READY_STATE =>
            if (s_display_data_latched /= I_DISPLAY_DATA) then
              s_lcd_curr_state     <= WRITE_STATE;
            else
              s_lcd_curr_state     <= s_lcd_curr_state;
            end if;

          when WRITE_STATE =>
            s_lcd_curr_state       <= WAIT_STATE;

          when WAIT_STATE =>
            if (s_lcd_busy = '1') then
              s_lcd_curr_state     <= NEXT_STATE;
            else
              s_lcd_curr_state     <= s_lcd_curr_state;
            end if;

            when NEXT_STATE =>
              if (s_lcd_busy = '0') then
                if (s_wr_data_byte_index /= C_WR_BYTE_INDEX_MAX) then
                  s_lcd_curr_state <= WRITE_STATE;
                else
                  s_lcd_curr_state <= READY_STATE;
                end if;
              else
                s_lcd_curr_state   <= s_lcd_curr_state;
              end if;

          -- Error condition, should never occur
          when others =>
            s_lcd_curr_state       <= READY_STATE;
        end case;
    end if;
  end process I2C_STATE_MACHINE;

  DATA_FLOW_CTRL: process (I_CLK, I_RESET_N)
  begin
    if (I_RESET_N = '0') then
      s_display_data_latched     <= (others=>'1');
      s_lcd_enable               <= '0';
      s_wr_data_byte_index       <=  0;
      O_BUSY                     <= '1';

    elsif (rising_edge(I_CLK)) then
      -- Latch data so it does not change during write
      if (s_lcd_curr_state = READY_STATE) then
         s_display_data_latched  <= I_DISPLAY_DATA;
      else
         s_display_data_latched  <= s_display_data_latched;
      end if;

      -- Enable signal logic
      if (s_lcd_curr_state = WRITE_STATE) then
        s_lcd_enable             <= '1';
      elsif (s_lcd_curr_state = WAIT_STATE) and
            (s_lcd_busy = '1') then
        s_lcd_enable             <= '0';
      else
        s_lcd_enable             <= s_lcd_enable;
      end if;

      -- Data Byte Index logic
      if (I_DISP_ENABLE = '0') then
        s_wr_data_byte_index <= 0;
      elsif (s_lcd_curr_state = NEXT_STATE) and (s_lcd_busy = '0') then
          if (s_wr_data_byte_index /= C_WR_BYTE_INDEX_MAX) then
            s_wr_data_byte_index <= s_wr_data_byte_index + 1;
          else
            s_wr_data_byte_index <= C_WR_BYTE_READY_INDEX;
          end if;
      else
        s_wr_data_byte_index     <= s_wr_data_byte_index;
      end if;

      -- Output Busy logic
      if (s_lcd_curr_state = READY_STATE) then
        O_BUSY                   <= '0';
      else
        O_BUSY                   <= '1';
      end if;
    end if;
  end process DATA_FLOW_CTRL;




end Behavioral;
