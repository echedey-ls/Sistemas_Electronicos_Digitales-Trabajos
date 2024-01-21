LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY SEGMENTS_MANAGER IS
    GENERIC (
        g_CLK_FREQ : POSITIVE := 100_000_000; -- Hz
        g_REFRESH_RATE : POSITIVE := 50; -- Hz
        g_USED_SEGMENTS : POSITIVE := 3
    );
    PORT (
        i_CLK : IN STD_ULOGIC;
        i_RESET_N : IN STD_ULOGIC;
        i8_REMAINING_SECS : IN STD_ULOGIC_VECTOR(7 DOWNTO 0);
        i_PRODUCT_TYPE : IN ProductType;
        o7_DIGIT_SEGMENTS : OUT STD_ULOGIC_VECTOR(6 DOWNTO 0);
        o8_DIGIT_DISABLE : OUT STD_ULOGIC_VECTOR(g_USED_SEGMENTS - 1 DOWNTO 0)
    );
END ENTITY SEGMENTS_MANAGER;

ARCHITECTURE rtl OF SEGMENTS_MANAGER IS
    --! BINARY TO BCD CONVERTER (FROM DIGIKEY)
    COMPONENT binary_to_bcd IS
        GENERIC (
            bits : INTEGER := 10; --size of the binary input numbers in bits
            digits : INTEGER := 3); --number of BCD digits to convert to
        PORT (
            clk : IN STD_ULOGIC; --system clock
            reset_n : IN STD_ULOGIC; --active low asynchronus reset
            ena : IN STD_ULOGIC; --latches in new binary number and starts conversion
            binary : IN STD_ULOGIC_VECTOR(bits - 1 DOWNTO 0); --binary number to convert
            busy : OUT STD_ULOGIC; --indicates conversion in progress
            bcd : OUT STD_ULOGIC_VECTOR(digits * 4 - 1 DOWNTO 0)); --resulting BCD number
    END COMPONENT binary_to_bcd;
    -- Signals
    SIGNAL Converter_start : STD_ULOGIC := '0'; -- starts conversion with '1' on 1 cycle (same as ena)
    --SIGNAL Converter_busy : STD_ULOGIC := '0';
    SIGNAL BCD_Representation : STD_ULOGIC_VECTOR(g_USED_SEGMENTS * 4 - 1 DOWNTO 0);
    SIGNAL Binary_input_reg : STD_ULOGIC_VECTOR(i8_REMAINING_SECS'RANGE) := (OTHERS => '0');

    --! BCD/Binary 1 digit to a 7 segment display
    COMPONENT decoder IS
        PORT (
            code : IN STD_ULOGIC_VECTOR(3 DOWNTO 0);
            led : OUT STD_ULOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT decoder;
    ALIAS BIN2SEG IS decoder;

    --! Custom binary to 7 segment characters
    COMPONENT char_decoder IS
        PORT (
            code : IN STD_ULOGIC_VECTOR(3 DOWNTO 0);
            led : OUT STD_ULOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT char_decoder;
    TYPE character_array IS ARRAY(NATURAL RANGE <>) OF STD_ULOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL char_array : character_array(3 DOWNTO 0);

    --! From type enum to 4 chars
    COMPONENT ProductType2Chars IS
        PORT (
            prod : IN ProductType;
            code0, code1, code2, code3 : OUT STD_ULOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT ProductType2Chars;

    --! Freq. divider
    COMPONENT e21_fdivider IS
        GENERIC (
            MODULE : POSITIVE := 16
        );
        PORT (
            RESET : IN STD_ULOGIC;
            CLK : IN STD_ULOGIC;
            CE_IN : IN STD_ULOGIC;
            CE_OUT : OUT STD_ULOGIC
        );
    END COMPONENT e21_fdivider;
    -- Signals
    SIGNAL next_segment_pulse : STD_ULOGIC := '0';

    --! Local custom MUX
    SUBTYPE segments_bus IS STD_ULOGIC_VECTOR(6 DOWNTO 0);
    TYPE segments_bus_vector IS ARRAY (NATURAL RANGE <>) OF segments_bus;

    SIGNAL segments_codes_vector : segments_bus_vector(g_USED_SEGMENTS - 1 DOWNTO 0);
    SIGNAL enabled_digit : NATURAL RANGE 0 TO g_USED_SEGMENTS - 1 := 1;

    SIGNAL int_RESET : STD_ULOGIC := '1';
BEGIN
    int_RESET <= NOT i_RESET_N;
    Inst00_binary_to_bcd : binary_to_bcd
    GENERIC MAP(
        bits => 8,
        digits => g_USED_SEGMENTS
    )
    PORT MAP(
        clk => i_CLK,
        reset_n => i_RESET_N,
        ena => Converter_start,
        binary => i8_REMAINING_SECS,
        busy => OPEN,
        bcd => BCD_Representation
    );

    Inst00_freq_div_segments : e21_fdivider
    GENERIC MAP(
        MODULE => g_CLK_FREQ / g_REFRESH_RATE
    )
    PORT MAP(
        RESET => int_RESET,
        CLK => i_CLK,
        CE_IN => '1',
        CE_OUT => next_segment_pulse
    );

    --! MUX or DIGIT SELECT algorithm
    -- Map segments lines to mux inputs
    PROCESS (i_CLK, i_RESET_N)
    BEGIN
        IF i_RESET_N = '0' THEN
            enabled_digit <= 0;
        ELSIF rising_edge(i_CLK) THEN
            IF next_segment_pulse = '1' THEN
                enabled_digit <= enabled_digit + 1;
                IF enabled_digit = g_USED_SEGMENTS THEN
                    enabled_digit <= 0;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    -- Which digit to activate
    PROCESS (i_CLK, enabled_digit)
    BEGIN
        o8_DIGIT_DISABLE <= (OTHERS => '1');
        o8_DIGIT_DISABLE(enabled_digit) <= '0';
    END PROCESS;
    -- Which segments to display
    o7_DIGIT_SEGMENTS <= segments_codes_vector(enabled_digit);

    --! Detect & Start conversion on input change
    PROCESS (i_CLK, i_RESET_N, i8_REMAINING_SECS)
    BEGIN
        IF i_RESET_N = '0' THEN
            Binary_input_reg <= (OTHERS => '0');
        ELSIF rising_edge(i_CLK) THEN
            Binary_input_reg <= i8_REMAINING_SECS;
        END IF;
    END PROCESS;

    Converter_start <= '0' WHEN Binary_input_reg = i8_REMAINING_SECS ELSE
        '1';

    codes2segments_decoders : FOR index IN g_USED_SEGMENTS - 1 DOWNTO 0 GENERATE
        if_gen_segments :
        IF index < 3 GENERATE
            Inst0i_bin2seg : bin2seg
            PORT MAP(
                code => BCD_Representation(4 * index + 3 DOWNTO 4 * index),
                led => segments_codes_vector(index)
            );
        ELSIF index = 3 GENERATE
                segments_codes_vector(index) <= (OTHERS => '1');
            ELSE
                GENERATE
                    Inst0i_char2seg : char_decoder
                    PORT MAP(
                        code => char_array(index - 4),
                        led => segments_codes_vector(index)
                    );
                END GENERATE if_gen_segments;
            END GENERATE;

            -- Get product enum type
            Inst00_Prod2Chars : ProductType2Chars
            PORT MAP(
                prod => i_PRODUCT_TYPE,
                code0 => char_array(0),
                code1 => char_array(1),
                code2 => char_array(2),
                code3 => char_array(3)
            );
        END ARCHITECTURE rtl;
