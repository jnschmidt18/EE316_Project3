library ieee;
use ieee.std_logic_1164.all;

entity topfsm is
	port(
		clock : in std_logic;
		keyin : in std_logic;
		mode : out std_logic_vector(1 downto 0)
	);
end topfsm;

architecture Behavior of topfsm is

type state_type is (ldr, temp, sine, pot);
signal state : state_type:=ldr;
signal clk_cnt : integer range 0 to 999999:=0;
signal clk_en : std_logic;
signal keyprev : std_logic;


begin
P0: process(clock)
		begin
			if rising_edge(clock) then
				if (clk_cnt = 999999) then
					clk_cnt <= 0;
					clk_en <= '1';
				else
					clk_cnt <= clk_cnt + 1;
					clk_en <= '0';
				end if;
			end if;
		end process;

    P1: process(clock)
        begin
            if(rising_edge(clock) and clk_en = '1') then
                keyprev <= keyin;
            end if;
    end process;
    
	P2: process(clock)
		begin
			if(rising_edge(clock) and clk_en = '1') then
				case state is
					when ldr =>
						mode <= "00";
						if(keyin = '1' and keyprev = '0') then
							state <= temp;
						else
							state <= ldr;
						end if;
					when temp =>
						mode <= "01";
						if(keyin = '1' and keyprev = '0') then
							state <= sine;
						else
							state <= temp;
						end if;	
					when sine =>
						mode <= "10";
						if(keyin = '1' and keyprev = '0') then
							state <= pot;
						else
							state <= sine;
						end if;
					when pot =>
						mode <= "11";
						if(keyin = '1' and keyprev = '0') then
							state <= ldr;
						else
							state <= pot;
						end if;
				end case;
			end if;
	end process;
end Behavior;