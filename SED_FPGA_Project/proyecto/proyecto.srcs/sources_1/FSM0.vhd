LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;

-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- TODO:
-- * LCDs

-- Type declaration of enum with machine statuses and conversion to 8 bits
USE WORK.MACHINE_COMMON.ALL;

ENTITY FSM0 IS
    GENERIC (
        g_CLK_FREQ : POSITIVE := 100_000_000;
        g_UART_FREQ : POSITIVE := 10_000
    );
    PORT (
        i_CLK : IN STD_LOGIC;
        i_RESET_N : IN STD_LOGIC;
        i_SERIAL_IN : IN STD_LOGIC;
        o_RX_BRK_LED : OUT STD_LOGIC;
        o_HEATER : OUT STD_LOGIC;
        o8_REMAINING_SECS : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
        o8_UART_DBG : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
    );
END FSM0;

ARCHITECTURE arch_fsm OF FSM0 IS
    --! STATUS
    TYPE FSM_STATUS_T IS (
        ENTRY_POINT,
        ISSUE_AVAILABLE_MSG,
        RX_WAIT_LOOP,
        TIMER_TRIGGER,
        COUNTDOWN,
        FINISHED
    );
    -- Signals
    SIGNAL CURRENT_STATE : FSM_STATUS_T := ENTRY_POINT;
    SIGNAL NEXT_STATE : FSM_STATUS_T := ENTRY_POINT;

    --! UART
    COMPONENT fluart IS -- Credits to https://github.com/marcj71/fluart
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

            tx_data : IN STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
            tx_req : IN STD_LOGIC;
            tx_brk : IN STD_LOGIC;
            tx_busy : OUT STD_LOGIC;
            tx_end : OUT STD_LOGIC;
            rx_data : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
            rx_data_valid : OUT STD_LOGIC;
            rx_brk : OUT STD_LOGIC;
            rx_err : OUT STD_LOGIC
        );
    END COMPONENT fluart;
    -- Signals
    SIGNAL Recv_flag : STD_LOGIC := '0';
    SIGNAL Recv_data : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL Recv_brk : STD_LOGIC := '0';
    SIGNAL Send_flag : STD_LOGIC := '0';
    SIGNAL Send_status : MachineStatus := FAULT;

    --! COUNTDOWN TIMER
    COMPONENT e20_updown_cntr IS
        GENERIC (
            WIDTH : POSITIVE := 4
        );
        PORT (
            CLR_N : IN STD_LOGIC;
            CLK : IN STD_LOGIC;
            UP : IN STD_LOGIC;
            CE_N : IN STD_LOGIC;
            LOAD_N : IN STD_LOGIC;
            J : IN STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0);
            ZERO_N : OUT STD_LOGIC;
            Q : OUT STD_LOGIC_VECTOR (WIDTH - 1 DOWNTO 0)
        );
    END COMPONENT e20_updown_cntr;
    -- Signals
    SIGNAL Timer_not_zero : STD_LOGIC := '0';
    SIGNAL Timer_enable : STD_LOGIC := '0';
    SIGNAL Timer_load : STD_LOGIC := '0';
    SIGNAL Timer_remaining : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');

    --! FREQUENCY DIVIDER - IMPULSE GENERATOR
    -- To run the countdown timer at 1Hz
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
    SIGNAL Divider_enable : STD_LOGIC := '0';
BEGIN ----------------------------------------
    --! UART instantiation
    Inst00_uart : fluart
    GENERIC MAP(
        CLK_FREQ => g_CLK_FREQ,
        SER_FREQ => g_UART_FREQ
    )
    PORT MAP(
        clk => i_CLK,
        reset => i_RESET_N,

        rxd => i_SERIAL_IN,
        txd => OPEN,

        tx_data => MachineStatus2Byte(Send_status),
        tx_req => Send_flag,
        tx_brk => '0',
        tx_busy => OPEN,
        tx_end => OPEN,

        rx_data => Recv_data,
        rx_data_valid => Recv_flag,
        rx_brk => Recv_brk,
        rx_err => OPEN
    );
    o_RX_BRK_LED <= Recv_brk;
    o8_UART_DBG <= Recv_data WHEN Recv_flag = '1';

    --! Countdown timer instantiation
    Inst00_CountDown : e20_updown_cntr
    GENERIC MAP(
        WIDTH => 8
    )
    PORT MAP(
        CLR_N => i_RESET_N,
        CLK => i_CLK,
        UP => '0',
        CE_N => NOT Timer_enable,
        LOAD_N => NOT Timer_load,
        J => Recv_data, -- Input
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
        CE_IN => Divider_enable,
        CE_OUT => Timer_enable
    );

    --! State Machine
    state_register : PROCESS (i_RESET_N, i_CLK)
    BEGIN
        IF i_RESET_N = '1' THEN
            CURRENT_STATE <= ENTRY_POINT;
        ELSIF rising_edge(i_CLK) THEN
            CURRENT_STATE <= NEXT_STATE;
        END IF;
    END PROCESS;

    nextstate_decod : PROCESS (i_CLK, CURRENT_STATE)
    BEGIN
        NEXT_STATE <= CURRENT_STATE;
        CASE CURRENT_STATE IS
            WHEN ENTRY_POINT =>
                NEXT_STATE <= ISSUE_AVAILABLE_MSG;
            WHEN ISSUE_AVAILABLE_MSG =>
                NEXT_STATE <= RX_WAIT_LOOP;
            WHEN RX_WAIT_LOOP =>
                IF Recv_flag = '1' THEN
                    NEXT_STATE <= TIMER_TRIGGER;
                END IF;
            WHEN TIMER_TRIGGER =>
                NEXT_STATE <= COUNTDOWN;
            WHEN COUNTDOWN =>
                IF Timer_not_zero = '1' THEN
                    NEXT_STATE <= FINISHED;
                END IF;
            WHEN FINISHED =>
                NEXT_STATE <= ISSUE_AVAILABLE_MSG;
            WHEN OTHERS =>
                NEXT_STATE <= ENTRY_POINT;
        END CASE;
    END PROCESS nextstate_decod;

    action_decod : PROCESS (i_CLK, CURRENT_STATE)
    BEGIN
        --! Default action values
        o_HEATER <= '0';
        Send_flag <= '0';
        Timer_load <= '0';
        Divider_enable <= '0';
        CASE CURRENT_STATE IS
            WHEN ENTRY_POINT =>
                --! In case some initialization is required, or data send on power-up
                NULL;
            WHEN ISSUE_AVAILABLE_MSG => -- 1 cycle duration
                --! For this cycle, a send_flag and a send_status will be raised
                Send_flag <= '1';
                Send_status <= AVAILABLE;
            WHEN RX_WAIT_LOOP =>
                --! Waits for Recv_flag = '1'
                NULL;
            WHEN TIMER_TRIGGER => -- 1 cycle duration
                --! Load timer seconds and start countdown
                Timer_load <= '1';
            WHEN COUNTDOWN =>
                --! Exits when timer gets to zero
                o_HEATER <= '1';
                Divider_enable <= '1';
                -- Send BUSY if status requested
                IF Recv_flag = '1' THEN -- Recv_flag lasts 1 cycle
                    -- Current code will send BUSY independently of what is received
                    -- TODO: implement cancel option here
                    Send_flag <= '1';
                    Send_status <= BUSY;
                END IF;
            WHEN FINISHED => -- 1 cycle duration
                Send_flag <= '1';
                Send_status <= FINISHED;
            WHEN OTHERS =>
                NULL;
        END CASE;
    END PROCESS action_decod;

END arch_fsm;
