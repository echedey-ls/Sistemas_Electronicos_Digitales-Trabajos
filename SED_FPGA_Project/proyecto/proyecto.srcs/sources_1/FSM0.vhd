LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Type declaration of enum with machine statuses and conversion to 8 bits
USE WORK.MACHINE_COMMON.ALL;

ENTITY FSM0 IS
    GENERIC (
        g_CLK_FREQ : POSITIVE := 100_000_000
    );
    PORT (
        i_CLK : IN STD_ULOGIC;
        i_RESET_N : IN STD_ULOGIC;

        i_CANCEL_BTN : IN STD_ULOGIC;
        o_HEATER : OUT STD_ULOGIC;
        -- UART TELECOMS IO
        i_cmd_received : IN STD_ULOGIC;
        i_cmd_cancel : IN STD_ULOGIC;
        i_cmd_product : IN STD_ULOGIC;
        i_product_type : IN ProductType;
        i8_converted_secs : IN BYTE;

        o_status : INOUT MachineStatus;
        o_status_send : OUT STD_ULOGIC;
        -- DISPLAY OUTPUT
        o8_REMAINING_SECS : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
        o_PRODUCT_STR : OUT ProductType
    );
END FSM0;

ARCHITECTURE arch_fsm OF FSM0 IS
    --! STATUS
    TYPE FSM_STATUS_T IS (
        ENTRY_POINT,
        PRELAUNCH,
        COUNT_DOWN,
        ORDER_CANCELLED,
        ORDER_FINISHED
    );

    -- Transition signals
    -- Composed later on
    SIGNAL int_timer_finished : STD_ULOGIC := '0'; -- Timer_not_zero = '0'
    SIGNAL int_RX_CMD_Cancel : STD_ULOGIC := '0'; -- i_cmd_received & i_cmd_cancel
    SIGNAL int_RX_CMD_Product : STD_ULOGIC := '0'; -- i_cmd_received & i_cmd_product
    SIGNAL int_any_CMD_Cancel : STD_ULOGIC := '0'; -- takes into account cancel button (or gate)

    --! COUNTDOWN TIMER
    COMPONENT e20_updown_cntr IS
        GENERIC (
            WIDTH : POSITIVE := 4
        );
        PORT (
            CLR_N : IN STD_ULOGIC;
            CLK : IN STD_ULOGIC;
            UP : IN STD_ULOGIC;
            CE_N : IN STD_ULOGIC;
            LOAD_N : IN STD_ULOGIC;
            J : IN STD_ULOGIC_VECTOR (WIDTH - 1 DOWNTO 0);
            ZERO_N : OUT STD_ULOGIC;
            Q : OUT STD_ULOGIC_VECTOR (WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT e20_updown_cntr;
    -- Signals
    SIGNAL int_timer_not_zero : STD_ULOGIC := '0';
    SIGNAL int_timer_enable : STD_ULOGIC := '0';
    SIGNAL int_timer_clear : STD_ULOGIC := '0';
    SIGNAL int_timer_load : STD_ULOGIC := '0';
    SIGNAL int_timer_remaining : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    --! FREQUENCY DIVIDER - IMPULSE GENERATOR
    -- To run the countdown timer at 1Hz
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
    SIGNAL Do_countdown : STD_ULOGIC := '0';
    -- SIGNAL Last_prod_cancelled : STD_ULOGIC := '0';

    --! Buttons Edge Detector
    COMPONENT EDGEDTCTR IS
        GENERIC (
            REG_LENGTH : POSITIVE := 1
        );
        PORT (
            CLK, RST_N : IN STD_ULOGIC;
            SYNC_IN : IN STD_ULOGIC;
            EDGE : OUT STD_ULOGIC
        );
    END COMPONENT EDGEDTCTR;
    -- Signals
    SIGNAL CANCEL_BTN_EDGE : STD_ULOGIC := '0';

    -- Intermediate signal to suppress warnings
    SIGNAL int_RESET : STD_ULOGIC := '1';
    SIGNAL int_CountDown_RST_N : STD_ULOGIC := '1';
    SIGNAL int_timer_enable_N : STD_ULOGIC := '1';
    SIGNAL int_timer_load_N : STD_ULOGIC := '1';
BEGIN ----------------------------------------
    int_RESET <= NOT i_RESET_N;
    --! Countdown timer instantiation
    int_CountDown_RST_N <= i_RESET_N AND NOT int_timer_clear;
    int_timer_enable_N <= NOT int_timer_enable;
    int_timer_load_N <= NOT int_timer_load;
    Inst00_CountDown : e20_updown_cntr
    GENERIC MAP(
        WIDTH => 8
    )
    PORT MAP(
        CLR_N => int_CountDown_RST_N,
        CLK => i_CLK,
        UP => '0',
        CE_N => int_timer_enable_N,
        LOAD_N => int_timer_load_N,
        J => i8_converted_secs,
        ZERO_N => int_timer_not_zero,
        Q => int_timer_remaining -- Output
    );
    o8_REMAINING_SECS <= int_timer_remaining;

    --! Freq. generator / impulses instantiation
    Inst00_divider : e21_fdivider
    GENERIC MAP(
        MODULE => g_CLK_FREQ
    )
    PORT MAP(
        RESET => int_RESET,
        CLK => i_CLK,
        CE_IN => Do_countdown,
        CE_OUT => int_timer_enable
    );

    --! Cancel Input
    Inst00_CANCEL_BTN_EDGE : EDGEDTCTR
    PORT MAP(
        CLK => i_CLK,
        RST_N => i_RESET_N,
        SYNC_IN => i_CANCEL_BTN,
        EDGE => CANCEL_BTN_EDGE
    );

    --! State Machine !--
    ---------------------
    -- Transition signals
    int_timer_finished <= NOT int_timer_not_zero;
    int_RX_CMD_Cancel <= i_cmd_received AND i_cmd_cancel;
    int_RX_CMD_Product <= i_cmd_received AND i_cmd_product;
    int_any_CMD_Cancel <= int_RX_CMD_Cancel OR CANCEL_BTN_EDGE; -- UART Cancel Command OR Cancel Button

    -- Transition & actions process
    fsm_main_proc : PROCESS (i_RESET_N, i_CLK)
        VARIABLE CURRENT_STATE : FSM_STATUS_T := ENTRY_POINT;
        VARIABLE NEXT_STATE : FSM_STATUS_T := ENTRY_POINT;
        VARIABLE int_PRODUCT_TYPE : ProductType := DASHES;
    BEGIN
        IF i_RESET_N = '0' THEN
            CURRENT_STATE := ENTRY_POINT;
            NEXT_STATE := ENTRY_POINT;

            --! Reset internal and external output variables
            o_HEATER <= '0';
            int_timer_load <= '0';
            int_timer_clear <= '0';
            Do_countdown <= '0';
            o_status_send <= '0';
            int_PRODUCT_TYPE := DASHES;
        ELSIF rising_edge(i_CLK) THEN
            --! Transition & and save current state for the next cycle
            CURRENT_STATE := NEXT_STATE;
            NEXT_STATE := CURRENT_STATE;

            --! Transition table
            -- See FSM diagram
            CASE CURRENT_STATE IS
                WHEN ENTRY_POINT =>
                    IF int_RX_CMD_Product = '1' THEN
                        NEXT_STATE := PRELAUNCH;
                    END IF;
                WHEN PRELAUNCH =>
                    -- In addition to action code, this allows ALWAYS generating a positive pulse on o_status_send
                    IF o_status = STARTED_PROD THEN
                        NEXT_STATE := COUNT_DOWN;
                    END IF;
                WHEN COUNT_DOWN =>
                    IF int_timer_finished = '1' THEN
                        NEXT_STATE := ORDER_FINISHED;
                    ELSIF int_any_CMD_Cancel = '1' THEN
                        NEXT_STATE := ORDER_CANCELLED;
                    END IF;
                WHEN ORDER_CANCELLED =>
                    IF int_RX_CMD_Product = '1' THEN
                        NEXT_STATE := PRELAUNCH;
                    END IF;
                WHEN ORDER_FINISHED =>
                    IF int_RX_CMD_Product = '1' THEN
                        NEXT_STATE := PRELAUNCH;
                    END IF;
                WHEN OTHERS =>
                    NEXT_STATE := ENTRY_POINT;
            END CASE;

            --! Action switch case
            -- Default action values
            o_HEATER <= '0';
            int_timer_load <= '0';
            int_timer_clear <= '0';
            Do_countdown <= '0';
            o_status_send <= '0';
            int_PRODUCT_TYPE := int_PRODUCT_TYPE;
            CASE CURRENT_STATE IS
                WHEN ENTRY_POINT =>
                    -- Show empty status on 7-Segments
                    int_PRODUCT_TYPE := DASHES;
                    -- Send AVAILABLE code on power-up / reset
                    o_status <= AVAILABLE;
                    o_status_send <= '1';
                WHEN PRELAUNCH =>
                    -- Show status on 7-Segments
                    int_PRODUCT_TYPE := i_product_type;
                    -- In addition to transition code, this allows ALWAYS generating a positive pulse on o_status_send
                    IF o_status = STARTED_PROD THEN
                        o_status_send <= '1';
                    END IF;
                    int_timer_load <= '1';
                    -- Send STARTED_PROD code on start
                    o_status <= STARTED_PROD;
                WHEN COUNT_DOWN =>
                    -- Heat product, other logic could be implemented here
                    o_HEATER <= '1';
                    -- in this case, simulation via a 1-Hz counter
                    Do_countdown <= '1';
                    -- Send BUSY code if another product is requested
                    IF int_RX_CMD_Product = '1' and int_RX_CMD_Cancel = '0' THEN
                        o_status_send <= '1';
                        o_status <= BUSY;
                    END IF;
                WHEN ORDER_CANCELLED =>
                    int_timer_clear <= '1';
                    -- Show status on 7-Segments
                    int_PRODUCT_TYPE := CANCEL;
                    -- Send current product was cancelled by any means (from FPGA or UART RX command)
                    o_status_send <= '1';
                    o_status <= CANCELLED;
                WHEN ORDER_FINISHED =>
                    -- Send FINISHED code
                    o_status_send <= '1';
                    o_status <= FINISHED;
                WHEN OTHERS =>
                    NULL;
            END CASE;

        END IF;
        --! Output assignments
        o_PRODUCT_STR <= int_PRODUCT_TYPE;
    END PROCESS fsm_main_proc;
    --! END OF STATE MACHINE !--
    ----------------------------

END ARCHITECTURE arch_fsm;
