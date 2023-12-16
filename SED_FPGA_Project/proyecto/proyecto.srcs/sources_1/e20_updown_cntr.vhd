LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY e20_updown_cntr IS
  GENERIC (
    WIDTH : POSITIVE := 4
  );
  PORT (
    CLR_N : IN STD_LOGIC;
    CLK : IN STD_LOGIC;
    UP : IN STD_LOGIC;
    CE_N : IN STD_LOGIC;
    LOAD_N : IN STD_LOGIC;
    J : IN STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0);
    ZERO_N : OUT STD_LOGIC;
    Q : OUT STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0)
  );
END e20_updown_cntr;

ARCHITECTURE behavioral OF e20_updown_cntr IS
  SIGNAL q_i : unsigned(Q'RANGE);
BEGIN
  PROCESS (CLR_N, CLK, LOAD_N, J)
  BEGIN
    IF CLR_N = '0' THEN
      q_i <= (OTHERS => '0');
    ELSIF LOAD_N = '0' THEN
      q_i <= unsigned(J);
    ELSIF rising_edge(CLK) THEN
      IF CE_N = '0' THEN
        IF UP = '1' THEN
          q_i <= q_i + 1;
        ELSE
          q_i <= q_i - 1;
        END IF;
      END IF;
    END IF;
  END PROCESS;
  Q <= STD_LOGIC_VECTOR(q_i);
  ZERO_N <= '0' WHEN q_i = 0 ELSE
    '1';
END behavioral;
