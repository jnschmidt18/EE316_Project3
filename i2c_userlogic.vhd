LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity i2c_userlogic is
    port(
        clk : in std_logic;
        commandin : in std_logic_vector(7 downto 0);
        SDA : inout std_logic;
        SCL : inout std_logic;
        datard : out std_logic_vector(7 downto 0);
        dataready : out std_logic
    );
end i2c_userlogic;

architecture Behavior of i2c_userlogic is

component i2c_master is
    GENERIC(
    input_clk : INTEGER := 125_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 100_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END component;

type statename is (start, wdata, rdata);
signal state : statename;
signal busy, busyprev : std_logic;
signal count : integer:= 0;
signal countmax : integer:= 3000;
signal i2cdatawr : std_logic_vector(7 downto 0);
signal reset_n : std_logic;
signal i2cen : std_logic;
signal i2caddr : std_logic_vector(6 downto 0);
signal i2crw : std_logic;
signal SDAbuffer, SCLbuffer : std_logic;
signal datardbuf : std_logic_vector(7 downto 0);
signal ackbuf : std_logic;
signal commandinprev : std_logic_vector(7 downto 0);

begin

i2c_master1 : i2c_master
--    generic map(
--        input_clk => 100_000_000,
--        bus_clk => 100_000)
        
    port map(
        clk => clk,
        reset_n => reset_n,
        ena => i2cen,
        addr => i2caddr,
        rw => i2crw,
        data_wr => i2cdatawr,
        busy => busy,
        data_rd => datardbuf,
        ack_error => ackbuf,
        sda => SDAbuffer,
        scl => SCLbuffer
    );


    P0 : process(clk)
        begin
            if(rising_edge(clk)) then
                busyprev <= busy;
                commandinprev <= commandin;
            end if;
    end process;
    
    P1 : process(clk)
        begin
            if(rising_edge(clk)) then
                case state is
                    when start =>
                        if(count /= countmax) then
                            count <= count + 1;
                            reset_n <= '0';
                            i2cen <= '0';
                            i2caddr <= "1001000";
                            state <= start;
                        else
                            count <= 0;
                            reset_n <= '1';
                            i2cen <= '1';
                            i2crw <= '0';
                            i2cdatawr <= commandin;
                            i2caddr <= "1001000";
                            state <= wdata;
                        end if;
                    when wdata =>
                        if(busy = '0' and busyprev = '1') then
                            i2crw <= '1';
                            state <= rdata;
                        else
                            state <= wdata;
                        end if;
                    when rdata =>
                        if(commandinprev = commandin) then
                            dataready <= '0';
                            if(busy = '0' and busyprev = '1') then
                                datard <= datardbuf;
                                dataready <= '1';
                            end if;
                            state <= rdata;
                        else
                            state <= start;    
                        end if;    
                end case;
            end if;
            
    SDA <= SDAbuffer;
    SCL <= SCLbuffer;
    datard <= datardbuf;
    
    end process;
end Behavior;
