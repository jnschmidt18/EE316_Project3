LIBRARY ieee;
   USE ieee.std_logic_1164.all;

ENTITY top IS
   PORT (
        clk : in std_logic;
        btn : in std_logic_vector(1 downto 0);
        led0_g : out std_logic;
        led0_r : out std_logic;
        led0_b : out std_logic;
        led1_g : out std_logic;
        led1_r : out std_logic;
        led1_b : out std_logic;
        ck_io0 : out std_logic;
        ck_io1 : out std_logic;
	ADC_SDA : inout std_logic;
	ADC_SCL	: inout std_logic
   );
END top;

ARCHITECTURE structural OF top IS

signal mode_sig : std_LOGIC_VECTOR(1 downto 0);
signal data1_sig : std_LOGIC_VECTOR(7 downto 0) := "00000000";
signal data2_sig : std_LOGIC_VECTOR(7 downto 0) := "01011011";
signal data3_sig : std_LOGIC_VECTOR(7 downto 0) := "11101010";
signal data4_sig : std_LOGIC_VECTOR(7 downto 0) := "11111111";
signal dataout_sig : std_LOGIC_VECTOR(7 downto 0);

-- TOP LEVEL COMPONENT
component pwm is
	port(
		clock : in std_LOGIC;
		indata : in std_LOGIC_VECTOR(7 downto 0);
		outdata : out std_LOGIC
	);
end component;

component clock_gen is
	port(
		inclock : in std_LOGIC;
		indata : in std_LOGIC_VECTOR(7 downto 0);
		outclock : out std_LOGIC
	);
end component;

component topfsm is
	port(
		clock : in std_LOGIC;
		keyin : in std_LOGIC;
		mode : out std_LOGIC_VECTOR(1 downto 0)
	);
end component;

component mux is
	port(
		clock : in std_logic;
		mode : in std_logic_vector(1 downto 0);
		datain1 : in std_logic_vector(7 downto 0);
		datain2 : in std_logic_vector(7 downto 0);
		datain3 : in std_logic_vector(7 downto 0);
		datain4 : in std_logic_vector(7 downto 0);
		dataout : out std_logic_vector(7 downto 0)
	);
end component;

component i2c_master_adc is
	Generic(
        	i_clk : integer := 125000000; -- input clock frequency in Hz
        	bus_clk : integer := 100000); -- clock frequency of scl in Hz
    	Port ( 
		clk : in STD_LOGIC; --system clock
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
end component;

component adc_controller is
	generic(
		slave_addr : std_logic_vector(6 downto 0) := "1001000");
	port(
		adc_clk		: in	std_logic;
		adc_rst		: in	std_logic;
		--instruct	: in	std_logic_vector(7 downto 0);
		adc_enable	: in	std_logic;
		adc_source	: in	std_logic_vector(1 downto 0); --to select AIN0 - AIN3
		adc_sda		: inout	std_logic;
		adc_scl		: inout	std_logic;
		adc_odata	: out	std_logic_vector(7 downto 0)
		--data_rd     : out   std_logic_vector(7 downto 0);
		--data_rdy	: out 	std_logic
		);
end component;

BEGIN

led0_g <= mode_sig(0);
led0_r <= mode_sig(0);
led0_b <= mode_sig(0);
led1_g <= mode_sig(1);
led1_r <= mode_sig(1);
led1_b <= mode_sig(1);

Inst0_topfsm : topfsm
		port map(
		clock => clk,
		keyin => btn(1),
		mode => mode_sig
		);

Inst0_pwm : pwm
		port map (
		clock => clk,
		indata => dataout_sig,
		outdata => ck_io0
		);
		
Inst0_clockgen : clock_gen
		port map(
		inclock => clk,
		indata => dataout_sig,
		outclock => ck_io1
		);
		
Inst0_mux : mux
		port map(
		clock => clk,
		mode => mode_sig,
		datain1 => data1_sig,
		datain2 => data2_sig,
		datain3 => data3_sig,
		datain4 => data4_sig,
		dataout => dataout_sig
		);

END structural;


