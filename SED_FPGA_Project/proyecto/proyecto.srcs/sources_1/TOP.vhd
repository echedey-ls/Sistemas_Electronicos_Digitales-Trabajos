LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY TOP IS
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        CPU_RESETN : IN STD_LOGIC;
        CANCEL_BUTTON : IN STD_LOGIC;
        SERIAL_IN : IN STD_LOGIC;
        SERIAL_OUT : OUT STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR (15 DOWNTO 0);
        DIGIT_SEGMENTS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        DIGIT_DISABLE : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
    CONSTANT c_CLK_FREQ : POSITIVE := 100_000_000; -- Hz
    CONSTANT c_UART_FREQ : POSITIVE := 10_000; -- Hz
    CONSTANT c_7SEGMENTS_FREQ : POSITIVE := 2_000; -- Hz, refresh rate of each of the 7 segments
    CONSTANT c_USED_SEGMENTS : POSITIVE := 8;
    CONSTANT c_USED_LEDS : POSITIVE := 2;
END TOP;

ARCHITECTURE Behavioral OF TOP IS
    --! Logic Manager
    COMPONENT FSM0 IS
        GENERIC (
            g_CLK_FREQ : POSITIVE := 100_000_000
        );
        PORT (
            i_CLK : IN STD_ULOGIC;
            i_RESET_N : IN STD_ULOGIC;

            i_CANCEL_BTN : IN STD_ULOGIC;
            o_HEATER : OUT STD_ULOGIC;
            -- UART TELECOMS IO
            i_cmd_received : IN STD_ULOGIC;
            i_cmd_cancel : IN STD_ULOGIC;
            i_cmd_product : IN STD_ULOGIC;
            i_product_type : IN ProductType;
            i8_converted_secs : IN BYTE;

            o_status : OUT MachineStatus;
            o_status_send : OUT STD_ULOGIC;
            -- DISPLAY OUTPUT
            o8_REMAINING_SECS : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
            o_PRODUCT_STR : OUT ProductType
        );
    END COMPONENT FSM0;

    --! HID Manager
    COMPONENT SEGMENTS_MANAGER IS
        GENERIC (
            g_CLK_FREQ : POSITIVE := 100_000_000; -- Hz
            g_REFRESH_RATE : POSITIVE := 50; -- Hz
            g_USED_SEGMENTS : POSITIVE := 3
        );
        PORT (
            i_CLK : IN STD_LOGIC;
            i_RESET_N : IN STD_LOGIC;
            i8_REMAINING_SECS : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
            i_PRODUCT_TYPE : IN ProductType;
            o7_DIGIT_SEGMENTS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            o8_DIGIT_DISABLE : OUT STD_LOGIC_VECTOR(g_USED_SEGMENTS - 1 DOWNTO 0)
        );
    END COMPONENT SEGMENTS_MANAGER;

    --!
    COMPONENT COMMUNICATION_ENTITY IS
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
            o8_converted_secs : OUT BYTE; -- Input BYTE 6 MSBs + 3 secs; 2 LSBs mean the type of product
            o_RX_brk : OUT STD_ULOGIC
        );
    END COMPONENT COMMUNICATION_ENTITY;
    -- Signals
    SIGNAL int_status : MachineStatus := AVAILABLE;
    SIGNAL int_status_send : STD_ULOGIC := '0';

    SIGNAL int_cmd_received : STD_ULOGIC := '0';
    SIGNAL int_cmd_cancel : STD_ULOGIC := '0';
    SIGNAL int_cmd_product : STD_ULOGIC := '0';
    SIGNAL int_product_type : ProductType := NONE;
    SIGNAL int8_converted_secs : BYTE;

    --! Syncronizer for the button(s)
    COMPONENT SYNCHRNZR IS
        PORT (
            CLK : IN STD_LOGIC;
            ASYNC_IN : IN STD_LOGIC;
            SYNC_OUT : OUT STD_LOGIC
        );
    END COMPONENT SYNCHRNZR;

    --! Intermediate signals
    -- Remaining seconds of timer FSM --> 7-Segments Manager
    SIGNAL int_remaining_time : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    -- Type of product
    SIGNAL int_product_type_string : ProductType;
    -- CANCEL Button / Synced signal & Edge
    SIGNAL CANCEL_BTN_LEVEL : STD_LOGIC := '0';
BEGIN
    --! Cancel button
    Inst00_CANCEL_BTN_SYNC : SYNCHRNZR
    PORT MAP(
        CLK => CLK100MHZ,
        ASYNC_IN => CANCEL_BUTTON,
        SYNC_OUT => CANCEL_BTN_LEVEL
    );

    Inst00_FSM0 : FSM0
    GENERIC MAP(
        g_CLK_FREQ => c_CLK_FREQ
    )
    PORT MAP(
        i_CLK => CLK100MHZ,
        i_RESET_N => CPU_RESETN,

        i_CANCEL_BTN => CANCEL_BTN_LEVEL,
        o_HEATER => LED(15),
        -- UART TELECOMS IO
        i_cmd_received => int_cmd_received,
        i_cmd_cancel => int_cmd_cancel,
        i_cmd_product => int_cmd_product,
        i_product_type => int_product_type,
        i8_converted_secs => int8_converted_secs,

        o_status => int_status,
        o_status_send => int_status_send,
        -- DISPLAY OUTPUT
        o8_REMAINING_SECS => int_remaining_time,
        o_PRODUCT_STR => int_product_type_string
    );

    Inst00_Segments_Manager : SEGMENTS_MANAGER
    GENERIC MAP(
        g_CLK_FREQ => c_CLK_FREQ,
        g_REFRESH_RATE => c_7SEGMENTS_FREQ,
        g_USED_SEGMENTS => c_USED_SEGMENTS
    )
    PORT MAP(
        i_CLK => CLK100MHZ,
        i_RESET_N => CPU_RESETN,
        i8_REMAINING_SECS => int_remaining_time,
        i_PRODUCT_TYPE => int_product_type_string,
        o7_DIGIT_SEGMENTS => DIGIT_SEGMENTS,
        o8_DIGIT_DISABLE => DIGIT_DISABLE(c_USED_SEGMENTS - 1 DOWNTO 0)
    );

    Inst00_comms_entity : COMMUNICATION_ENTITY
    GENERIC MAP(
        g_CLK_FREQ => c_CLK_FREQ,
        g_UART_FREQ => c_UART_FREQ
    )
    PORT MAP(
        i_CLK => CLK100MHZ,
        i_RESET_N => CPU_RESETN,

        i_serial_rx => SERIAL_IN,
        o_serial_tx => SERIAL_OUT,

        i_status => int_status,
        i_status_send => int_status_send,
        o_cmd_received => int_cmd_received,
        o_cmd_cancel => int_cmd_cancel,
        o_cmd_product => int_cmd_product,
        o_product_type => int_product_type,
        o8_converted_secs => int8_converted_secs,
        o_RX_brk => LED(14)
    );

    -- Deactivate unused 7-segments
    disable_unused_digits : IF c_USED_SEGMENTS < 8 GENERATE
        DIGIT_DISABLE(DIGIT_DISABLE'HIGH DOWNTO c_USED_SEGMENTS) <= (OTHERS => '1');
    END GENERATE disable_unused_digits;

    -- Turn off unused LEDS
    disable_unused_leds : IF c_USED_LEDS < 16 GENERATE
        LED(LED'high - c_USED_LEDS DOWNTO 0) <= (OTHERS => '0');
    END GENERATE disable_unused_leds;

END ARCHITECTURE Behavioral;
