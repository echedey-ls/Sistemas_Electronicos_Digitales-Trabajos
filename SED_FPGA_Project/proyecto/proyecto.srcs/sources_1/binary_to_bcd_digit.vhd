--------------------------------------------------------------------------------
--
--   FileName:         binary_to_bcd_digit.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 13.1.0 Build 162 SJ Web Edition
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 6/15/2017 Scott Larson
--     Initial Public Release
--
--------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.all;

entity binary_to_bcd_digit is
    port(
        clk     : in     std_ulogic;    --system clock
        reset_n : in     std_ulogic;    --active low asynchronous reset
        ena     : in     std_ulogic;    --activate operation
        binary  : in     std_ulogic;    --bit shifted into digit
        c_out   : buffer std_ulogic;  --carry out shifted to next larger digit
        bcd     : buffer std_ulogic_vector(3 downto 0));  --resulting BCD output
end binary_to_bcd_digit;

architecture logic of binary_to_bcd_digit is
    signal prev_ena : std_ulogic;  --keeps track of the previous enable to identify when enable is first asserted
begin

    c_out <= bcd(3) or (bcd(2) and bcd(1)) or (bcd(2) and bcd(0));  --assert carry out when register value exceeds 4

    process(reset_n, clk)
    begin
        if(reset_n = '0') then          --asynchronous reset asserted
            prev_ena <= '0';            --clear ena history
            bcd      <= "0000";         --clear output
        elsif(clk'event and clk = '1') then       --rising edge of system clock
            prev_ena <= ena;            --keep track of last enable
            if(ena = '1') then          --operation activated
                if(prev_ena = '0') then    --first cycle of activation
                    bcd <= "0000";      --initialize the register
                elsif(c_out = '1') then    --register value exceeds 4
                    bcd(0) <= binary;   --shift new bit into first register
                    bcd(1) <= not bcd(0);  --set second register to adjusted value
                    bcd(2) <= not (bcd(1) xor bcd(0));  --set third register to adjusted value
                    bcd(3) <= bcd(3) and bcd(0);  --set fourth register to adjusted value
                else                    --register value does not exceed 4
                    bcd <= bcd(2 downto 0) & binary;  --shift register values up and shift in new bit
                end if;
            end if;
        end if;
    end process;

end logic;
