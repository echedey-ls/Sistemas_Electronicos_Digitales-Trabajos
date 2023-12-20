LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY ProductType2Chars IS
    PORT (
        prod : IN ProductType;
        code0, code1, code2, code3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY ProductType2Chars;

ARCHITECTURE rtl OF ProductType2Chars IS
BEGIN
    WITH prod SELECT code3 <= -- left-most char
        "0010" WHEN COFFEE,
        "1010" WHEN TEA,
        "0110" WHEN MILK,
        "0010" WHEN CHOCOLAT,
        "1001" WHEN CANCEL,
        "1111" WHEN DASHES,
        "0000" WHEN NONE; -- Do not show anything
    WITH prod SELECT code2 <= -- second char
        "0001" WHEN COFFEE,
        "0011" WHEN TEA,
        "0011" WHEN MILK,
        "0101" WHEN CHOCOLAT,
        "1010" WHEN CANCEL,
        "1111" WHEN DASHES,
        "0000" WHEN NONE; -- Do not show anything
    WITH prod SELECT code1 <= -- third char
        "0100" WHEN COFFEE,
        "0000" WHEN TEA,
        "0010" WHEN MILK,
        "0111" WHEN CHOCOLAT,
        "0111" WHEN CANCEL,
        "1111" WHEN DASHES,
        "0000" WHEN NONE; -- Do not show anything
    WITH prod SELECT code0 <= -- fourth char
        "0011" WHEN COFFEE,
        "0000" WHEN TEA,
        "0101" WHEN MILK,
        "0010" WHEN CHOCOLAT,
        "1000" WHEN CANCEL,
        "1111" WHEN DASHES,
        "0000" WHEN NONE; -- Do not show anything
END ARCHITECTURE rtl;
