-- Set of utils for the FPGA <> MICROCONTROLLER interface
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

PACKAGE MACHINE_COMMON IS
    TYPE MachineStatus IS (
        FAULT,
        BUSY,
        AVAILABLE,
        FINISHED
    );

    TYPE ProductType IS (
        COFFEE,
        TEA,
        MILK,
        CHOCOLAT,
        NONE
    );

    SUBTYPE BYTE IS STD_LOGIC_VECTOR(7 DOWNTO 0);

    FUNCTION MachineStatus2Byte(st : IN MachineStatus) RETURN BYTE;
    FUNCTION Bits2ProductType(bits : IN STD_LOGIC_VECTOR) RETURN ProductType;
END PACKAGE MACHINE_COMMON;

PACKAGE BODY MACHINE_COMMON IS
    FUNCTION MachineStatus2Byte(st : IN MachineStatus) RETURN BYTE IS
    BEGIN
        CASE st IS
            WHEN FAULT => RETURN "01111111"; -- 0x7F
            WHEN BUSY => RETURN "00000001"; -- 0x01
            WHEN AVAILABLE => RETURN "00000010"; -- 0x02
            WHEN FINISHED => RETURN "00000011"; -- 0x03
            WHEN OTHERS => RETURN "10000000"; -- 0x80
        END CASE;
    END FUNCTION MachineStatus2Byte;

    FUNCTION Bits2ProductType(bits : IN STD_LOGIC_VECTOR) RETURN ProductType IS
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
