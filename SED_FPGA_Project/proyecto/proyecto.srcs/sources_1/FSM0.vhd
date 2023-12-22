LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- arithmetic functions with Signed or Unsigned values
USE IEEE.NUMERIC_STD.ALL;

-- Type declaration of enum with machine statuses and conversion to 8 bits
USE WORK.MACHINE_COMMON.ALL;

ENTITY FSM0 IS
    GENERIC (
        g_CLK_FREQ : POSITIVE := 100_000_000;
        g_UART_FREQ : POSITIVE := 10_000
    );
    PORT (
        i_CLK : IN STD_ULOGIC;
        i_RESET_N : IN STD_ULOGIC;
        i_CANCEL_BTN : IN STD_ULOGIC;
        i_SERIAL_IN : IN STD_ULOGIC;
        o_SERIAL_OUT : OUT STD_ULOGIC;
        o_RX_BRK_LED : OUT STD_ULOGIC;
        o_HEATER : OUT STD_ULOGIC;
        o8_REMAINING_SECS : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
        o_PRODUCT_STR : OUT ProductType;
        oo_UART_DBG : OUT STD_ULOGIC_VECTOR
    );
END FSM0;

ARCHITECTURE arch_fsm OF FSM0 IS
    --! STATUS
    TYPE FSM_STATUS_T IS (
        ENTRY_POINT,
        WAIT_FOR_CMD,
        COUNT_DOWN,
        ORDER_CANCELLED,
        ORDER_FINISHED
    );
    -- Signals
    SIGNAL CURRENT_STATE : FSM_STATUS_T := ENTRY_POINT;
    SIGNAL NEXT_STATE : FSM_STATUS_T := ENTRY_POINT;

    -- Transition signals
    -- Composed later on
    SIGNAL Timer_has_finished : STD_ULOGIC := '0'; -- Timer_not_zero = '0'
    SIGNAL CMD_Cancel : STD_ULOGIC := '0';
    SIGNAL Recv_CMD_Cancel : STD_ULOGIC := '0'; -- Recv_flag & CMD_Cancel
    SIGNAL Recv_CMD_Product_Request : STD_ULOGIC := '0'; -- Recv_flag & !CMD_Cancel
    SIGNAL Any_CMD_Cancel : STD_ULOGIC := '0'; -- takes into account cancel button (or gate)

    --! UART
    COMPONENT fluart IS -- Credits to https://github.com/marcj71/fluart
        GENERIC (
            CLK_FREQ : INTEGER := 50_000_000; -- main frequency (Hz)
            SER_FREQ : INTEGER := 115200; -- bit rate (bps), any number up to CLK_FREQ / 2
            BRK_LEN : INTEGER := 10 -- break duration (tx), minimum break duration (rx) in bits
        );
        PORT (
            clk : IN STD_ULOGIC;
            reset : IN STD_ULOGIC;

            rxd : IN STD_ULOGIC;
            txd : OUT STD_ULOGIC;

            tx_data : IN STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
            tx_req : IN STD_ULOGIC;
            tx_brk : IN STD_ULOGIC;
            tx_busy : OUT STD_ULOGIC;
            tx_end : OUT STD_ULOGIC;
            rx_data : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
            rx_data_valid : OUT STD_ULOGIC;
            rx_brk : OUT STD_ULOGIC;
            rx_err : OUT STD_ULOGIC
        );
    END COMPONENT fluart;
    -- Signals
    SIGNAL Recv_flag : STD_ULOGIC := '0';
    SIGNAL Recv_data : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Recv_brk : STD_ULOGIC := '0';
    SIGNAL Send_flag : STD_ULOGIC := '0';
    SIGNAL Send_status_enum : MachineStatus := FAULT;
    SIGNAL Send_status_byte : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    --! INPUT COMMANDS TRANSLATOR
    COMPONENT UART_RX_COMMAND_TRANSLATION IS
        PORT (
            i8_rx_code : IN BYTE;
            o_IS_CANCEL_CMD : INOUT STD_ULOGIC;
            o_product_type : OUT ProductType;
            o8_converted_secs : OUT BYTE
        );
    END COMPONENT UART_RX_COMMAND_TRANSLATION;
    -- Signals
    SIGNAL CMD_RX_seconds : BYTE := (OTHERS => '0');
    SIGNAL CMD_RX_prod_type : ProductType := NONE;

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
    SIGNAL Timer_not_zero : STD_ULOGIC := '0';
    SIGNAL Timer_enable : STD_ULOGIC := '0';
    SIGNAL Timer_clear : STD_ULOGIC := '0';
    SIGNAL Timer_load : STD_ULOGIC := '0';
    SIGNAL Timer_remaining : STD_ULOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

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
        PORT (
            CLK, RST_N : IN STD_ULOGIC;
            SYNC_IN : IN STD_ULOGIC;
            EDGE : OUT STD_ULOGIC
        );
    END COMPONENT EDGEDTCTR;
    -- Signals
    SIGNAL CANCEL_BTN_EDGE : STD_ULOGIC := '0';
