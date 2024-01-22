library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Type declaration of enum with machine statuses and conversion to 8 bits
use WORK.MACHINE_COMMON.all;

entity FSM0 is
    generic (
        g_CLK_FREQ : positive := 100_000_000
        );
    port (
        i_CLK     : in std_ulogic;
        i_RESET_N : in std_ulogic;

        i_CANCEL_BTN      : in  std_ulogic;
        o_HEATER          : out std_ulogic;
        -- UART TELECOMS IO
        i_cmd_received    : in  std_ulogic;
        i_cmd_cancel      : in  std_ulogic;
        i_cmd_product     : in  std_ulogic;
        i_product_type    : in  ProductType;
        i8_converted_secs : in  BYTE;

        o_status          : inout MachineStatus;
        o_status_send     : out   std_ulogic;
        -- DISPLAY OUTPUT
        o8_REMAINING_SECS : out   std_ulogic_vector(7 downto 0);
        o_PRODUCT_STR     : out   ProductType
        );
end FSM0;

architecture arch_fsm of FSM0 is
    --! STATUS
    type FSM_STATUS_T is (
        ENTRY_POINT,
        PRELAUNCH,
        COUNT_DOWN,
        ORDER_CANCELLED,
        ORDER_FINISHED
        );

    -- Transition signals
    -- Composed later on
    signal int_timer_finished : std_ulogic := '0';  -- Timer_not_zero = '0'
    signal int_RX_CMD_Cancel  : std_ulogic := '0';  -- i_cmd_received & i_cmd_cancel
    signal int_RX_CMD_Product : std_ulogic := '0';  -- i_cmd_received & i_cmd_product
    signal int_any_CMD_Cancel : std_ulogic := '0';  -- takes into account cancel button (or gate)

    --! COUNTDOWN TIMER
    component e20_updown_cntr is
        generic (
            WIDTH : positive := 4
            );
        port (
            CLR_N  : in  std_ulogic;
            CLK    : in  std_ulogic;
            UP     : in  std_ulogic;
            CE_N   : in  std_ulogic;
            LOAD_N : in  std_ulogic;
            J      : in  std_ulogic_vector (WIDTH - 1 downto 0);
            ZERO_N : out std_ulogic;
            Q      : out std_ulogic_vector (WIDTH - 1 downto 0)
            );
    end component e20_updown_cntr;
    -- Signals
    signal int_timer_not_zero  : std_ulogic                    := '0';
    signal int_timer_enable    : std_ulogic                    := '0';
    signal int_timer_clear     : std_ulogic                    := '0';
    signal int_timer_load      : std_ulogic                    := '0';
    signal int_timer_remaining : std_ulogic_vector(7 downto 0) := (others => '0');

    --! FREQUENCY DIVIDER - IMPULSE GENERATOR
    -- To run the countdown timer at 1Hz
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
    signal Do_countdown : std_ulogic := '0';
    -- SIGNAL Last_prod_cancelled : STD_ULOGIC := '0';

    --! Buttons Edge Detector
    component EDGEDTCTR is
        generic (
            REG_LENGTH : positive := 1
            );
        port (
            CLK, RST_N : in  std_ulogic;
            SYNC_IN    : in  std_ulogic;
            EDGE       : out std_ulogic
            );
    end component EDGEDTCTR;
    -- Signals
    signal CANCEL_BTN_EDGE : std_ulogic := '0';

    -- Intermediate signal to suppress warnings
    signal int_RESET           : std_ulogic := '1';
    signal int_CountDown_RST_N : std_ulogic := '1';
    signal int_timer_enable_N  : std_ulogic := '1';
    signal int_timer_load_N    : std_ulogic := '1';
