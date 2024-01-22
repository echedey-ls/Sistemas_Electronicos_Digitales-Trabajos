library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.numeric_std.all;

use WORK.MACHINE_COMMON.all;

entity COMMUNICATION_ENTITY is
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
        o8_converted_secs : out   BYTE;  -- Input byte 6 MSBs + 3 secs; 2 LSBs mean the type of product
        o_RX_brk          : out   std_ulogic
        );
end entity COMMUNICATION_ENTITY;

architecture comms_ent_arch of COMMUNICATION_ENTITY is
    --! Edge detector for i_status_send
    component EDGEDTCTR is
        generic (
            REG_LENGTH : positive := 1
            );
        port (
            CLK, RST_N : in  std_ulogic;
            SYNC_IN    : in  std_ulogic;
            EDGE       : out std_ulogic
            );
    end component EDGEDTCTR;

    --! UART
    component fluart is  -- Credits to https://github.com/marcj71/fluart
        generic (
            CLK_FREQ : integer := 50_000_000;  -- main frequency (Hz)
            SER_FREQ : integer := 115200;  -- bit rate (bps), any number up to CLK_FREQ / 2
            BRK_LEN  : integer := 10  -- break duration (tx), minimum break duration (rx) in bits
            );
        port (
            clk   : in std_ulogic;
            reset : in std_ulogic;

            rxd : in  std_ulogic;
            txd : out std_ulogic;

            tx_data       : in  std_ulogic_vector(7 downto 0) := (others => '0');
            tx_req        : in  std_ulogic;
            tx_brk        : in  std_ulogic;
            tx_busy       : out std_ulogic;
            tx_end        : out std_ulogic;
            rx_data       : out std_ulogic_vector(7 downto 0);
            rx_data_valid : out std_ulogic;
            rx_brk        : out std_ulogic;
            rx_err        : out std_ulogic
            );
    end component fluart;
    -- Signals
    signal int_UART_RX_DATA     : BYTE                          := (others => '0');
    signal int_UART_TX_pulse    : std_ulogic                    := '0';
    signal int_Send_status_byte : std_ulogic_vector(7 downto 0) := (others => '0');

    signal int_RCV_CMD_LSBs : std_ulogic_vector(1 downto 0)                     := "00";
    signal int_RCV_CMD_MSBs : std_ulogic_vector(int_UART_RX_DATA'high downto 2) := (others => '0');

    signal int_RESET : std_ulogic := '1';
begin
    int_RESET <= not i_RESET_N;
    --! Edge detector, send data pulse
    Inst00_UART_TX_REQ_PULSE : EDGEDTCTR
        port map(
            CLK     => i_CLK,
            RST_N   => i_RESET_N,
            SYNC_IN => i_status_send,
            EDGE    => int_UART_TX_pulse
            );

    --! UART instantiation
    int_Send_status_byte <= MachineStatus2Byte(i_status);
    Inst00_uart : fluart
        generic map(
            CLK_FREQ => g_CLK_FREQ,
            SER_FREQ => g_UART_FREQ
            )
        port map(
            clk   => i_CLK,
            reset => int_RESET,

            rxd => i_serial_rx,
            txd => o_serial_tx,

            tx_data => int_Send_status_byte,
            tx_req  => int_UART_TX_pulse,
            tx_brk  => '0',
            tx_busy => open,
            tx_end  => open,

            rx_data       => int_UART_RX_DATA,
            rx_data_valid => o_cmd_received,
            rx_brk        => o_RX_brk,
            rx_err        => open
            );
    int_RCV_CMD_LSBs <= int_UART_RX_DATA(int_RCV_CMD_LSBs'high downto 0);
    int_RCV_CMD_MSBs <= int_UART_RX_DATA(int_UART_RX_DATA'high downto int_RCV_CMD_LSBs'high + 1);
    o_cmd_cancel     <= '1' when unsigned(int_UART_RX_DATA) = 255 else
                    '0';
    o_cmd_product     <= not o_cmd_cancel;
    o8_converted_secs <= int_RCV_CMD_MSBs & "11";
    o_product_type <=
        CANCEL   when o_cmd_cancel = '1' else
        COFFEE   when int_RCV_CMD_LSBs = "00" else
        TEA      when int_RCV_CMD_LSBs = "01" else
        MILK     when int_RCV_CMD_LSBs = "10" else
        CHOCOLAT when int_RCV_CMD_LSBs = "11" else
        NONE;
end architecture comms_ent_arch;
