library IEEE;
use IEEE.STD_LOGIC_1164.all;

use WORK.MACHINE_COMMON.all;

entity ProductType2Chars is
    port (
        prod                       : in  ProductType;
        code0, code1, code2, code3 : out std_ulogic_vector(3 downto 0)
        );
end entity ProductType2Chars;

architecture rtl of ProductType2Chars is
begin
    with prod select code3 <=                     -- left-most char
                               "0010" when COFFEE,
                               "1010" when TEA,
                               "0110" when MILK,
                               "0010" when CHOCOLAT,
                               "1001" when CANCEL,
                               "1111" when DASHES,
                               "0000" when NONE,  -- Do not show anything
                               "0111" when others;
    with prod select code2 <=                     -- second char
                               "0001" when COFFEE,
                               "0011" when TEA,
                               "0011" when MILK,
                               "0101" when CHOCOLAT,
                               "1010" when CANCEL,
                               "1111" when DASHES,
                               "0000" when NONE,  -- Do not show anything
                               "1010" when others;
    with prod select code1 <=                     -- third char
                               "0100" when COFFEE,
                               "0000" when TEA,
                               "0010" when MILK,
                               "0111" when CHOCOLAT,
                               "0111" when CANCEL,
                               "1111" when DASHES,
                               "0000" when NONE,  -- Do not show anything
                               "0101" when others;
    with prod select code0 <=                     -- fourth char
                               "0011" when COFFEE,
                               "0000" when TEA,
                               "0101" when MILK,
                               "0010" when CHOCOLAT,
                               "1000" when CANCEL,
                               "1111" when DASHES,
                               "0000" when NONE,  -- Do not show anything
                               "0000" when others;
end architecture rtl;
