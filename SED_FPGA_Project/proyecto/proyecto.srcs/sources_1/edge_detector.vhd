library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity EDGEDTCTR is
    port (
        CLK, RST_N : in STD_ULOGIC;
        SYNC_IN : in STD_ULOGIC;
        EDGE : out STD_ULOGIC
    );
end EDGEDTCTR;

architecture BEHAVIORAL of EDGEDTCTR is
    signal sreg : STD_ULOGIC_vector(2 downto 0);
begin
    process (CLK, RST_N)
    begin
        if RST_N = '0' then
            sreg <= (others => '0');
        elsif rising_edge(CLK) then
            sreg <= sreg(1 downto 0) & SYNC_IN;
        end if;
    end process;
    with sreg select
        EDGE <= '1' when "100",
                '0' when others;
end BEHAVIORAL;
