library ieee;
use ieee.std_logic_1164.all;

entity mux is
	port(
		clock : in std_logic;
		mode : in std_logic_vector(1 downto 0);
		datain1 : in std_logic_vector(7 downto 0);
		datain2 : in std_logic_vector(7 downto 0);
		datain3 : in std_logic_vector(7 downto 0);
		datain4 : in std_logic_vector(7 downto 0);
		dataout : out std_logic_vector(7 downto 0)
	);
end mux;

architecture Behavior of mux is

begin
	process(clock)
		begin
			case mode is
				when "00" =>
					dataout <= datain1;
				when "01" =>
					dataout <= datain2;
				when "10" =>
					dataout <= datain3;
				when "11" =>
					dataout <= datain4;
				when others =>
					dataout <= datain1;
				end case;
	end process;
end Behavior;