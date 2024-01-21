library ieee;
use ieee.std_logic_1164.all;

entity tb_EDGEDTCTR is
end tb_EDGEDTCTR;

architecture tb of tb_EDGEDTCTR is

    component EDGEDTCTR
        port (CLK     : in std_ulogic;
              RST_N   : in std_ulogic;
              SYNC_IN : in std_ulogic;
              EDGE    : out std_ulogic);
    end component;

    signal CLK     : std_ulogic;
    signal RST_N   : std_ulogic;
    signal SYNC_IN : std_ulogic;
    signal EDGE    : std_ulogic;

    constant TbPeriod : time := 1000 ns;
    signal TbClock : std_logic := '0';
    signal TbSYNC : std_logic := '0';
    signal TbSimEnded : std_logic := '0';

begin

    dut : EDGEDTCTR
    port map (CLK     => CLK,
              RST_N   => RST_N,
              SYNC_IN => SYNC_IN,
              EDGE    => EDGE);

    -- Clock generation
    TbClock <= not TbClock after TbPeriod/2 when TbSimEnded /= '1' else '0';
	
	-- SYNC stimuli
	TbSYNC <= not TbSYNC after TbPeriod*4 when TbSimEnded /= '1' else '0';

    CLK <= TbClock;
    SYNC_IN <= TbSYNC;

    stimuli : process
    begin

        -- Reset generation
        RST_N <= '0';
        wait for TbPeriod*10;
        RST_N <= '1';
        wait for TbPeriod;

        wait for 100 * TbPeriod;

        -- Stop the clock and hence terminate the simulation
        TbSimEnded <= '1';
        wait;
    end process;

end tb;

