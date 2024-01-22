library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

use WORK.MACHINE_COMMON.all;

entity FSM0_tb is
end;

architecture bench of FSM0_tb is

    component FSM0
        generic (
            g_CLK_FREQ : positive := 100_000_000
            );
        port (
            i_CLK             : in    std_ulogic;
            i_RESET_N         : in    std_ulogic;
            i_CANCEL_BTN      : in    std_ulogic;
            o_HEATER          : out   std_ulogic;
            i_cmd_received    : in    std_ulogic;
            i_cmd_cancel      : in    std_ulogic;
            i_cmd_product     : in    std_ulogic;
            i_product_type    : in    ProductType;
            i8_converted_secs : in    BYTE;
            o_status          : inout MachineStatus;
            o_status_send     : out   std_ulogic;
            o8_REMAINING_SECS : out   std_ulogic_vector(7 downto 0);
            o_PRODUCT_STR     : out   ProductType
            );
    end component;

    signal i_CLK             : std_ulogic;
    signal i_RESET_N         : std_ulogic;
    signal i_CANCEL_BTN      : std_ulogic;
    signal o_HEATER          : std_ulogic;
    signal i_cmd_received    : std_ulogic;
    signal i_cmd_cancel      : std_ulogic;
    signal i_cmd_product     : std_ulogic;
    signal i_product_type    : ProductType;
    signal i8_converted_secs : BYTE;
    signal o_status          : MachineStatus;
    signal o_status_send     : std_ulogic;
    signal o8_REMAINING_SECS : std_ulogic_vector(7 downto 0);
    signal o_PRODUCT_STR     : ProductType;

    constant c_CLK_FREQ    : positive := 100_000_000;
    constant c_CLK_PERIOD  : time     := 1 sec / c_CLK_FREQ;   -- 10 ns
    constant c_UART_FREQ   : positive := 10_000_000;
    constant c_UART_PERIOD : time     := 1 sec / c_UART_FREQ;  -- 100 ns
    signal stop_the_clock  : boolean;

begin

    -- Insert values for generic parameters !!
    uut : FSM0 generic map(g_CLK_FREQ => 100_000_000)
        port map(
            i_CLK             => i_CLK,
            i_RESET_N         => i_RESET_N,
            i_CANCEL_BTN      => i_CANCEL_BTN,
            o_HEATER          => o_HEATER,
            i_cmd_received    => i_cmd_received,
            i_cmd_cancel      => i_cmd_cancel,
            i_cmd_product     => i_cmd_product,
            i_product_type    => i_product_type,
            i8_converted_secs => i8_converted_secs,
            o_status          => o_status,
            o_status_send     => o_status_send,
            o8_REMAINING_SECS => o8_REMAINING_SECS,
            o_PRODUCT_STR     => o_PRODUCT_STR);

    stimulus : process
    begin

        i_RESET_N         <= '1';
        i_CANCEL_BTN      <= '0';
        i_cmd_received    <= '0';
        i_cmd_cancel      <= '0';
        i_cmd_product     <= '0';
        i_product_type    <= NONE;
        i8_converted_secs <= (others => '0');
        wait for c_CLK_PERIOD;
        -- Put initialisation code here

        --ENTRY-POINT

        wait for c_CLK_PERIOD;
        assert o_HEATER = '0' and o_status = AVAILABLE and o_PRODUCT_STR = DASHES report "Fallo ENTRY-POINT" severity error;

        i_cmd_received    <= '1';
        i_cmd_product     <= '1';
        i_product_type    <= COFFEE;
        i8_converted_secs <= "00000101";
        wait for c_CLK_PERIOD + c_CLK_PERIOD;  -- add another cycle since o_status gets updated a cycle later
        assert o_status = BUSY or o_status = STARTED_PROD report "Fallo transición ENTRY-POINT" severity error;
        wait for c_CLK_PERIOD;
        i_cmd_received    <= '0';
        i_cmd_product     <= '0';
        --PRELAUNCH DURA UN SOLO CICLO
        --COUNT_DOWN

        wait for c_CLK_PERIOD;
        assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo COUNT-DOWN" severity error;

        i_RESET_N <= '0';
        wait for c_CLK_PERIOD;
        assert o_HEATER = '0' and o_status_send = '0' and o_PRODUCT_STR = DASHES report "Fallo reset" severity error;
        i_RESET_N <= '1';
        wait for c_CLK_PERIOD;

        i_cmd_received    <= '1';
        i_cmd_product     <= '1';
        i_product_type    <= COFFEE;
        i8_converted_secs <= "00000101";
        wait for c_CLK_PERIOD;
        i_cmd_received    <= '0';
        i_cmd_product     <= '0';
        wait for c_CLK_PERIOD;
        --CANCELLED
        i_cmd_received    <= '1';
        i_cmd_product     <= '0';
        i_cmd_cancel      <= '1';
        wait for c_CLK_PERIOD*3;
        assert o_HEATER = '0' and o_status = CANCELLED and o_PRODUCT_STR = CANCEL report "Fallo cancelación" severity error;
        i_cmd_received    <= '0';
        i_cmd_product     <= '0';
        wait for c_CLK_PERIOD;

        i_cmd_cancel      <= '0';
        i_cmd_received    <= '1';
        i_cmd_product     <= '1';
        i_product_type    <= COFFEE;
        i8_converted_secs <= "00000101";
        wait for c_CLK_PERIOD;
        i_cmd_received    <= '0';
        i_cmd_product     <= '0';
        wait for c_CLK_PERIOD*4;

        assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo transicion CANCELLED" severity error;

        --FINISHED

        wait for 7 sec + c_CLK_PERIOD;
        assert o_HEATER = '0' and o_status = FINISHED and o_PRODUCT_STR = COFFEE report "Fallo terminacion" severity error;

        i_cmd_received    <= '1';
        i_cmd_product     <= '1';
        i_product_type    <= COFFEE;
        i8_converted_secs <= "00000101";
        wait for c_CLK_PERIOD;
        i_cmd_received    <= '0';
        i_cmd_product     <= '0';
        wait for c_CLK_PERIOD*2;
        assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo transicion FINISHED" severity error;

        -- Put test bench stimulus code here

        stop_the_clock <= true;
        wait;
    end process;

    clocking : process
    begin
        while not stop_the_clock loop
            i_CLK <= '0', '1' after c_CLK_PERIOD / 2;
            wait for c_CLK_PERIOD;
        end loop;
        wait;
    end process;

end;