begin  ----------------------------------------
    int_RESET           <= not i_RESET_N;
    --! Countdown timer instantiation
    int_CountDown_RST_N <= i_RESET_N and not int_timer_clear;
    int_timer_enable_N  <= not int_timer_enable;
    int_timer_load_N    <= not int_timer_load;
    Inst00_CountDown : e20_updown_cntr
        generic map(
            WIDTH => 8
            )
        port map(
            CLR_N  => int_CountDown_RST_N,
            CLK    => i_CLK,
            UP     => '0',
            CE_N   => int_timer_enable_N,
            LOAD_N => int_timer_load_N,
            J      => i8_converted_secs,
            ZERO_N => int_timer_not_zero,
            Q      => int_timer_remaining  -- Output
            );
    o8_REMAINING_SECS <= int_timer_remaining;

    --! Freq. generator / impulses instantiation
    Inst00_divider : e21_fdivider
        generic map(
            MODULE => g_CLK_FREQ
            )
        port map(
            RESET  => int_RESET,
            CLK    => i_CLK,
            CE_IN  => Do_countdown,
            CE_OUT => int_timer_enable
            );

    --! Cancel Input
    Inst00_CANCEL_BTN_EDGE : EDGEDTCTR
        port map(
            CLK     => i_CLK,
            RST_N   => i_RESET_N,
            SYNC_IN => i_CANCEL_BTN,
            EDGE    => CANCEL_BTN_EDGE
            );

    --! State Machine !--
    ---------------------
    -- Transition signals
    int_timer_finished <= not int_timer_not_zero;
    int_RX_CMD_Cancel  <= i_cmd_received and i_cmd_cancel;
    int_RX_CMD_Product <= i_cmd_received and i_cmd_product;
    int_any_CMD_Cancel <= int_RX_CMD_Cancel or CANCEL_BTN_EDGE;  -- UART Cancel Command OR Cancel Button

    -- Transition & actions process
    fsm_main_proc : process (i_RESET_N, i_CLK)
        variable CURRENT_STATE    : FSM_STATUS_T := ENTRY_POINT;
        variable NEXT_STATE       : FSM_STATUS_T := ENTRY_POINT;
        variable int_PRODUCT_TYPE : ProductType  := DASHES;
    begin
        if i_RESET_N = '0' then
            CURRENT_STATE := ENTRY_POINT;
            NEXT_STATE    := ENTRY_POINT;

            --! Reset internal and external output variables
            o_HEATER         <= '0';
            int_timer_load   <= '0';
            int_timer_clear  <= '0';
            Do_countdown     <= '0';
            o_status_send    <= '0';
            int_PRODUCT_TYPE := DASHES;
        elsif rising_edge(i_CLK) then
            --! Transition & and save current state for the next cycle
            CURRENT_STATE := NEXT_STATE;
            NEXT_STATE    := CURRENT_STATE;

            --! Transition table
            -- See FSM diagram
            case CURRENT_STATE is
                when ENTRY_POINT =>
                    if int_RX_CMD_Product = '1' then
                        NEXT_STATE := PRELAUNCH;
                    end if;
                when PRELAUNCH =>
                    -- In addition to action code, this allows ALWAYS generating a positive pulse on o_status_send
                    if o_status = STARTED_PROD then
                        NEXT_STATE := COUNT_DOWN;
                    end if;
                when COUNT_DOWN =>
                    if int_timer_finished = '1' then
                        NEXT_STATE := ORDER_FINISHED;
                    elsif int_any_CMD_Cancel = '1' then
                        NEXT_STATE := ORDER_CANCELLED;
                    end if;
                when ORDER_CANCELLED =>
                    if int_RX_CMD_Product = '1' then
                        NEXT_STATE := PRELAUNCH;
                    end if;
                when ORDER_FINISHED =>
                    if int_RX_CMD_Product = '1' then
                        NEXT_STATE := PRELAUNCH;
                    end if;
                when others =>
                    NEXT_STATE := ENTRY_POINT;
            end case;

            --! Action switch case
            -- Default action values
            o_HEATER         <= '0';
            int_timer_load   <= '0';
            int_timer_clear  <= '0';
            Do_countdown     <= '0';
            o_status_send    <= '0';
            int_PRODUCT_TYPE := int_PRODUCT_TYPE;
            case CURRENT_STATE is
                when ENTRY_POINT =>
                    -- Show empty status on 7-Segments
                    int_PRODUCT_TYPE := DASHES;
                    -- Send AVAILABLE code on power-up / reset
                    o_status         <= AVAILABLE;
                    o_status_send    <= '1';
                when PRELAUNCH =>
                    -- Show status on 7-Segments
                    int_PRODUCT_TYPE := i_product_type;
                    -- In addition to transition code, this allows ALWAYS generating a positive pulse on o_status_send
                    if o_status = STARTED_PROD then
                        o_status_send <= '1';
                    end if;
                    int_timer_load <= '1';
                    -- Send STARTED_PROD code on start
                    o_status       <= STARTED_PROD;
                when COUNT_DOWN =>
                    -- Heat product, other logic could be implemented here
                    o_HEATER     <= '1';
                    -- in this case, simulation via a 1-Hz counter
                    Do_countdown <= '1';
                    -- Send BUSY code if another product is requested
                    if int_RX_CMD_Product = '1' and int_RX_CMD_Cancel = '0' then
                        o_status_send <= '1';
                        o_status      <= BUSY;
                    end if;
                when ORDER_CANCELLED =>
                    int_timer_clear  <= '1';
                    -- Show status on 7-Segments
                    int_PRODUCT_TYPE := CANCEL;
                    -- Send current product was cancelled by any means (from FPGA or UART RX command)
                    o_status_send    <= '1';
                    o_status         <= CANCELLED;
                when ORDER_FINISHED =>
                    -- Send FINISHED code
                    o_status_send <= '1';
                    o_status      <= FINISHED;
                when others =>
                    null;
            end case;

        end if;
        --! Output assignments
        o_PRODUCT_STR <= int_PRODUCT_TYPE;
    end process fsm_main_proc;
    --! END OF STATE MACHINE !--
    ----------------------------

end architecture arch_fsm;
