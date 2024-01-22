LIBRARY IEEE;
USE IEEE.Std_logic_1164.ALL;
USE IEEE.Numeric_Std.ALL;

USE WORK.MACHINE_COMMON.ALL;

ENTITY FSM0_tb IS
END;

ARCHITECTURE bench OF FSM0_tb IS

  COMPONENT FSM0
    GENERIC (
      g_CLK_FREQ : POSITIVE := 100_000_000
    );
    PORT (
      i_CLK : IN STD_ULOGIC;
      i_RESET_N : IN STD_ULOGIC;
      i_CANCEL_BTN : IN STD_ULOGIC;
      o_HEATER : OUT STD_ULOGIC;
      i_cmd_received : IN STD_ULOGIC;
      i_cmd_cancel : IN STD_ULOGIC;
      i_cmd_product : IN STD_ULOGIC;
      i_product_type : IN ProductType;
      i8_converted_secs : IN BYTE;
      o_status : INOUT MachineStatus;
      o_status_send : OUT STD_ULOGIC;
      o8_REMAINING_SECS : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
      o_PRODUCT_STR : OUT ProductType
    );
  END COMPONENT;

  SIGNAL i_CLK : STD_ULOGIC;
  SIGNAL i_RESET_N : STD_ULOGIC;
  SIGNAL i_CANCEL_BTN : STD_ULOGIC;
  SIGNAL o_HEATER : STD_ULOGIC;
  SIGNAL i_cmd_received : STD_ULOGIC;
  SIGNAL i_cmd_cancel : STD_ULOGIC;
  SIGNAL i_cmd_product : STD_ULOGIC;
  SIGNAL i_product_type : ProductType;
  SIGNAL i8_converted_secs : BYTE;
  SIGNAL o_status : MachineStatus;
  SIGNAL o_status_send : STD_ULOGIC;
  SIGNAL o8_REMAINING_SECS : STD_ULOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL o_PRODUCT_STR : ProductType;

  CONSTANT c_CLK_FREQ : POSITIVE := 100_000_000;
  CONSTANT c_CLK_PERIOD : TIME := 1 sec / c_CLK_FREQ; -- 10 ns
  CONSTANT c_UART_FREQ : POSITIVE := 10_000_000;
  CONSTANT c_UART_PERIOD : TIME := 1 sec / c_UART_FREQ; -- 100 ns
  SIGNAL stop_the_clock : BOOLEAN;

BEGIN

  -- Insert values for generic parameters !!
  uut : FSM0 GENERIC MAP(g_CLK_FREQ => 100_000_000)
  PORT MAP(
    i_CLK => i_CLK,
    i_RESET_N => i_RESET_N,
    i_CANCEL_BTN => i_CANCEL_BTN,
    o_HEATER => o_HEATER,
    i_cmd_received => i_cmd_received,
    i_cmd_cancel => i_cmd_cancel,
    i_cmd_product => i_cmd_product,
    i_product_type => i_product_type,
    i8_converted_secs => i8_converted_secs,
    o_status => o_status,
    o_status_send => o_status_send,
    o8_REMAINING_SECS => o8_REMAINING_SECS,
    o_PRODUCT_STR => o_PRODUCT_STR);

  stimulus : PROCESS
  BEGIN

    i_RESET_N <= '1';
    i_CANCEL_BTN <= '0';
    i_cmd_received <= '0';
    i_cmd_cancel <= '0';
    i_cmd_product <= '0';
    i_product_type <= NONE;
    i8_converted_secs <= (OTHERS => '0');
    WAIT FOR c_CLK_PERIOD;
    -- Put initialisation code here

    --ENTRY-POINT

    WAIT FOR c_CLK_PERIOD;
    ASSERT o_HEATER = '0' AND o_status = AVAILABLE AND o_PRODUCT_STR = DASHES REPORT "Fallo ENTRY-POINT" SEVERITY error;

    i_cmd_received <= '1';
    i_cmd_product <= '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= "00000101";
    WAIT FOR c_CLK_PERIOD + c_CLK_PERIOD; -- add another cycle since o_status gets updated a cycle later
    ASSERT o_status = BUSY OR o_status = STARTED_PROD REPORT "Fallo transición ENTRY-POINT" SEVERITY error;
    WAIT FOR c_CLK_PERIOD;
    i_cmd_received <= '0';
    i_cmd_product <= '0';
    --PRELAUNCH DURA UN SOLO CICLO
    --COUNT_DOWN

    WAIT FOR c_CLK_PERIOD;
    ASSERT o_HEATER = '1' AND (o_status = STARTED_PROD OR o_status = BUSY) REPORT "Fallo COUNT-DOWN" SEVERITY error;

    i_RESET_N <= '0';
    WAIT FOR c_CLK_PERIOD;
    ASSERT o_HEATER = '0' AND o_status_send = '0' AND o_PRODUCT_STR = DASHES REPORT "Fallo reset" SEVERITY error;
    i_RESET_N <= '1';
    WAIT FOR c_CLK_PERIOD;

    i_cmd_received <= '1';
    i_cmd_product <= '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= "00000101";
    WAIT FOR c_CLK_PERIOD;
    i_cmd_received <= '0';
    i_cmd_product <= '0';
    WAIT FOR c_CLK_PERIOD;
    --CANCELLED
    i_cmd_received <= '1';
    i_cmd_product <= '0';
    i_cmd_cancel <= '1';
    WAIT FOR c_CLK_PERIOD*3;
    ASSERT o_HEATER = '0' AND o_status = CANCELLED AND o_PRODUCT_STR = CANCEL REPORT "Fallo cancelación" SEVERITY error;
    i_cmd_received <= '0';
    i_cmd_product <= '0';
    WAIT FOR c_CLK_PERIOD;

    i_cmd_cancel <= '0';
    i_cmd_received <= '1';
    i_cmd_product <= '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= "00000101";
    WAIT FOR c_CLK_PERIOD;
    i_cmd_received <= '0';
    i_cmd_product <= '0';
    WAIT FOR c_CLK_PERIOD*4;

    ASSERT o_HEATER = '1' AND (o_status = STARTED_PROD OR o_status = BUSY) REPORT "Fallo transicion CANCELLED" SEVERITY error;

    --FINISHED

    WAIT FOR 7 sec + c_CLK_PERIOD;
    ASSERT o_HEATER = '0' AND o_status = FINISHED AND o_PRODUCT_STR = COFFEE REPORT "Fallo terminacion" SEVERITY error;

    i_cmd_received <= '1';
    i_cmd_product <= '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= "00000101";
    WAIT FOR c_CLK_PERIOD;
    i_cmd_received <= '0';
    i_cmd_product <= '0';
    WAIT FOR c_CLK_PERIOD*2;
    ASSERT o_HEATER = '1' AND (o_status = STARTED_PROD OR o_status = BUSY) REPORT "Fallo transicion FINISHED" SEVERITY error;

    -- Put test bench stimulus code here

    stop_the_clock <= true;
    WAIT;
  END PROCESS;

  clocking : PROCESS
  BEGIN
    WHILE NOT stop_the_clock LOOP
      i_CLK <= '0', '1' AFTER c_CLK_PERIOD / 2;
      WAIT FOR c_CLK_PERIOD;
    END LOOP;
    WAIT;
  END PROCESS;

END;
