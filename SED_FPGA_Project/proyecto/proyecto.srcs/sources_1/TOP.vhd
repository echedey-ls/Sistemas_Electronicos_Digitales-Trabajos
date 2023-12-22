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
END TOP;

ARCHITECTURE Behavioral OF TOP IS
    --! Logic Manager
    COMPONENT FSM0 IS
        GENERIC (
            g_CLK_FREQ : POSITIVE := 100_000_000;
            g_UART_FREQ : POSITIVE := 10_000
        );
        PORT (
            i_CLK : IN STD_LOGIC;
            i_RESET_N : IN STD_LOGIC;
            i_CANCEL_BTN : IN STD_LOGIC;
            i_SERIAL_IN : IN STD_LOGIC;
            o_SERIAL_OUT : OUT STD_LOGIC;
            o_RX_BRK_LED : OUT STD_LOGIC;
            o_HEATER : OUT STD_LOGIC;
            o8_REMAINING_SECS : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            o_PRODUCT_STR : OUT ProductType;
            oo_UART_DBG : OUT STD_LOGIC_VECTOR
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
    SIGNAL REMAINING_SECS : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    -- Type of product
    SIGNAL PRODUCT_TYPE : ProductType;
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
        g_CLK_FREQ => c_CLK_FREQ,
        g_UART_FREQ => c_UART_FREQ
    )
    PORT MAP(
        i_CLK => CLK100MHZ,
        i_RESET_N => CPU_RESETN,
        i_CANCEL_BTN => CANCEL_BTN_LEVEL,
        i_SERIAL_IN => SERIAL_IN,
        o_SERIAL_OUT => SERIAL_OUT,
        o_RX_BRK_LED => LED(14),
        o_HEATER => LED(15),
        o8_REMAINING_SECS => REMAINING_SECS,
        o_PRODUCT_STR => PRODUCT_TYPE,
        oo_UART_DBG => LED(13 DOWNTO 0)
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
        i8_REMAINING_SECS => REMAINING_SECS,
        i_PRODUCT_TYPE => PRODUCT_TYPE,
        o7_DIGIT_SEGMENTS => DIGIT_SEGMENTS,
        o8_DIGIT_DISABLE => DIGIT_DISABLE(c_USED_SEGMENTS - 1 DOWNTO 0)
    );
    -- Deactivate unused 7-segments
    disable_unused_digits : IF c_USED_SEGMENTS < 8 GENERATE
        DIGIT_DISABLE(DIGIT_DISABLE'HIGH DOWNTO c_USED_SEGMENTS) <= (OTHERS => '1');
    END GENERATE disable_unused_digits;

END ARCHITECTURE Behavioral;
