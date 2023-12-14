LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY TOP IS
    PORT (
        CLK100MHZ : IN STD_LOGIC;
        CPU_RESETN : IN STD_LOGIC;
        SERIAL_IN : IN STD_LOGIC;
        LED : OUT STD_LOGIC_VECTOR (15 DOWNTO 0)
    );
END TOP;

ARCHITECTURE Behavioral OF TOP IS
    COMPONENT fluart IS -- Credits to https://github.com/marcj71/fluart
        GENERIC (
            CLK_FREQ : INTEGER := 50_000_000; -- main frequency (Hz)
            SER_FREQ : INTEGER := 115200; -- bit rate (bps), any number up to CLK_FREQ / 2
            BRK_LEN : INTEGER := 10 -- break duration (tx), minimum break duration (rx) in bits
        );
        PORT (
            clk : IN STD_LOGIC;
            reset : IN STD_LOGIC;

            rxd : IN STD_LOGIC;
            txd : OUT STD_LOGIC;

            tx_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
            tx_req : IN STD_LOGIC;
            tx_brk : IN STD_LOGIC;
            tx_busy : OUT STD_LOGIC;
            tx_end : OUT STD_LOGIC;
            rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rx_data_valid : OUT STD_LOGIC;
            rx_brk : OUT STD_LOGIC;
            rx_err : OUT STD_LOGIC
        );
    END COMPONENT;

    -- Internal Signals

    -- UART
    SIGNAL Recv_flag : STD_LOGIC := '0';
    SIGNAL Send_flag : STD_LOGIC := '0';
    SIGNAL rx_brk : STD_LOGIC := '0';
    
    SIGNAL LEDS_internal : STD_LOGIC_VECTOR (15 DOWNTO 0) := (OTHERS => '0');
BEGIN
    Inst00_uart : fluart
    GENERIC MAP(
        CLK_FREQ => 100_000_000,
        SER_FREQ => 10_000
    )
    PORT MAP(
        clk => CLK100MHZ,
        reset => CPU_RESETN,

        rxd => SERIAL_IN,
        txd => open,

        tx_data => open,
        tx_req => '0',
        tx_brk => '0',
        tx_busy => open,
        tx_end => open,

        rx_data => LEDS_internal(7 DOWNTO 0),
        rx_data_valid => Recv_flag,
        rx_brk => rx_brk,
        rx_err => open
    );
    LEDS_internal(15) <= rx_brk;
    LED <= LEDS_internal WHEN Recv_flag = '1' else LED;

END Behavioral;