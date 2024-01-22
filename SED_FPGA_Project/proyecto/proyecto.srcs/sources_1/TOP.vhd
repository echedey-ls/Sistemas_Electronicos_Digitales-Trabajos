library IEEE;
use IEEE.STD_LOGIC_1164.all;

use WORK.MACHINE_COMMON.all;

entity TOP is
    port (
        CLK100MHZ      : in  std_logic;
        CPU_RESETN     : in  std_logic;
        CANCEL_BUTTON  : in  std_logic;
        SERIAL_IN      : in  std_logic;
        SERIAL_OUT     : out std_logic;
        LED            : out std_logic_vector (15 downto 0);
        DIGIT_SEGMENTS : out std_logic_vector(6 downto 0);
        DIGIT_DISABLE  : out std_logic_vector(7 downto 0)
        );
    constant c_CLK_FREQ       : positive := 100_000_000;  -- Hz
    constant c_UART_FREQ      : positive := 10_000;       -- Hz
    constant c_7SEGMENTS_FREQ : positive := 2_000;  -- Hz, refresh rate of each of the 7 segments
    constant c_USED_SEGMENTS  : positive := 8;
    constant c_USED_LEDS      : positive := 2;
end TOP;

architecture Behavioral of TOP is
    --! Logic Manager
    component FSM0 is
        generic (
            g_CLK_FREQ : positive := 100_000_000
            );
        port (
            i_CLK     : in std_ulogic;
            i_RESET_N : in std_ulogic;

            i_CANCEL_BTN      : in  std_ulogic;
            o_HEATER          : out std_ulogic;
            -- UART TELECOMS IO
            i_cmd_received    : in  std_ulogic;
            i_cmd_cancel      : in  std_ulogic;
            i_cmd_product     : in  std_ulogic;
            i_product_type    : in  ProductType;
            i8_converted_secs : in  BYTE;

            o_status          : inout MachineStatus;
            o_status_send     : out   std_ulogic;
            -- DISPLAY OUTPUT
            o8_REMAINING_SECS : out   std_ulogic_vector(7 downto 0);
            o_PRODUCT_STR     : out   ProductType
            );
    end component FSM0;

    --! HID Manager
    component SEGMENTS_MANAGER is
        generic (
            g_CLK_FREQ      : positive := 100_000_000;  -- Hz
            g_REFRESH_RATE  : positive := 50;           -- Hz
            g_USED_SEGMENTS : positive := 3
            );
        port (
            i_CLK             : in  std_logic;
            i_RESET_N         : in  std_logic;
            i8_REMAINING_SECS : in  std_logic_vector(7 downto 0);
            i_PRODUCT_TYPE    : in  ProductType;
            o7_DIGIT_SEGMENTS : out std_logic_vector(6 downto 0);
            o8_DIGIT_DISABLE  : out std_logic_vector(g_USED_SEGMENTS - 1 downto 0)
            );
    end component SEGMENTS_MANAGER;

    --!
    component COMMUNICATION_ENTITY is
        generic (
            g_CLK_FREQ  : positive := 100_000_000;
            g_UART_FREQ : positive := 10_000
            );
        port (
            i_CLK     : in std_ulogic;
            i_RESET_N : in std_ulogic;

            i_serial_rx : in  std_ulogic;
            o_serial_tx : out std_ulogic;

            i_status      : in MachineStatus;
            i_status_send : in std_ulogic;

            o_cmd_received    : out   std_ulogic;
            o_cmd_cancel      : inout std_ulogic;
            o_cmd_product     : out   std_ulogic;
            o_product_type    : out   ProductType;
            o8_converted_secs : out   BYTE;  -- Input BYTE 6 MSBs + 3 secs; 2 LSBs mean the type of product
            o_RX_brk          : out   std_ulogic
            );
    end component COMMUNICATION_ENTITY;
    -- Signals
    signal int_status      : MachineStatus := AVAILABLE;
    signal int_status_send : std_ulogic    := '0';

    signal int_cmd_received    : std_ulogic  := '0';
    signal int_cmd_cancel      : std_ulogic  := '0';
    signal int_cmd_product     : std_ulogic  := '0';
    signal int_product_type    : ProductType := NONE;
    signal int8_converted_secs : BYTE;

    --! Syncronizer for the button(s)
    component SYNCHRNZR is
        port (
            CLK      : in  std_logic;
            ASYNC_IN : in  std_logic;
            SYNC_OUT : out std_logic
            );
    end component SYNCHRNZR;

    --! Intermediate signals
    -- Remaining seconds of timer FSM --> 7-Segments Manager
    signal int_remaining_time      : std_logic_vector(7 downto 0) := (others => '0');
    -- Type of product
    signal int_product_type_string : ProductType;
    -- CANCEL Button / Synced signal & Edge
    signal CANCEL_BTN_LEVEL        : std_logic                    := '0';
