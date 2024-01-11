-- Set of utils for the FPGA <> MICROCONTROLLER interface
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

PACKAGE MACHINE_COMMON IS
    TYPE MachineStatus IS (
        CANCELLED,
        BUSY,
        AVAILABLE,
        FINISHED
    );

    TYPE ProductType IS (
        NONE,
        DASHES,
        CANCEL,
        COFFEE,
        TEA,
        MILK,
        CHOCOLAT
    );

    SUBTYPE BYTE IS STD_ULOGIC_VECTOR(7 DOWNTO 0);

    --! Convert Machine Status to 8bits to UART TX
    FUNCTION MachineStatus2Byte(
        st : IN MachineStatus
    ) RETURN BYTE;
    --! Two LSBs input from UART define the Product Type
    FUNCTION Bits2ProductType(
        bits : IN STD_ULOGIC_VECTOR
    ) RETURN ProductType;
END PACKAGE MACHINE_COMMON;

PACKAGE BODY MACHINE_COMMON IS
    FUNCTION MachineStatus2Byte(st : IN MachineStatus) RETURN BYTE IS
    BEGIN
        CASE st IS
            WHEN CANCELLED => RETURN "01111111"; -- 0x7F
            WHEN BUSY => RETURN "00000001"; -- 0x01
            WHEN AVAILABLE => RETURN "00000010"; -- 0x02
            WHEN FINISHED => RETURN "00000011"; -- 0x03
            WHEN OTHERS => RETURN "10000000"; -- 0x80
        END CASE;
    END FUNCTION MachineStatus2Byte;

    FUNCTION Bits2ProductType(
        bits : IN STD_ULOGIC_VECTOR
    ) RETURN ProductType IS
    BEGIN
        ASSERT bits'length = 2;
        CASE bits IS
            WHEN "00" => RETURN COFFEE;
            WHEN "01" => RETURN TEA;
            WHEN "10" => RETURN MILK;
            WHEN "11" => RETURN CHOCOLAT;
        END CASE;
    END FUNCTION Bits2ProductType;
END PACKAGE BODY MACHINE_COMMON;
