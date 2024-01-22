--------------------------------------------------------------------------------
--
--   FileName:         binary_to_bcd.vhd
--   Dependencies:     binary_to_bcd_digit.vhd
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
--   Version 1.1 6/23/2017 Scott Larson
--     Fixed small corner-case bug
--   Version 1.2 1/16/2018 Scott Larson
--     Fixed reset logic to include resetting the state machine
--
--------------------------------------------------------------------------------

library ieee;
use IEEE.STD_LOGIC_1164.all;

entity binary_to_bcd is
    generic(
        bits   : integer := 10;    --size of the binary input numbers in bits
        digits : integer := 3);         --number of BCD digits to convert to
    port(
        clk     : in  std_ulogic;       --system clock
        reset_n : in  std_ulogic;       --active low asynchronus reset
        ena     : in  std_ulogic;  --latches in new binary number and starts conversion
        binary  : in  std_ulogic_vector(bits-1 downto 0);  --binary number to convert
        busy    : out std_ulogic;       --indicates conversion in progress
        bcd     : out std_ulogic_vector(digits*4-1 downto 0));  --resulting BCD number
end binary_to_bcd;

architecture logic of binary_to_bcd is
    type machine is(idle, convert);     --needed states
    signal state            : machine;  --state machine
    signal binary_reg       : std_ulogic_vector(bits-1 downto 0);  --latched in binary number
    signal bcd_reg          : std_ulogic_vector(digits*4-1 downto 0);  --bcd result register
    signal converter_ena    : std_ulogic;  --enable into each BCD single digit converter
    signal converter_inputs : std_ulogic_vector(digits downto 0);  --inputs into each BCD single digit converter

    --binary to BCD single digit converter component
    component binary_to_bcd_digit is
        port(
            clk     : in     std_ulogic;
            reset_n : in     std_ulogic;
            ena     : in     std_ulogic;
            binary  : in     std_ulogic;
            c_out   : buffer std_ulogic;
            bcd     : buffer std_ulogic_vector(3 downto 0));
    end component binary_to_bcd_digit;

begin

    process(reset_n, clk)
        variable bit_count : integer range 0 to bits+1 := 0;  --counts the binary bits shifted into the converters
    begin
        if(reset_n = '0') then          --asynchronous reset asserted
            bit_count     := 0;         --reset bit counter
            busy          <= '1';       --indicate not available
            converter_ena <= '0';       --disable the converter
            bcd           <= (others => '0');  --clear BCD result port
            state         <= idle;      --reset state machine
        elsif(clk'event and clk = '1') then    --system clock rising edge
            case state is

                when idle =>            --idle state
                    if(ena = '1') then  --converter is enabled
                        busy          <= '1';  --indicate conversion in progress
                        converter_ena <= '1';  --enable the converter
                        binary_reg    <= binary;  --latch in binary number for conversion
                        bit_count     := 0;    --reset bit counter
                        state         <= convert;  --go to convert state
                    else                --converter is not enabled
                        busy          <= '0';  --indicate available
                        converter_ena <= '0';  --disable the converter
                        state         <= idle;    --remain in idle state
                    end if;

                when convert =>         --convert state
                    if(bit_count < bits+1) then  --not all bits shifted in
                        bit_count           := bit_count + 1;  --increment bit counter
                        converter_inputs(0) <= binary_reg(bits-1);  --shift next bit into converter
                        binary_reg          <= binary_reg(bits-2 downto 0) & '0';  --shift binary number register
                        state               <= convert;  --remain in convert state
                    else                --all bits shifted in
                        busy          <= '0';  --indicate conversion is complete
                        converter_ena <= '0';  --disable the converter
                        bcd           <= bcd_reg;        --output result
                        state         <= idle;   --return to idle state
                    end if;

            end case;
        end if;
    end process;

    --instantiate the converter logic for the specified number of digits
    bcd_digits : for i in 1 to digits generate
        digit_0 : binary_to_bcd_digit
            port map (clk, reset_n, converter_ena, converter_inputs(i-1), converter_inputs(i), bcd_reg(i*4-1 downto i*4-4));
    end generate;

end logic;
