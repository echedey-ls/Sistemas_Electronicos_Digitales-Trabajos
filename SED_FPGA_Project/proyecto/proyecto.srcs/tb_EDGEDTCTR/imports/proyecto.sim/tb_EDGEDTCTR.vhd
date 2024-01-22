library ieee;
use ieee.std_logic_1164.all;

entity EDGEDTCTR_tb is
end EDGEDTCTR_tb;

architecture tb of EDGEDTCTR_tb is

    component EDGEDTCTR is
        generic (
            REG_LENGTH : positive := 1
            );
        port (
            CLK     : in  std_ulogic;
            RST_N   : in  std_ulogic;
            SYNC_IN : in  std_ulogic;
            EDGE    : out std_ulogic);
    end component;

    signal CLK     : std_ulogic;
    signal RST_N   : std_ulogic;
    signal SYNC_IN : std_ulogic;
    signal EDGE    : std_ulogic;

    signal TbSYNC          : std_logic := '0';
    signal TbSimEnded      : std_logic := '0';
    constant c_CLK_FREQ    : positive  := 100_000_000;
    constant c_CLK_PERIOD  : time      := 1 sec / c_CLK_FREQ;   -- 10 ns
    constant c_UART_FREQ   : positive  := 10_000_000;
    constant c_UART_PERIOD : time      := 1 sec / c_UART_FREQ;  -- 100 ns

begin

    dut : EDGEDTCTR
        port map(
            CLK     => CLK,
            RST_N   => RST_N,
            SYNC_IN => SYNC_IN,
            EDGE    => EDGE);

    -- Clock generation
    CLK <= not CLK after c_CLK_PERIOD/2;

    -- SYNC stimuli
    TbSYNC <= not TbSYNC after c_CLK_PERIOD * 4 + c_CLK_PERIOD * 7 / 13;  -- async input

    SYNC_IN <= TbSYNC;

    stimuli : process
    begin

        -- Reset generation
        RST_N <= '0';
        wait for c_CLK_PERIOD * 10;
        RST_N <= '1';
        wait for c_CLK_PERIOD;
        assert EDGE = '0' report "[TEST]: Unexpected Edge 1";

        wait until TbSYNC = '1';
        assert EDGE = '0' report "[TEST]: Unexpected Edge 2";
        wait until CLK = '1';
        assert EDGE = '1' report "[TEST]: Edge OK";

        wait for c_CLK_PERIOD;
        assert EDGE = '0' report "[TEST]: Unexpected Edge 3";
        wait;
    end process;

end tb;
