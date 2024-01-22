library IEEE;
use IEEE.STD_LOGIC_1164.all;

use WORK.MACHINE_COMMON.all;

entity SEGMENTS_MANAGER is
    generic (
        g_CLK_FREQ      : positive := 100_000_000;  -- Hz
        g_REFRESH_RATE  : positive := 50;           -- Hz
        g_USED_SEGMENTS : positive := 3
        );
    port (
        i_CLK             : in  std_ulogic;
        i_RESET_N         : in  std_ulogic;
        i8_REMAINING_SECS : in  std_ulogic_vector(7 downto 0);
        i_PRODUCT_TYPE    : in  ProductType;
        o7_DIGIT_SEGMENTS : out std_ulogic_vector(6 downto 0);
        o8_DIGIT_DISABLE  : out std_ulogic_vector(g_USED_SEGMENTS - 1 downto 0)
        );
end entity SEGMENTS_MANAGER;

architecture rtl of SEGMENTS_MANAGER is
    --! BINARY TO BCD CONVERTER (FROM DIGIKEY)
    component binary_to_bcd is
        generic (
            bits   : integer := 10;  --size of the binary input numbers in bits
            digits : integer := 3);     --number of BCD digits to convert to
        port (
            clk     : in  std_ulogic;   --system clock
            reset_n : in  std_ulogic;   --active low asynchronus reset
            ena     : in  std_ulogic;  --latches in new binary number and starts conversion
            binary  : in  std_ulogic_vector(bits - 1 downto 0);  --binary number to convert
            busy    : out std_ulogic;   --indicates conversion in progress
            bcd     : out std_ulogic_vector(digits * 4 - 1 downto 0));  --resulting BCD number
    end component binary_to_bcd;
    -- Signals
    signal Converter_start    : std_ulogic                                 := '0';  -- starts conversion with '1' on 1 cycle (same as ena)
    --SIGNAL Converter_busy : STD_ULOGIC := '0';
    signal BCD_Representation : std_ulogic_vector(g_USED_SEGMENTS * 4 - 1 downto 0);
    signal Binary_input_reg   : std_ulogic_vector(i8_REMAINING_SECS'range) := (others => '0');

    --! BCD/Binary 1 digit to a 7 segment display
    component decoder is
        port (
            code : in  std_ulogic_vector(3 downto 0);
            led  : out std_ulogic_vector(6 downto 0)
            );
    end component decoder;
    alias BIN2SEG is decoder;

    --! Custom binary to 7 segment characters
    component char_decoder is
        port (
            code : in  std_ulogic_vector(3 downto 0);
            led  : out std_ulogic_vector(6 downto 0)
            );
    end component char_decoder;
    type character_array is array(natural range <>) of std_ulogic_vector(3 downto 0);
    signal char_array : character_array(3 downto 0);

    --! From type enum to 4 chars
    component ProductType2Chars is
        port (
            prod                       : in  ProductType;
            code0, code1, code2, code3 : out std_ulogic_vector(3 downto 0)
            );
    end component ProductType2Chars;

    --! Freq. divider
    component e21_fdivider is
        generic (
            MODULE : positive := 16
            );
        port (
            RESET  : in  std_ulogic;
            CLK    : in  std_ulogic;
            CE_IN  : in  std_ulogic;
            CE_OUT : out std_ulogic
            );
    end component e21_fdivider;
    -- Signals
    signal next_segment_pulse : std_ulogic := '0';

    --! Local custom MUX
    subtype segments_bus is std_ulogic_vector(6 downto 0);
    type segments_bus_vector is array (natural range <>) of segments_bus;

    signal segments_codes_vector : segments_bus_vector(g_USED_SEGMENTS - 1 downto 0);
    signal enabled_digit         : natural range 0 to g_USED_SEGMENTS - 1 := 1;

    signal int_RESET : std_ulogic := '1';
begin
    int_RESET <= not i_RESET_N;
    Inst00_binary_to_bcd : binary_to_bcd
        generic map(
            bits   => 8,
            digits => g_USED_SEGMENTS
            )
        port map(
            clk     => i_CLK,
            reset_n => i_RESET_N,
            ena     => Converter_start,
            binary  => i8_REMAINING_SECS,
            busy    => open,
            bcd     => BCD_Representation
            );

    Inst00_freq_div_segments : e21_fdivider
        generic map(
            MODULE => g_CLK_FREQ / g_REFRESH_RATE
            )
        port map(
            RESET  => int_RESET,
            CLK    => i_CLK,
            CE_IN  => '1',
            CE_OUT => next_segment_pulse
            );

    --! MUX or DIGIT SELECT algorithm
    -- Map segments lines to mux inputs
    process (i_CLK, i_RESET_N)
    begin
        if i_RESET_N = '0' then
            enabled_digit <= 0;
        elsif rising_edge(i_CLK) then
            if next_segment_pulse = '1' then
                enabled_digit <= enabled_digit + 1;
                if enabled_digit = g_USED_SEGMENTS then
                    enabled_digit <= 0;
                end if;
            end if;
        end if;
    end process;
    -- Which digit to activate
    process (i_CLK, enabled_digit)
    begin
        o8_DIGIT_DISABLE                <= (others => '1');
        o8_DIGIT_DISABLE(enabled_digit) <= '0';
    end process;
    -- Which segments to display
    o7_DIGIT_SEGMENTS <= segments_codes_vector(enabled_digit);

    --! Detect & Start conversion on input change
    process (i_CLK, i_RESET_N, i8_REMAINING_SECS)
    begin
        if i_RESET_N = '0' then
            Binary_input_reg <= (others => '0');
        elsif rising_edge(i_CLK) then
            Binary_input_reg <= i8_REMAINING_SECS;
        end if;
    end process;

    Converter_start <= '0' when Binary_input_reg = i8_REMAINING_SECS else
                       '1';

    codes2segments_decoders : for index in g_USED_SEGMENTS - 1 downto 0 generate
        if_gen_segments :
        if index < 3 generate
            Inst0i_bin2seg : bin2seg
                port map(
                    code => BCD_Representation(4 * index + 3 downto 4 * index),
                    led  => segments_codes_vector(index)
                    );
        elsif index = 3 generate
            segments_codes_vector(index) <= (others => '1');
        else
            generate
                Inst0i_char2seg : char_decoder
                    port map(
                        code => char_array(index - 4),
                        led  => segments_codes_vector(index)
                        );
            end generate if_gen_segments;
        end generate;

    -- Get product enum type
    Inst00_Prod2Chars : ProductType2Chars
        port map(
            prod  => i_PRODUCT_TYPE,
            code0 => char_array(0),
            code1 => char_array(1),
            code2 => char_array(2),
            code3 => char_array(3)
            );
end architecture rtl;
