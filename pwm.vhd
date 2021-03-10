library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity pwm is
	port(
		clock : in std_logic;
		indata : in std_logic_vector(7 downto 0);
		outdata : out std_logic
	);
end pwm;

architecture Behavior of pwm is

signal counter : std_logic_vector(7 downto 0) := "00000000";

begin
	P0: process(clock)
	begin
		if(rising_edge(clock)) then
			if(counter <= indata) then
				outdata <= '1';
			else
				outdata <= '0';
			end if;
			if(counter = "11111111") then
				counter <= "00000000";
			else
				counter <= counter + "00000001";
			end if;
		end if;
	end process;
end Behavior;