BEGIN ----------------------------------------
    --! Check inputs
    ASSERT oo_UART_DBG'LENGTH >= 10;
    --! UART instantiation
    Inst00_uart : fluart
    GENERIC MAP(
        CLK_FREQ => g_CLK_FREQ,
        SER_FREQ => g_UART_FREQ
    )
    PORT MAP(
        clk => i_CLK,
        reset => NOT i_RESET_N,

        rxd => i_SERIAL_IN,
        txd => o_SERIAL_OUT,

        tx_data => Send_status_byte,
        tx_req => Send_flag,
        tx_brk => '0',
        tx_busy => OPEN,
        tx_end => OPEN,

        rx_data => Recv_data,
        rx_data_valid => Recv_flag,
        rx_brk => Recv_brk,
        rx_err => OPEN
    );
    Send_status_byte <= MachineStatus2Byte(Send_status_enum);
    o_RX_BRK_LED <= Recv_brk;

    --! Split UART RX data into Product Time & Product Type
    Inst00_CMD_RX_CONVERTER : UART_RX_COMMAND_TRANSLATION
    PORT MAP(
        i8_rx_code => Recv_data,
        o_IS_CANCEL_CMD => CMD_Cancel,
        o_product_type => CMD_RX_prod_type,
        o8_converted_secs => CMD_RX_seconds
    );

    --! Countdown timer instantiation
    Inst00_CountDown : e20_updown_cntr
    GENERIC MAP(
        WIDTH => 8
    )
    PORT MAP(
        CLR_N => i_RESET_N AND NOT Timer_clear,
        CLK => i_CLK,
        UP => '0',
        CE_N => NOT Timer_enable,
        LOAD_N => NOT Timer_load,
        J => CMD_RX_seconds,
        ZERO_N => Timer_not_zero,
        Q => Timer_remaining -- Output
    );
    o8_REMAINING_SECS <= Timer_remaining;

    --! Freq. generator / impulses instantiation
    Inst00_divider : e21_fdivider
    GENERIC MAP(
        MODULE => g_CLK_FREQ
    )
    PORT MAP(
        RESET => NOT i_RESET_N,
        CLK => i_CLK,
        CE_IN => Do_countdown,
        CE_OUT => Timer_enable
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
    Timer_has_finished <= NOT Timer_not_zero;
    Recv_CMD_Cancel <= Recv_flag AND CMD_Cancel;
    Recv_CMD_Product_Request <= Recv_flag AND NOT CMD_Cancel;
    Any_CMD_Cancel <= Recv_CMD_Cancel OR CANCEL_BTN_EDGE; -- UART Cancel Command OR Cancel Button

    oo_UART_DBG(13 DOWNTO 10) <= Timer_has_finished & Recv_CMD_Cancel & Recv_CMD_Product_Request & Any_CMD_Cancel;

    -- Transition process
    state_register : PROCESS (i_RESET_N, i_CLK)
    BEGIN
        IF i_RESET_N = '0' THEN
            CURRENT_STATE <= ENTRY_POINT;
        ELSIF rising_edge(i_CLK) THEN
            CURRENT_STATE <= NEXT_STATE;
        END IF;
    END PROCESS;

    nextstate_decod : PROCESS (i_CLK, CURRENT_STATE)
    BEGIN
        NEXT_STATE <= CURRENT_STATE;
        oo_UART_DBG(9 DOWNTO 5) <= (OTHERS => '0');
        CASE CURRENT_STATE IS
            WHEN ENTRY_POINT =>
                oo_UART_DBG(5) <= '1';
                NEXT_STATE <= WAIT_FOR_CMD;
            WHEN WAIT_FOR_CMD =>
                oo_UART_DBG(6) <= '1';
                IF Recv_CMD_Product_Request = '1' THEN
                    NEXT_STATE <= COUNT_DOWN;
                END IF;
            WHEN COUNT_DOWN =>
                oo_UART_DBG(7) <= '1';
                IF Timer_has_finished = '1' THEN
                    NEXT_STATE <= ORDER_FINISHED;
                -- ELSIF Any_CMD_Cancel = '1' THEN
                --     NEXT_STATE <= ORDER_CANCELLED;
                END IF;
            WHEN ORDER_CANCELLED =>
                oo_UART_DBG(8) <= '1';
                NEXT_STATE <= ENTRY_POINT;
            WHEN ORDER_FINISHED =>
                oo_UART_DBG(9) <= '1';
                NEXT_STATE <= ENTRY_POINT;
            WHEN OTHERS =>
                NEXT_STATE <= ENTRY_POINT;
        END CASE;
    END PROCESS nextstate_decod;

    action_decod : PROCESS (i_CLK, CURRENT_STATE)
        VARIABLE display_txt : ProductType := DASHES;
    BEGIN
        --! Default action values
        o_HEATER <= '0';
        Send_flag <= '0';
        Timer_load <= '0';
        Timer_clear <= '0';
        Do_countdown <= '0';
        display_txt := display_txt; -- Text to display latch
        oo_UART_DBG(4 DOWNTO 0) <= (OTHERS => '0');
        CASE CURRENT_STATE IS
            WHEN ENTRY_POINT =>
                oo_UART_DBG(0) <= '1';
                --! In case some initialization is required, or data send on power-up
                -- Reset timer
                -- Last_prod_cancelled <= '0';
                Do_countdown <= '0';
                Timer_clear <= '1';
                display_txt := DASHES;
            WHEN WAIT_FOR_CMD =>
                oo_UART_DBG(1) <= '1';
                Send_flag <= '1';
                Send_status_enum <= AVAILABLE;
                IF Recv_CMD_Product_Request = '1' THEN
                    Timer_load <= '1';
                    display_txt := CMD_RX_prod_type;
                END IF;
            WHEN COUNT_DOWN =>
                oo_UART_DBG(2) <= '1';
                o_HEATER <= '1';
                Do_countdown <= '1';
                IF Recv_CMD_Product_Request THEN
                    Send_flag <= '1';
                    Send_status_enum <= BUSY;
                END IF;
            WHEN ORDER_CANCELLED =>
                oo_UART_DBG(3) <= '1';
                display_txt := CANCEL;
                Send_flag <= '1';
                Send_status_enum <= FAULT;
                Timer_clear <= '1';
            WHEN ORDER_FINISHED =>
                oo_UART_DBG(4) <= '1';
                display_txt := DASHES;
                Send_flag <= '1';
                Send_status_enum <= FINISHED;
            WHEN OTHERS =>
                Send_flag <= '1';
                Send_status_enum <= FAULT;
        END CASE;
        o_PRODUCT_STR <= display_txt;
    END PROCESS action_decod;
    --! END OF STATE MACHINE !--
    ----------------------------

END ARCHITECTURE arch_fsm;
