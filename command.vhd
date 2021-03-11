library ieee;
use ieee.std_logic_1164.all;

entity command is
    port(
        clock : in std_logic;
        mode : in std_logic_vector(1 downto 0);
        commandout : out std_logic_vector(7 downto 0)
    );
end command;

architecture Behavior of command is

begin
    process(clock)
        begin
            if(rising_edge(clock)) then
                case mode is
                    when "00" =>
                        commandout <= "00000000";
                    when "01" =>
                        commandout <= "00000001";
                    when "10" =>
                        commandout <= "00000010";
                    when "11" =>
                        commandout <= "00000011";
                end case;
            end if;
    end process;
end Behavior;