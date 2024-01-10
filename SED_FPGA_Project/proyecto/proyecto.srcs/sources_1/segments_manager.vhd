LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

ENTITY SEGMENTS_MANAGER IS
    GENERIC (
        g_CLK_FREQ : POSITIVE := 100_000_000; -- Hz
        g_REFRESH_RATE : POSITIVE := 50; -- Hz
        g_USED_SEGMENTS : POSITIVE := 3
    );
    PORT (
        i_CLK : IN STD_LOGIC;
        i_RESET_N : IN STD_LOGIC;
        i8_REMAINING_SECS : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        o7_DIGIT_SEGMENTS : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        o8_DIGIT_DISABLE : OUT STD_LOGIC_VECTOR(g_USED_SEGMENTS - 1 DOWNTO 0)
    );
END ENTITY SEGMENTS_MANAGER;

ARCHITECTURE rtl OF SEGMENTS_MANAGER IS
    --! BINARY TO BCD CONVERTER (FROM DIGIKEY)
    COMPONENT binary_to_bcd IS
        GENERIC (
            bits : INTEGER := 10; --size of the binary input numbers in bits
            digits : INTEGER := 3); --number of BCD digits to convert to
        PORT (
            clk : IN STD_LOGIC; --system clock
            reset_n : IN STD_LOGIC; --active low asynchronus reset
            ena : IN STD_LOGIC; --latches in new binary number and starts conversion
            binary : IN STD_LOGIC_VECTOR(bits - 1 DOWNTO 0); --binary number to convert
            busy : OUT STD_LOGIC; --indicates conversion in progress
            bcd : OUT STD_LOGIC_VECTOR(digits * 4 - 1 DOWNTO 0)); --resulting BCD number
    END COMPONENT binary_to_bcd;
    -- Signals
    SIGNAL Converter_start : STD_LOGIC := '0'; -- starts conversion with '1' on 1 cycle (same as ena)
    --SIGNAL Converter_busy : STD_LOGIC := '0';
    SIGNAL BCD_Representation : STD_LOGIC_VECTOR(g_USED_SEGMENTS * 4 - 1 DOWNTO 0);
    SIGNAL Binary_input_reg : STD_LOGIC_VECTOR(i8_REMAINING_SECS'RANGE) := (OTHERS => '0');

    --! BCD/Binary 1 digit to a 7 segment display
    COMPONENT decoder IS
        PORT (
            code : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            led : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT decoder;
    ALIAS BIN2SEG IS decoder;

    --! Freq. divider
    COMPONENT e21_fdivider IS
        GENERIC (
            MODULE : POSITIVE := 16
        );
        PORT (
            RESET : IN STD_LOGIC;
            CLK : IN STD_LOGIC;
            CE_IN : IN STD_LOGIC;
            CE_OUT : OUT STD_LOGIC
        );
    END COMPONENT e21_fdivider;
    -- Signals
    SIGNAL bcd_digit_next : STD_LOGIC := '0';

    --! Local custom MUX
    SUBTYPE bcd_bus IS STD_LOGIC_VECTOR(3 DOWNTO 0);
    TYPE bcd_bus_vector IS ARRAY (NATURAL RANGE <>) OF bcd_bus;

    SIGNAL bcd_codes_vector : bcd_bus_vector(g_USED_SEGMENTS - 1 DOWNTO 0) := (OTHERS => "0000");
    SIGNAL enabled_digit : POSITIVE RANGE 0 TO g_USED_SEGMENTS - 1 := 1;
    SIGNAL bcd_displayed : bcd_bus := "0000";
BEGIN
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
        RESET => NOT i_RESET_N,
        CLK => i_CLK,
        CE_IN => '1',
        CE_OUT => bcd_digit_next
    );

    --! MUX or DIGIT SELECT algorithm
    -- Map BCD lines to mux inputs
    bcd_lines_gen : FOR i IN bcd_codes_vector'RANGE GENERATE
        bcd_codes_vector(i) <= BCD_Representation(4 * i + 3 DOWNTO 4 * i);
    END GENERATE bcd_lines_gen;
    PROCESS (i_CLK, i_RESET_N)
    BEGIN
        IF i_RESET_N = '0' THEN
            enabled_digit <= 0;
        ELSIF rising_edge(i_CLK) THEN
            IF bcd_digit_next = '1' THEN
                enabled_digit <= enabled_digit + 1;
                IF enabled_digit = g_USED_SEGMENTS THEN
                    enabled_digit <= 0;
                END IF;
            END IF;
        END IF;
    END PROCESS;
    -- Which digit to activate
    PROCESS (i_CLK)
    BEGIN
        o8_DIGIT_DISABLE <= (OTHERS => '1');
        o8_DIGIT_DISABLE(enabled_digit) <= '0';
    END PROCESS;
    -- Which BCD code to take
    bcd_displayed <= bcd_codes_vector(enabled_digit);

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

    Inst00_bin2seg : bin2seg
    PORT MAP(
        code => bcd_displayed,
        led => o7_DIGIT_SEGMENTS
    );

END ARCHITECTURE rtl;
