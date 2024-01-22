LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY EDGEDTCTR_tb IS
END EDGEDTCTR_tb;

ARCHITECTURE tb OF EDGEDTCTR_tb IS

    COMPONENT EDGEDTCTR IS
        GENERIC (
            REG_LENGTH : POSITIVE := 1
        );
        PORT (
            CLK : IN STD_ULOGIC;
            RST_N : IN STD_ULOGIC;
            SYNC_IN : IN STD_ULOGIC;
            EDGE : OUT STD_ULOGIC);
    END COMPONENT;

    SIGNAL CLK : STD_ULOGIC;
    SIGNAL RST_N : STD_ULOGIC;
    SIGNAL SYNC_IN : STD_ULOGIC;
    SIGNAL EDGE : STD_ULOGIC;

    SIGNAL TbSYNC : STD_LOGIC := '0';
    SIGNAL TbSimEnded : STD_LOGIC := '0';
    CONSTANT c_CLK_FREQ : POSITIVE := 100_000_000;
    CONSTANT c_CLK_PERIOD : TIME := 1 sec / c_CLK_FREQ; -- 10 ns
    CONSTANT c_UART_FREQ : POSITIVE := 10_000_000;
    CONSTANT c_UART_PERIOD : TIME := 1 sec / c_UART_FREQ; -- 100 ns

BEGIN

    dut : EDGEDTCTR
    PORT MAP(
        CLK => CLK,
        RST_N => RST_N,
        SYNC_IN => SYNC_IN,
        EDGE => EDGE);

    -- Clock generation
    CLK <= NOT CLK AFTER c_CLK_PERIOD/2;

    -- SYNC stimuli
    TbSYNC <= NOT TbSYNC AFTER c_CLK_PERIOD * 4 + c_CLK_PERIOD * 7 / 13;  -- async input

    SYNC_IN <= TbSYNC;

    stimuli : PROCESS
    BEGIN

        -- Reset generation
        RST_N <= '0';
        WAIT FOR c_CLK_PERIOD * 10;
        RST_N <= '1';
        WAIT FOR c_CLK_PERIOD;
        ASSERT EDGE = '0' REPORT "[TEST]: Unexpected Edge 1";

        WAIT UNTIL TbSYNC = '1';
        ASSERT EDGE = '0' REPORT "[TEST]: Unexpected Edge 2";
        WAIT UNTIL CLK = '1';
        ASSERT EDGE = '1' REPORT "[TEST]: Edge OK";

        WAIT FOR c_CLK_PERIOD;
        ASSERT EDGE = '0' REPORT "[TEST]: Unexpected Edge 3";
        WAIT;
    END PROCESS;

END tb;
