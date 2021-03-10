-- Module: i2c_slave_adc.vhd
-- EE 316 Project 3
-- Team 6

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

entity adc_controller is
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
end adc_controller;

architecture behavioral of adc_controller is
type FSM is (init, wait_state, sampling,config);
--type FSM is (init, write_data, read_data);
signal state : FSM := init;
signal enaSig, rwSig,busySig,ackErrorSig :  std_logic; 
signal prev_busy : std_logic;
signal analog_input : std_logic_vector(7 downto 0);
signal configure : std_logic_vector(7 downto 0) := "000000" & adc_source;
signal adc_addr : std_logic_vector(6 downto 0) := "1001000";
--signal cnt : integer := 0;
--signal max_cnt : integer := 3000;
--signal en, rw, busy, ack_error : std_logic;
--signal reset_n : std_logic;
--signal sda_buffer, scl_buffer : std_logic;
--signal prev_busy : std_logic;
--signal rd_buffer : std_logic_vector(7 downto 0);
--signal i2c_wrdata : std_logic_vector(7 downto 0);
--signal instructSig	: std_logic_vector(7 downto 0);
--signal i2c_address : std_logic_vector(6 downto 0);
--signal prev_instruct : std_logic_vector(7 downto 0);


component i2c_master_adc is
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
end component i2c_master_adc;

begin

	--i2c_address <= "1001000";
	i2c_instant : i2c_master_adc
		generic map(
			i_clk => 125000000,
			bus_clk => 100000)
		port map(
			clk => adc_clk,
			reset_n => adc_rst,
			ena => enaSig,
			addr => adc_addr,
			rw => rwSig,
			data_wr => configure,
			busy => busySig,
			data_rd => analog_input,
			ack_error => ackerrorSig,
			sda => adc_sda,
			scl => adc_scl);
	
--	process(adc_clk)
--	begin
--		if(rising_edge(adc_clk)) then
--			prev_instruct <= instruct;
--			prev_busy <= busy;
--		end if;
--	end process;
	
--	process(adc_clk)
--	begin
--		if(adc_clk'event and adc_clk = '1') then
--			case state is
--			when init =>
--				if (cnt /= max_cnt) then
--					cnt <= cnt - 1;
--					reset_n <= '0';
--					state <= init;
--					en <= '0';
--				else
--					cnt <= 0;
--					reset_n <= '1';
--					en <= '1';
--					rw <= '0';
--					i2c_wrdata <= instruct;
--					state <= write_data;
--				end if;
				
--			when write_data =>
--				if (busy = '0' and prev_busy = '1') then
--					rw <= '1';
--					state <= read_data;
--				end if;
			
--			when read_data =>
--				if prev_instruct = instruct then
--					data_rdy <= '0';
--					if (busy = '0' and prev_busy = '1') then
--						data_rd <= rd_buffer;
--						data_rdy <= '1';
--					end if;
--				else
--					state <= init;
--				end if;
--			end case;
--			end if;
			
--			adc_sda <= sda_buffer;
--			adc_scl <= scl_buffer;
--			data_rd <= rd_buffer;
--	end process;
--	end behavioral;
	
	 process(adc_clk,adc_rst,adc_enable)
	 begin
		 if(adc_rst = '0' or adc_enable = '0') then --reset
			 state <= init;
		 else
			 if(rising_edge(adc_clk)) then
				 case state is
					 when init =>
						 state <= wait_state; --restart system
						
					 when wait_state =>
						 if(busySig = '1') then
							 state <= wait_state;
						 else
							 state <= config;
						 end if;
						
					 when sampling =>
						 if(configure(1 downto 0) = adc_source) then
							 state <= sampling;
						 else
							 state <= wait_state;
						 end if;
						
					 when config =>
						 if(busySig = '0' and prev_busy = '1') then
							 state <= sampling;
						 else
							 state <= config;
						 end if;
				 end case;
			 end if;
		 end if;
	 end process;
	
	 process(adc_clk)
	 begin
		 if(rising_edge(adc_clk)) then
			 configure <= "000000" & adc_source; --selects input source
			 if(state = init) then
				 enaSig <= '0';
				 analog_input <= "00000000";
				 busySig <= '1';
				 rwSig <= '1';
				 --maybe add cnt to improve timing
			 elsif(state = wait_state) then
				 enaSig <= '0';
				 busySig <= '0';
			 elsif(state = sampling) then
				 rwSig <= '1'; -- read data
				 adc_odata <= analog_input;
			 elsif(state = config) then
				 enaSig <= '1'; --enable i2c connection
				 rwSig <= '0'; --write mode
				 busySig <= '1'; --busy
			 else
				 state <= wait_state;
			 end if;
		 end if;
	 end process;
	
	 --process to see if busy is changed
	 process(adc_clk)
	 begin
		 if(rising_edge(adc_clk)) then
			 prev_busy <= busySig;
		 end if;
	 end process;
 end behavioral;
