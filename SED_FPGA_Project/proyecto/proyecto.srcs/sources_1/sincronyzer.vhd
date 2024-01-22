library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity SYNCHRNZR is
    port (
        CLK      : in  std_ulogic;
        ASYNC_IN : in  std_ulogic;
        SYNC_OUT : out std_ulogic
        );
end SYNCHRNZR;

architecture BEHAVIORAL of SYNCHRNZR is
    signal sreg : std_ulogic_vector(1 downto 0);
begin
    process (CLK)
    begin
        if rising_edge(CLK) then
            sync_out <= sreg(1);
            sreg     <= sreg(0) & async_in;
        end if;
    end process;
end BEHAVIORAL;
