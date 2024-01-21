library IEEE;
use IEEE.Std_logic_1164.all;
use IEEE.Numeric_Std.all;

entity FSM0_tb is
end;

architecture bench of FSM0_tb is

  component FSM0
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
  end component;

  signal i_CLK: STD_ULOGIC;
  signal i_RESET_N: STD_ULOGIC;
  signal i_CANCEL_BTN: STD_ULOGIC;
  signal o_HEATER: STD_ULOGIC;
  signal i_cmd_received: STD_ULOGIC;
  signal i_cmd_cancel: STD_ULOGIC;
  signal i_cmd_product: STD_ULOGIC;
  signal i_product_type: ProductType;
  signal i8_converted_secs: BYTE;
  signal o_status: MachineStatus;
  signal o_status_send: STD_ULOGIC;
  signal o8_REMAINING_SECS: STD_ULOGIC_VECTOR(7 DOWNTO 0);
  signal o_PRODUCT_STR: ProductType ;

  constant clock_period: time := 10 ns;
  signal stop_the_clock: boolean;

begin

  -- Insert values for generic parameters !!
  uut: FSM0 generic map ( g_CLK_FREQ        => 100_000_000)
               port map ( i_CLK             => i_CLK,
                          i_RESET_N         => i_RESET_N,
                          i_CANCEL_BTN      => i_CANCEL_BTN,
                          o_HEATER          => o_HEATER,
                          i_cmd_received    => i_cmd_received,
                          i_cmd_cancel      => i_cmd_cancel,
                          i_cmd_product     => i_cmd_product,
                          i_product_type    => i_product_type,
                          i8_converted_secs => i8_converted_secs,
                          o_status          => o_status,
                          o_status_send     => o_status_send,
                          o8_REMAINING_SECS => o8_REMAINING_SECS,
                          o_PRODUCT_STR     => o_PRODUCT_STR );

  stimulus: process
  begin
  
  --o_HEATER : OUT STD_ULOGIC;
  --o_status : INOUT MachineStatus;
  --o_status_send : OUT STD_ULOGIC;
  --o8_REMAINING_SECS : OUT STD_ULOGIC_VECTOR(7 DOWNTO 0);
  --o_PRODUCT_STR : OUT ProductType
  
    i_RESET_N <= '1';
    i_CANCEL_BTN <= '0';
    i_cmd_received <= '0';
    i_cmd_cancel <= '0';
    i_cmd_product <= '0';
    i_product_type <= NONE;
    i8_converted_secs <= (others => '0');
    wait for 5 ns;
    -- Put initialisation code here
    
    --ENTRY-POINT
    
    wait for 5 ns;
    assert o_HEATER = '0' and o_status = AVAILABLE and o_PRODUCT_STR = DASHES report "Fallo ENTRY-POINT" severity error;
	
    i_cmd_received = '1';
    i_cmd_product = '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= '00000101';
    wait for 5 ns;
    assert o_status = BUSY or o_status = STARTED_PROD report "Fallo transición ENTRY-POINT" severity error;
    wait for 5 ns;
    i_cmd_received = '0';
    i_cmd_product = '0';
	--PRELAUNCH DURA UN SOLO CICLO
    --COUNT_DOWN

	wait for 5 ns;
    assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo COUNT-DOWN" severity error;

    i_RESET_N <= '0';
    wait for 5 ns;
    assert o_HEATER = '0' and o_status_send = '0' and o_PRODUCT_STR = DASHES report "Fallo reset" severity error;
    i_RESET_N <= '1';
    wait for 5 ns;
    
    i_cmd_received = '1';
    i_cmd_product = '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= '00000101';
  	wait for 5 ns;
    i_cmd_received = '0';
    i_cmd_product = '0';
    wait for 5 ns
    --CANCELLED
    i_cmd_received = '1';
    i_cmd_product <= '1';
    wait for 5 ns;
    assert o_HEATER = '0' and o_status = CANCELLED and o_PRODUCT_STR = CANCEL report "Fallo cancelación" severity error;
    i_cmd_received = '0';
    i_cmd_product <= '0';
    wait for 5 ns;
    
    i_cmd_received = '1';
    i_cmd_product = '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= '00000101';
  	wait for 5 ns;
    i_cmd_received = '0';
    i_cmd_product = '0';
    
    assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo transicion CANCELLED" severity error;
    
    --FINISHED
    
    wait 10 s;
    assert o_HEATER = '0' and o_status = FINISHED and o_PRODUCT_STR = COFFEE report "Fallo terminacion" severity error;
    
    i_cmd_received = '1';
    i_cmd_product = '1';
    i_product_type <= COFFEE;
    i8_converted_secs <= '00000101';
  	wait for 5 ns;
    i_cmd_received = '0';
    i_cmd_product = '0';
    wait for 5 ns;
    assert o_HEATER = '1' and (o_status = STARTED_PROD or o_status = BUSY) report "Fallo transicion FINISHED" severity error;
    
    -- Put test bench stimulus code here

    stop_the_clock <= true;
    wait;
  end process;

  clocking: process
  begin
    while not stop_the_clock loop
      i_CLK <= '0', '1' after clock_period / 2;
      wait for clock_period;
    end loop;
    wait;
  end process;

end;