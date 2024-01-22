LIBRARY IEEE;
USE IEEE.Std_logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY COMMUNICATION_ENTITY_tb IS
END;

ARCHITECTURE bench OF COMMUNICATION_ENTITY_tb IS

    COMPONENT COMMUNICATION_ENTITY
        GENERIC (
            g_CLK_FREQ : POSITIVE := 100_000_000;
            g_UART_FREQ : POSITIVE := 10_000
        );
        PORT (
            i_CLK : IN STD_ULOGIC;
            i_RESET_N : IN STD_ULOGIC;
            i_serial_rx : IN STD_ULOGIC;
            o_serial_tx : OUT STD_ULOGIC;
            i_status : IN MachineStatus;
            i_status_send : IN STD_ULOGIC;
            o_cmd_received : OUT STD_ULOGIC;
            o_cmd_cancel : INOUT STD_ULOGIC;
            o_cmd_product : OUT STD_ULOGIC;
            o_product_type : OUT ProductType;
            o8_converted_secs : OUT BYTE;
            o_RX_brk : OUT STD_ULOGIC
        );
    END COMPONENT;

    SIGNAL i_CLK : STD_ULOGIC := '0';
    SIGNAL i_RESET_N : STD_ULOGIC := '0';
    SIGNAL i_serial_rx : STD_ULOGIC := '1';
    SIGNAL o_serial_tx : STD_ULOGIC;
    SIGNAL i_status : MachineStatus := AVAILABLE;
    SIGNAL i_status_send : STD_ULOGIC := '0';
    SIGNAL o_cmd_received : STD_ULOGIC;
    SIGNAL o_cmd_cancel : STD_ULOGIC;
    SIGNAL o_cmd_product : STD_ULOGIC;
    SIGNAL o_product_type : ProductType;
    SIGNAL o8_converted_secs : BYTE;
    SIGNAL o_RX_brk : STD_ULOGIC;

    CONSTANT c_CLK_FREQ : POSITIVE := 100_000_000;
    CONSTANT c_CLK_PERIOD : TIME := 1 sec / c_CLK_FREQ; -- 10 ns
    CONSTANT c_UART_FREQ : POSITIVE := 10_000_000;
    CONSTANT c_UART_PERIOD : TIME := 1 sec / c_UART_FREQ; -- 100 ns

    -- Test transitions
    signal launch_cancel_request : std_ulogic := '0';
BEGIN
    dut : COMMUNICATION_ENTITY GENERIC MAP(
        g_CLK_FREQ => c_CLK_FREQ,
        g_UART_FREQ => c_UART_FREQ)
    PORT MAP(
        i_CLK => i_CLK,
        i_RESET_N => i_RESET_N,
        i_serial_rx => i_serial_rx,
        o_serial_tx => o_serial_tx,
        i_status => i_status,
        i_status_send => i_status_send,
        o_cmd_received => o_cmd_received,
        o_cmd_cancel => o_cmd_cancel,
        o_cmd_product => o_cmd_product,
        o_product_type => o_product_type,
        o8_converted_secs => o8_converted_secs,
        o_RX_brk => o_RX_brk);

    i_CLK <= NOT i_CLK AFTER c_CLK_PERIOD / 2;

    stimulus_serial_input : PROCESS
    BEGIN
        WAIT FOR 20 ns;
        -- send b01100001
        i_serial_rx <= '0'; -- start bit
        WAIT FOR c_UART_PERIOD;

        i_serial_rx <= '1'; -- LSB
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '0';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '0';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '0';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '0';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '0';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '1';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '1';
        WAIT FOR c_UART_PERIOD;
        i_serial_rx <= '1'; -- MSB
        WAIT FOR c_UART_PERIOD;

        i_serial_rx <= '1'; -- stop bit
        WAIT FOR c_UART_PERIOD;

        WAIT until launch_cancel_request = '1';
        -- send stop request (b1111_1111)
        i_serial_rx <= '0'; -- start bit
        WAIT FOR c_UART_PERIOD;
        cancel_for_loop : FOR i IN 0 TO 7 LOOP
            i_serial_rx <= '1';
            WAIT FOR c_UART_PERIOD;
        END LOOP cancel_for_loop;
        i_serial_rx <= '1'; -- stop bit
        WAIT FOR c_UART_PERIOD;

        WAIT;

    END PROCESS;

    stimulus_local : PROCESS
    BEGIN
        -- Check RESET
        i_RESET_N <= '0';
        WAIT FOR c_CLK_PERIOD;
        i_RESET_N <= '1';

        -- Check input b01100001 : b0110_0011 secs + TEA product
        WAIT UNTIL i_serial_rx = '0';
        WAIT FOR 10 * c_CLK_PERIOD;
        WAIT UNTIL o_cmd_received = '1';

        ASSERT o_cmd_cancel = '0' REPORT "[TEST]: cancel cmd error (1)";
        ASSERT o_cmd_product = '1' REPORT "[TEST]: product cmd error (1)";
        ASSERT o8_converted_secs = "11000011" REPORT "[TEST]: decoded time error (1): " & to_string(o8_converted_secs);
        ASSERT o_product_type = TEA REPORT "[TEST]: product type error (1): " & ProductType'image(o_product_type);

        -- Check send code
        WAIT FOR 2 * c_UART_PERIOD;
        i_status <= BUSY;
        i_status_send <= '1';
        WAIT FOR 10 * c_UART_PERIOD;
        ASSERT o_serial_tx = '1' REPORT "[TEST]: o_serial_tx value error";

        -- Check recv CANCEL order
        launch_cancel_request <= '1';
        WAIT UNTIL i_serial_rx = '0';
        WAIT FOR 10 * c_CLK_PERIOD;
        WAIT UNTIL o_cmd_received = '1';

        ASSERT o_cmd_cancel = '1' REPORT "[TEST]: cancel cmd error (2)";
        ASSERT o_cmd_product = '0' REPORT "[TEST]: product cmd error (2)";
        -- ASSERT o8_converted_secs = "11111111" REPORT "[TEST]: decoded time error (2): " & to_string(o8_converted_secs);
        ASSERT o_product_type = CANCEL REPORT "[TEST]: product type error (2): " & ProductType'image(o_product_type);

        ASSERT false REPORT "[TEST OK]: FINISHED OK" SEVERITY failure;
    END PROCESS;
END;
