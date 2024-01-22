library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity e21_fdivider is
    generic (
        MODULE : positive := 16
        );
    port (
        RESET  : in  std_ulogic;
        CLK    : in  std_ulogic;
        CE_IN  : in  std_ulogic;
        CE_OUT : out std_ulogic
        );
end e21_fdivider;

architecture behavioral of e21_fdivider is

begin
    process (RESET, CLK)
        subtype count_range is integer range 0 to module - 1;
        variable count : count_range;
    begin
        if RESET = '1' then
            count  := count_range'high;
            CE_OUT <= '0';
        elsif rising_edge(CLK) then
            CE_OUT <= '0';
            if CE_IN = '1' then
                if count /= 0 then
                    count := count - 1;
                else
                    CE_OUT <= '1';
                    count  := count_range'high;
                end if;
            end if;
        end if;
    end process;
end behavioral;
