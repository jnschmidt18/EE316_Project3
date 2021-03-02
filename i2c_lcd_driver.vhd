----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
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
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

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
  constant C_I2C_LCD_ADDR        : std_logic_vector(2 downto 0) := "000";  -- Default address is not yet known
  constant C_WR_BYTE_INDEX_MAX   : integer := 12;
  constant C_WR_BYTE_READY_INDEX : integer := 7;

begin

end Behavioral;
