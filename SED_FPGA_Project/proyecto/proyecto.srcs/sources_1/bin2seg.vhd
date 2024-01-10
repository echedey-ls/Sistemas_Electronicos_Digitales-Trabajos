LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY decoder IS
    PORT (
        code : IN STD_ULOGIC_VECTOR(3 DOWNTO 0);
        led : OUT STD_ULOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY decoder;

ARCHITECTURE dataflow OF decoder IS
BEGIN
    WITH code SELECT
        led <=
        "0000001" WHEN "0000", -- 0
        "1001111" WHEN "0001",
        "0010010" WHEN "0010",
        "0000110" WHEN "0011",
        "1001100" WHEN "0100",
        "0100100" WHEN "0101",
        "0100000" WHEN "0110",
        "0001111" WHEN "0111",
        "0000000" WHEN "1000",
        "0000100" WHEN "1001", -- 9
        "1111110" WHEN OTHERS;
END ARCHITECTURE dataflow;
