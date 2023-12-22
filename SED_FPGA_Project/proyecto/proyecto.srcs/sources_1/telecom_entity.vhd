LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;

USE WORK.MACHINE_COMMON.ALL;

-- Input + 3 secs; 2 LSBs mean the type of product
ENTITY UART_RX_COMMAND_TRANSLATION IS
    PORT (
        i8_rx_code : IN BYTE;
        o_IS_CANCEL_CMD : INOUT STD_ULOGIC;
        o_product_type : OUT ProductType;
        o8_converted_secs : OUT BYTE
    );
END ENTITY UART_RX_COMMAND_TRANSLATION;

ARCHITECTURE RTL OF UART_RX_COMMAND_TRANSLATION IS
    SIGNAL int_ORDER_LSBs : STD_ULOGIC_VECTOR(1 DOWNTO 0) := "00";
    SIGNAL int_ORDER_MSBs : STD_ULOGIC_VECTOR(i8_rx_code'HIGH DOWNTO 2) := (OTHERS => '0');
BEGIN
    int_ORDER_LSBs <= i8_rx_code(int_ORDER_LSBs'HIGH DOWNTO 0);
    int_ORDER_MSBs <= i8_rx_code(i8_rx_code'HIGH DOWNTO int_ORDER_LSBs'HIGH + 1);
    o_IS_CANCEL_CMD <= '1' WHEN UNSIGNED(i8_rx_code) = 255 ELSE
        '0';
    o8_converted_secs <= int_ORDER_MSBs & "11";
    WITH o_IS_CANCEL_CMD & int_ORDER_LSBs SELECT
    o_product_type <=
        CANCEL WHEN "100" | "101" | "110" | "111",
        COFFEE WHEN "000",
        TEA WHEN "001",
        MILK WHEN "010",
        CHOCOLAT WHEN "011",
        DASHES WHEN OTHERS;
END RTL; -- RTL
