library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity EDGEDTCTR is
    generic (
        REG_LENGTH : positive := 1
        );
    port (
        CLK, RST_N : in  std_ulogic;
        SYNC_IN    : in  std_ulogic;
        EDGE       : out std_ulogic
        );
end EDGEDTCTR;

architecture BEHAVIORAL of EDGEDTCTR is
    signal sreg : std_ulogic_vector(REG_LENGTH downto 0);
begin
    process (CLK, RST_N)
    begin
        if RST_N = '0' then
            sreg <= (others => '0');
        elsif rising_edge(CLK) then
            sreg <= sreg(REG_LENGTH - 1 downto 0) & SYNC_IN;
        end if;
    end process;
    EDGE <=
        '1' when sreg = (REG_LENGTH - 1 downto 0 => '0') & '1' else
        '0';
end BEHAVIORAL;
