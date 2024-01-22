-- Set of utils for the FPGA <> MICROCONTROLLER interface
library IEEE;
use IEEE.STD_LOGIC_1164.all;

package MACHINE_COMMON is
    type MachineStatus is (
        CANCELLED,
        BUSY,
        AVAILABLE,
        FINISHED,
        STARTED_PROD
        );

    type ProductType is (
        NONE,
        DASHES,
        CANCEL,
        COFFEE,
        TEA,
        MILK,
        CHOCOLAT
        );

    subtype BYTE is std_ulogic_vector(7 downto 0);

    --! Convert Machine Status to 8bits to UART TX
    function MachineStatus2Byte(
        st : in MachineStatus
        ) return BYTE;
    --! Two LSBs input from UART define the Product Type
    function Bits2ProductType(
        bits : in std_logic_vector
        ) return ProductType;
end package MACHINE_COMMON;

package body MACHINE_COMMON is
    function MachineStatus2Byte(st : in MachineStatus) return BYTE is
    begin
        case st is
            when CANCELLED    => return "01111111";  -- 0x7F
            when BUSY         => return "00000001";  -- 0x01
            when AVAILABLE    => return "00000010";  -- 0x02
            when FINISHED     => return "00000011";  -- 0x03
            when STARTED_PROD => return "00000100";  -- 0x04
            when others       => return "10000000";  -- 0x80
        end case;
    end function MachineStatus2Byte;

    function Bits2ProductType(
        bits : in std_logic_vector
        ) return ProductType is
        alias bits_alias : std_logic_vector(bits'length downto 0) is bits;  -- ghdl error bypass
    begin
        assert bits'length = 2;
        case bits_alias is
            when "00"   => return COFFEE;
            when "01"   => return TEA;
            when "10"   => return MILK;
            when "11"   => return CHOCOLAT;
            when others => null;
        end case;
    end function Bits2ProductType;
end package body MACHINE_COMMON;
