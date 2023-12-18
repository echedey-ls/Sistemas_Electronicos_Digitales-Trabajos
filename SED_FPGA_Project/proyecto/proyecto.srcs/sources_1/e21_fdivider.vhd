LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

ENTITY e21_fdivider IS
  GENERIC (
    MODULE : POSITIVE := 16
  );
  PORT (
    RESET : IN STD_LOGIC;
    CLK : IN STD_LOGIC;
    CE_IN : IN STD_LOGIC;
    CE_OUT : OUT STD_LOGIC
  );
END e21_fdivider;

ARCHITECTURE behavioral OF e21_fdivider IS

BEGIN
  PROCESS (RESET, CLK)
    SUBTYPE count_range IS INTEGER RANGE 0 TO module - 1;
    VARIABLE count : count_range;
  BEGIN
    IF RESET = '1' THEN
      count := count_range'high;
      CE_OUT <= '0';
    ELSIF rising_edge(CLK) THEN
      CE_OUT <= '0';
      IF CE_IN = '1' THEN
        IF count /= 0 THEN
          count := count - 1;
        ELSE
          CE_OUT <= '1';
          count := count_range'high;
        END IF;
      END IF;
    END IF;
  END PROCESS;
END behavioral;
