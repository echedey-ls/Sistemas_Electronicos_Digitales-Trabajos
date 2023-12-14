-- fluart: the featureless UART
-- Very simple UART, inspired by https://github.com/freecores/rs232_interface
-- Copyright 2019, 2020 Marc Joosen

-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fluart IS
    GENERIC (
        CLK_FREQ : INTEGER := 50_000_000; -- main frequency (Hz)
        SER_FREQ : INTEGER := 115200; -- bit rate (bps), any number up to CLK_FREQ / 2
        BRK_LEN : INTEGER := 10 -- break duration (tx), minimum break duration (rx) in bits
    );
    PORT (
        clk : IN STD_LOGIC;
        reset : IN STD_LOGIC;

        rxd : IN STD_LOGIC;
        txd : OUT STD_LOGIC;

        tx_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
        tx_req : IN STD_LOGIC;
        tx_brk : IN STD_LOGIC;
        tx_busy : OUT STD_LOGIC;
        tx_end : OUT STD_LOGIC;
        rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        rx_data_valid : OUT STD_LOGIC;
        rx_brk : OUT STD_LOGIC;
        rx_err : OUT STD_LOGIC
    );

BEGIN
    ASSERT BRK_LEN >= 10 REPORT "BRK_LEN must be >= 10" SEVERITY failure;
END;
ARCHITECTURE rtl OF fluart IS

    TYPE state IS (idle, start, data, stop1, stop2, break);

    CONSTANT CLK_DIV_MAX : NATURAL := CLK_FREQ / SER_FREQ - 1;

    SIGNAL tx_state : state;
    SIGNAL tx_clk_div : INTEGER RANGE 0 TO CLK_DIV_MAX;
    SIGNAL tx_data_tmp : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL tx_bit_cnt : INTEGER RANGE 0 TO BRK_LEN;

    SIGNAL rx_state : state;
    SIGNAL rxd_d : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL rx_data_i : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL rx_clk_div : INTEGER RANGE 0 TO CLK_DIV_MAX;
    SIGNAL rx_bit_cnt : INTEGER RANGE 0 TO BRK_LEN;

