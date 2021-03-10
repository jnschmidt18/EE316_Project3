library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

entity clock_gen is
	port(
		inclock : in std_logic;
		indata : in std_logic_vector(7 downto 0);
		outclock : out std_logic
	);
end clock_gen;

architecture Behavior of clock_gen is

signal counter : integer range 0 to 131071 := 0;
signal temp : integer range 0 to 255 := 0;
signal frequency : integer range 500 to 1500 := 500;
signal counttoint : integer range 0 to 131071 := 0;
signal countto : integer range 0 to 131071 := 0;
signal clockval : std_logic := '0';

begin
	process(inclock)
		begin
			if(rising_edge(inclock)) then
				temp <= to_integer(unsigned(indata));
				frequency <= (4 * temp) + 500;
				--counttoint <= (-33 * frequency) + 66666;
				counttoint <= (-42 * frequency) + 145833;

				if(counter = countto) then
					clockval <= not clockval;
					countto <= countto + counttoint;
				end if;
				
				if(counter = 131071) then
					counter <= 0;
				else
					counter <= counter + 1;
				end if;
			end if;
			outclock <= clockval;
	end process;
end Behavior;