begin
    --! Cancel button
    Inst00_CANCEL_BTN_SYNC : SYNCHRNZR
        port map(
            CLK      => CLK100MHZ,
            ASYNC_IN => CANCEL_BUTTON,
            SYNC_OUT => CANCEL_BTN_LEVEL
            );

    Inst00_FSM0 : FSM0
        generic map(
            g_CLK_FREQ => c_CLK_FREQ
            )
        port map(
            i_CLK     => CLK100MHZ,
            i_RESET_N => CPU_RESETN,

            i_CANCEL_BTN      => CANCEL_BTN_LEVEL,
            o_HEATER          => LED(15),
            -- UART TELECOMS IO
            i_cmd_received    => int_cmd_received,
            i_cmd_cancel      => int_cmd_cancel,
            i_cmd_product     => int_cmd_product,
            i_product_type    => int_product_type,
            i8_converted_secs => int8_converted_secs,

            o_status          => int_status,
            o_status_send     => int_status_send,
            -- DISPLAY OUTPUT
            o8_REMAINING_SECS => int_remaining_time,
            o_PRODUCT_STR     => int_product_type_string
            );

    Inst00_Segments_Manager : SEGMENTS_MANAGER
        generic map(
            g_CLK_FREQ      => c_CLK_FREQ,
            g_REFRESH_RATE  => c_7SEGMENTS_FREQ,
            g_USED_SEGMENTS => c_USED_SEGMENTS
            )
        port map(
            i_CLK             => CLK100MHZ,
            i_RESET_N         => CPU_RESETN,
            i8_REMAINING_SECS => int_remaining_time,
            i_PRODUCT_TYPE    => int_product_type_string,
            o7_DIGIT_SEGMENTS => DIGIT_SEGMENTS,
            o8_DIGIT_DISABLE  => DIGIT_DISABLE(c_USED_SEGMENTS - 1 downto 0)
            );

    Inst00_comms_entity : COMMUNICATION_ENTITY
        generic map(
            g_CLK_FREQ  => c_CLK_FREQ,
            g_UART_FREQ => c_UART_FREQ
            )
        port map(
            i_CLK     => CLK100MHZ,
            i_RESET_N => CPU_RESETN,

            i_serial_rx => SERIAL_IN,
            o_serial_tx => SERIAL_OUT,

            i_status          => int_status,
            i_status_send     => int_status_send,
            o_cmd_received    => int_cmd_received,
            o_cmd_cancel      => int_cmd_cancel,
            o_cmd_product     => int_cmd_product,
            o_product_type    => int_product_type,
            o8_converted_secs => int8_converted_secs,
            o_RX_brk          => LED(14)
            );

    -- Deactivate unused 7-segments
    disable_unused_digits : if c_USED_SEGMENTS < 8 generate
        DIGIT_DISABLE(DIGIT_DISABLE'high downto c_USED_SEGMENTS) <= (others => '1');
    end generate disable_unused_digits;

    -- Turn off unused LEDS
    disable_unused_leds : if c_USED_LEDS < 16 generate
        LED(LED'high - c_USED_LEDS downto 0) <= (others => '0');
    end generate disable_unused_leds;

end architecture Behavioral;
