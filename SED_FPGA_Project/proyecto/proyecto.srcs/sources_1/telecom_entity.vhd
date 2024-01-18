LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY COMMUNICATION_ENTITY IS
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
        o8_converted_secs : OUT BYTE; -- Input byte 6 MSBs + 3 secs; 2 LSBs mean the type of product
        o_RX_brk : OUT STD_ULOGIC
    );
END ENTITY COMMUNICATION_ENTITY;

ARCHITECTURE comms_ent_arch OF COMMUNICATION_ENTITY IS
    --! Edge detector for i_status_send
    COMPONENT EDGEDTCTR IS
        GENERIC (
            REG_LENGTH : POSITIVE := 1
        );
        PORT (
            CLK, RST_N : IN STD_ULOGIC;
            SYNC_IN : IN STD_ULOGIC;
            EDGE : OUT STD_ULOGIC
        );
    END COMPONENT EDGEDTCTR;

    --! UART
    COMPONENT fluart IS -- Credits to https://github.com/marcj71/fluart
        GENERIC (
            CLK_FREQ : INTEGER := 50_000_000; -- main frequency (Hz)
            SER_FREQ : INTEGER := 115200; -- bit rate (bps), any number up to CLK_FREQ / 2
            BRK_LEN : INTEGER := 10 -- break duration (tx), minimum break duration (rx) in bits
        );
        PORT (
            clk : IN STD_ULOGIC;
            reset : IN STD_ULOGIC;

            rxd : IN STD_ULOGIC;
            txd : OUT STD_ULOGIC;

            tx_data : IN STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
            tx_req : IN STD_ULOGIC;
            tx_brk : IN STD_ULOGIC;
            tx_busy : OUT STD_ULOGIC;
            tx_end : OUT STD_ULOGIC;
            rx_data : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
            rx_data_valid : OUT STD_ULOGIC;
            rx_brk : OUT STD_ULOGIC;
            rx_err : OUT STD_ULOGIC
        );
    END COMPONENT fluart;
    -- Signals
    SIGNAL int_UART_RX_DATA : BYTE := (OTHERS => '0');
    SIGNAL int_UART_TX_pulse : STD_ULOGIC := '0';
    SIGNAL int_Send_status_byte : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    SIGNAL int_RCV_CMD_LSBs : STD_ULOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL int_RCV_CMD_MSBs : STD_ULOGIC_VECTOR(int_UART_RX_DATA'HIGH DOWNTO 2) := (OTHERS => '0');
BEGIN
    --! Edge detector, send data pulse
    Inst00_UART_TX_REQ_PULSE : EDGEDTCTR
    PORT MAP(
        CLK => i_CLK,
        RST_N => i_RESET_N,
        SYNC_IN => i_status_send,
        EDGE => int_UART_TX_pulse
    );

    --! UART instantiation
    int_Send_status_byte <= MachineStatus2Byte(i_status);
    Inst00_uart : fluart
    GENERIC MAP(
        CLK_FREQ => g_CLK_FREQ,
        SER_FREQ => g_UART_FREQ
    )
    PORT MAP(
        clk => i_CLK,
        reset => NOT i_RESET_N,

        rxd => i_serial_rx,
        txd => o_serial_tx,

        tx_data => int_Send_status_byte,
        tx_req => int_UART_TX_pulse,
        tx_brk => '0',
        tx_busy => OPEN,
        tx_end => OPEN,

        rx_data => int_UART_RX_DATA,
        rx_data_valid => o_cmd_received,
        rx_brk => o_RX_brk,
        rx_err => OPEN
    );
    int_RCV_CMD_LSBs <= int_UART_RX_DATA(int_RCV_CMD_LSBs'HIGH DOWNTO 0);
    int_RCV_CMD_MSBs <= int_UART_RX_DATA(int_UART_RX_DATA'HIGH DOWNTO int_RCV_CMD_LSBs'HIGH + 1);
    o_cmd_cancel <= '1' WHEN UNSIGNED(int_UART_RX_DATA) = 255 ELSE
        '0';
    o_cmd_product <= NOT o_cmd_cancel;
    o8_converted_secs <= int_RCV_CMD_MSBs & "11";
    o_product_type <=
        CANCEL WHEN o_cmd_cancel = '1' ELSE
        COFFEE WHEN int_RCV_CMD_LSBs = "00" ELSE
        TEA WHEN int_RCV_CMD_LSBs = "01" ELSE
        MILK WHEN int_RCV_CMD_LSBs = "10" ELSE
        CHOCOLAT WHEN int_RCV_CMD_LSBs = "11" ELSE
        NONE;
END ARCHITECTURE comms_ent_arch;
