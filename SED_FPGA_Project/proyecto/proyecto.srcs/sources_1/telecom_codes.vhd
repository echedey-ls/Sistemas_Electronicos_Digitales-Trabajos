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

    SUBTYPE BYTE IS STD_LOGIC_VECTOR(7 DOWNTO 0);

    FUNCTION MachineStatus2Byte(st : IN MachineStatus) RETURN BYTE;
END PACKAGE MACHINE_COMMON;

PACKAGE BODY MACHINE_COMMON IS
    FUNCTION MachineStatus2Byte(st : IN MachineStatus) RETURN BYTE IS
    BEGIN
        CASE st IS
            WHEN FAULT => return "01111111"; -- 0x7F
            WHEN BUSY => return "00000001"; -- 0x01
            WHEN AVAILABLE => return "00000010"; -- 0x02
            WHEN FINISHED => return "00000011"; -- 0x03
            WHEN OTHERS => return "10000000"; -- 0x80
        end case;
    END FUNCTION MachineStatus2Byte;
END PACKAGE BODY MACHINE_COMMON;
