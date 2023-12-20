LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY char_decoder IS
    PORT (
        code : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
        led : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
    );
END ENTITY char_decoder;

ARCHITECTURE dataflow OF char_decoder IS
BEGIN
    WITH code SELECT led <=
        "1111111" WHEN "0000", -- Nothing
        "0001000" WHEN "0001", --A
        "0110001" WHEN "0010", --C
        "0110000" WHEN "0011", --E
        "0111000" WHEN "0100", --F
        "1001000" WHEN "0101", --H
        "1110001" WHEN "0110", --L
        "0000001" WHEN "0111", --O
        "0011000" WHEN "1000", --P
        "0100100" WHEN "1001", --S
        "1110000" WHEN "1010", --t
        "1111110" WHEN "1111", ---
        "1111111" WHEN OTHERS;
END ARCHITECTURE dataflow;