BEGIN

    tx_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                tx_state <= idle;
                tx_clk_div <= 0;
                tx_busy <= '0';
                tx_end <= '0';
                txd <= '1';
                tx_data_tmp <= (OTHERS => '0');
                tx_bit_cnt <= 0;

            ELSIF tx_state /= idle AND tx_clk_div /= CLK_DIV_MAX THEN
                tx_clk_div <= tx_clk_div + 1;

                -- tx_end pulse coincides with last cycle of tx_busy
                IF (tx_state = stop2 OR (tx_state = break AND tx_bit_cnt = BRK_LEN - 1))
                    AND tx_clk_div = CLK_DIV_MAX - 1 THEN
                    tx_end <= '1';
                END IF;

            ELSE -- tx_state = idle (ready to transmit), or at the end of a bit period

                -- defaults
                tx_clk_div <= 0;
                tx_end <= '0';

                CASE tx_state IS
                    WHEN idle =>
                        IF tx_req = '1' THEN
                            -- send start bit
                            tx_busy <= '1';
                            txd <= '0';
                            tx_data_tmp <= tx_data;
                            tx_state <= data;
                            tx_bit_cnt <= 0;
                        ELSIF tx_brk = '1' THEN
                            tx_busy <= '1';
                            txd <= '0';
                            tx_state <= break;
                            tx_bit_cnt <= 0;
                        ELSE
                            txd <= '1';
                        END IF;

                    WHEN data =>
                        txd <= tx_data_tmp(0);

                        IF tx_bit_cnt = 7 THEN
                            tx_state <= stop1;
                        ELSE
                            tx_data_tmp <= '0' & tx_data_tmp(7 DOWNTO 1);
                            tx_bit_cnt <= tx_bit_cnt + 1;
                        END IF;

                    WHEN stop1 =>
                        txd <= '1';
                        tx_state <= stop2;

                    WHEN stop2 =>
                        txd <= '1';
                        tx_state <= idle;
                        tx_busy <= '0';

                    WHEN break =>
                        txd <= '0';

                        IF tx_bit_cnt = BRK_LEN - 1 THEN
                            tx_state <= idle;
                            txd <= '1';
                            tx_busy <= '0';
                        ELSE
                            tx_bit_cnt <= tx_bit_cnt + 1;
                        END IF;

                    WHEN OTHERS =>
                        tx_state <= idle;

                END CASE;
            END IF;
        END IF;
    END PROCESS;
    rx_proc : PROCESS (clk)
    BEGIN
        IF rising_edge(clk) THEN
            IF reset = '1' THEN
                rx_state <= idle;
                rxd_d <= (OTHERS => '1');
                rx_data_i <= (OTHERS => '0');
                rx_data_valid <= '0';
                rx_err <= '0';
                rx_brk <= '0';
                rx_clk_div <= 0;
                rx_bit_cnt <= 0;

            ELSE
                -- double-latching
                rxd_d <= rxd_d(2 DOWNTO 0) & rxd;

                -- defaults
                rx_data_valid <= '0';
                rx_err <= '0';
                rx_brk <= '0';

                CASE rx_state IS
                    WHEN idle =>
                        IF rxd_d(3) = '1' AND rxd_d(2) = '0' THEN
                            rx_state <= start;
                            rx_clk_div <= 0;
                        END IF;

                    WHEN start =>
                        -- wait half a bit period
                        IF rx_clk_div = CLK_DIV_MAX / 2 THEN
                            -- rxd still low?
                            IF rxd_d(2) = '0' THEN
                                rx_state <= data;
                                rx_clk_div <= 0;
                                rx_bit_cnt <= 0;
                                rx_data_i <= (OTHERS => '0');
                            ELSE
                                -- this was a glitch
                                rx_state <= idle;
                                rx_clk_div <= 0;
                            END IF;
                        ELSE
                            rx_clk_div <= rx_clk_div + 1;
                        END IF;

                    WHEN data =>
                        -- wait a full bit period
                        IF rx_clk_div = CLK_DIV_MAX THEN
                            rx_clk_div <= 0;
                            rx_bit_cnt <= rx_bit_cnt + 1;
                            rx_data_i <= rxd_d(2) & rx_data_i(7 DOWNTO 1);

                            IF rx_bit_cnt = 7 THEN
                                rx_state <= stop1;
                            END IF;
                        ELSE
                            rx_clk_div <= rx_clk_div + 1;
                        END IF;

                    WHEN stop1 =>
                        -- wait a full bit period
                        IF rx_clk_div = CLK_DIV_MAX THEN
                            rx_clk_div <= 0;
                            rx_bit_cnt <= rx_bit_cnt + 1;

                            IF rxd_d(2) = '1' THEN
                                -- valid word received
                                rx_state <= idle;
                                rx_data_valid <= '1';

                            ELSIF rx_data_i /= x"00" THEN
                                -- non-zero bits received but no stop bit -> framing error
                                rx_state <= idle;
                                rx_err <= '1';

                            ELSE
                                -- all zeros received, start of break?
                                rx_state <= break;

                            END IF;
                        ELSE
                            rx_clk_div <= rx_clk_div + 1;
                        END IF;

                    WHEN break =>
                        IF rx_bit_cnt = BRK_LEN - 1 THEN
                            -- proper break received
                            rx_state <= idle;
                            rx_brk <= '1';

                        ELSIF rxd_d(2) = '1' THEN
                            -- now we start checking every sample
                            rx_state <= idle;
                            rx_err <= '1';

                        ELSIF rx_clk_div = CLK_DIV_MAX THEN
                            rx_clk_div <= 0;
                            rx_bit_cnt <= rx_bit_cnt + 1;

                        ELSE
                            rx_clk_div <= rx_clk_div + 1;
                        END IF;

                    WHEN OTHERS =>
                        rx_state <= idle;

                END CASE;
            END IF;
        END IF;
    END PROCESS;

    rx_data <= rx_data_i;

END;
