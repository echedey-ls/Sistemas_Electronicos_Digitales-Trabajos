library ieee;
use IEEE.STD_LOGIC_1164.all;

entity char_decoder is
    port (
        code : in  std_ulogic_vector(3 downto 0);
        led  : out std_ulogic_vector(6 downto 0)
        );
end entity char_decoder;

architecture dataflow of char_decoder is
begin
    with code select led <=
        "1111111" when "0000",          -- Nothing
        "0001000" when "0001",          -- 'A'
        "0110001" when "0010",          -- 'C'
        "0110000" when "0011",          -- 'E'
        "0111000" when "0100",          -- 'F'
        "1001000" when "0101",          -- 'H'
        "1110001" when "0110",          -- 'L'
        "0000001" when "0111",          -- 'O'
        "0011000" when "1000",          -- 'P'
        "0100100" when "1001",          -- 'S'
        "1110000" when "1010",          -- 't'
        "1111110" when "1111",          -- '-'
        "1111111" when others;
end architecture dataflow;
