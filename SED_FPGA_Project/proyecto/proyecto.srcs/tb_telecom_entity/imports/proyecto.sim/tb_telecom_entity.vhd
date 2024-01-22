library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use WORK.MACHINE_COMMON.all;

entity COMMUNICATION_ENTITY_tb is
end;

architecture bench of COMMUNICATION_ENTITY_tb is

    component COMMUNICATION_ENTITY
        generic (
            g_CLK_FREQ  : positive := 100_000_000;
            g_UART_FREQ : positive := 10_000
            );
        port (
            i_CLK             : in    std_ulogic;
            i_RESET_N         : in    std_ulogic;
            i_serial_rx       : in    std_ulogic;
            o_serial_tx       : out   std_ulogic;
            i_status          : in    MachineStatus;
            i_status_send     : in    std_ulogic;
            o_cmd_received    : out   std_ulogic;
            o_cmd_cancel      : inout std_ulogic;
            o_cmd_product     : out   std_ulogic;
            o_product_type    : out   ProductType;
            o8_converted_secs : out   BYTE;
            o_RX_brk          : out   std_ulogic
            );
    end component;

    signal i_CLK             : std_ulogic    := '0';
    signal i_RESET_N         : std_ulogic    := '0';
    signal i_serial_rx       : std_ulogic    := '1';
    signal o_serial_tx       : std_ulogic;
    signal i_status          : MachineStatus := AVAILABLE;
    signal i_status_send     : std_ulogic    := '0';
    signal o_cmd_received    : std_ulogic;
    signal o_cmd_cancel      : std_ulogic;
    signal o_cmd_product     : std_ulogic;
    signal o_product_type    : ProductType;
    signal o8_converted_secs : BYTE;
    signal o_RX_brk          : std_ulogic;

    constant c_CLK_FREQ    : positive := 100_000_000;
    constant c_CLK_PERIOD  : time     := 1 sec / c_CLK_FREQ;   -- 10 ns
    constant c_UART_FREQ   : positive := 10_000_000;
    constant c_UART_PERIOD : time     := 1 sec / c_UART_FREQ;  -- 100 ns

    -- Test transitions
    signal launch_cancel_request : std_ulogic := '0';
begin
    dut : COMMUNICATION_ENTITY generic map(
        g_CLK_FREQ  => c_CLK_FREQ,
        g_UART_FREQ => c_UART_FREQ)
        port map(
            i_CLK             => i_CLK,
            i_RESET_N         => i_RESET_N,
            i_serial_rx       => i_serial_rx,
            o_serial_tx       => o_serial_tx,
            i_status          => i_status,
            i_status_send     => i_status_send,
            o_cmd_received    => o_cmd_received,
            o_cmd_cancel      => o_cmd_cancel,
            o_cmd_product     => o_cmd_product,
            o_product_type    => o_product_type,
            o8_converted_secs => o8_converted_secs,
            o_RX_brk          => o_RX_brk);

    i_CLK <= not i_CLK after c_CLK_PERIOD / 2;

    stimulus_serial_input : process
    begin
        wait for 20 ns;
        -- send b01100001
        i_serial_rx <= '0';             -- start bit
        wait for c_UART_PERIOD;

        i_serial_rx <= '1';             -- LSB
        wait for c_UART_PERIOD;
        i_serial_rx <= '0';
        wait for c_UART_PERIOD;
        i_serial_rx <= '0';
        wait for c_UART_PERIOD;
        i_serial_rx <= '0';
        wait for c_UART_PERIOD;
        i_serial_rx <= '0';
        wait for c_UART_PERIOD;
        i_serial_rx <= '0';
        wait for c_UART_PERIOD;
        i_serial_rx <= '1';
        wait for c_UART_PERIOD;
        i_serial_rx <= '1';
        wait for c_UART_PERIOD;
        i_serial_rx <= '1';             -- MSB
        wait for c_UART_PERIOD;

        i_serial_rx <= '1';             -- stop bit
        wait for c_UART_PERIOD;

        wait until launch_cancel_request = '1';
        -- send stop request (b1111_1111)
        i_serial_rx <= '0';             -- start bit
        wait for c_UART_PERIOD;
        cancel_for_loop : for i in 0 to 7 loop
            i_serial_rx <= '1';
            wait for c_UART_PERIOD;
        end loop cancel_for_loop;
        i_serial_rx <= '1';             -- stop bit
        wait for c_UART_PERIOD;

        wait;

    end process;

    stimulus_local : process
    begin
        -- Check RESET
        i_RESET_N <= '0';
        wait for c_CLK_PERIOD;
        i_RESET_N <= '1';

        -- Check input b01100001 : b0110_0011 secs + TEA product
        wait until i_serial_rx = '0';
        wait for 10 * c_CLK_PERIOD;
        wait until o_cmd_received = '1';

        assert o_cmd_cancel = '0' report "[TEST]: cancel cmd error (1)";
        assert o_cmd_product = '1' report "[TEST]: product cmd error (1)";
        assert o8_converted_secs = "11000011" report "[TEST]: decoded time error (1): " & to_string(o8_converted_secs);
        assert o_product_type = TEA report "[TEST]: product type error (1): " & ProductType'image(o_product_type);

        -- Check send code
        wait for 2 * c_UART_PERIOD;
        i_status      <= BUSY;
        i_status_send <= '1';
        wait for 10 * c_UART_PERIOD;
        assert o_serial_tx = '1' report "[TEST]: o_serial_tx value error";

        -- Check recv CANCEL order
        launch_cancel_request <= '1';
        wait until i_serial_rx = '0';
        wait for 10 * c_CLK_PERIOD;
        wait until o_cmd_received = '1';

        assert o_cmd_cancel = '1' report "[TEST]: cancel cmd error (2)";
        assert o_cmd_product = '0' report "[TEST]: product cmd error (2)";
        -- ASSERT o8_converted_secs = "11111111" REPORT "[TEST]: decoded time error (2): " & to_string(o8_converted_secs);
        assert o_product_type = CANCEL report "[TEST]: product type error (2): " & ProductType'image(o_product_type);

        assert false report "[TEST OK]: FINISHED OK" severity failure;
    end process;
end;
