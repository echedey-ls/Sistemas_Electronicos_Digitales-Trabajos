library ieee;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity e20_updown_cntr is
    generic (
        WIDTH : positive := 4
        );
    port (
        CLR_N  : in  std_ulogic;
        CLK    : in  std_ulogic;
        UP     : in  std_ulogic;
        CE_N   : in  std_ulogic;
        LOAD_N : in  std_ulogic;
        J      : in  std_ulogic_vector (WIDTH - 1 downto 0);
        ZERO_N : out std_ulogic;
        Q      : out std_ulogic_vector (WIDTH - 1 downto 0)
        );
end e20_updown_cntr;

architecture behavioral of e20_updown_cntr is
    signal q_i : UNRESOLVED_UNSIGNED(Q'range);
begin
    process (CLR_N, CLK, LOAD_N, J)
    begin
        if CLR_N = '0' then
            q_i <= (others => '0');
        elsif LOAD_N = '0' then
            q_i <= unsigned(J);
        elsif rising_edge(CLK) then
            if CE_N = '0' then
                if UP = '1' then
                    q_i <= q_i + 1;
                else
                    q_i <= q_i - 1;
                end if;
            end if;
        end if;
    end process;
    Q      <= std_ulogic_vector(q_i);
    ZERO_N <= '0' when q_i = 0 else
              '1';
end behavioral;
