/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2023 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.hpp"

#include "i2c-lcd.h"
#include "keypad.h"
#include "GestorPedidos.hpp"
#include "cafetera.hpp"
#include "Pedido.hpp"

#include <cstring>
#include <stdlib.h>
/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */

/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
I2C_HandleTypeDef hi2c1;

UART_HandleTypeDef huart4;
DMA_HandleTypeDef hdma_uart4_rx;

/* USER CODE BEGIN PV */

FPGA_TABLE fpga_status_h4 = FPGA_TABLE::UNDEF;

enum class MCU_STATES{
	IDLE,
	SELECT,
	TEMP,
	CONFIRM,
	BUSY,
	CANCEL,
	DONE,
	ERR
};

MCU_STATES state = MCU_STATES::IDLE;

void f_idle();
void f_select();
void f_confirm();
void f_busy();
void f_cancel();
void f_done();
void f_temp();
void f_error();

//uint8_t FPGA_STATUS;
/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_DMA_Init(void);
static void MX_I2C1_Init(void);
static void MX_UART4_Init(void);
/* USER CODE BEGIN PFP */

/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */
int row=0;
int col=0;

char coffee[20];
Cafetera c(&huart4);
GestorPedidos Gestor(&c);

Pedido_t cafe;

uint8_t time = 20; //tiempo por defecto
char temp = '1'; //Nivel de temperatura por defecto
char dTemp[] = {'1', '\0'}; //Para mostrar nivel de temperatura

uint8_t t2t = 20; //Constante de conversión de nivel de temperatura a tiempo

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */
	//Al crear la cafetera se pone ya a escuchar con DMA por &huart4

	//HAL_UART_Receive_DMA(&huart4, &fpga_status_h4, 1);
  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_DMA_Init();
  MX_I2C1_Init();
  MX_UART4_Init();
  Gestor.init(0);
  /* USER CODE BEGIN 2 */

  lcd_init ();
  lcd_put_cur(0, 0);
  lcd_send_string("STARTUP...");
  HAL_Delay(5000);
  lcd_clear();
  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {
	  
	  //This call is non blocking and should be called when we want to
	  //start updating FPGA_STATUS
    /* USER CODE END WHILE */

    /* USER CODE BEGIN 3 */
	  /*BEGIN Máquina de Estados*/
	  	  switch(state){
	  	  case MCU_STATES::IDLE:
	  		  f_idle();
	  		  break;
	  	  case MCU_STATES::SELECT:
	  		  f_select();
	  		  break;
	  	  case MCU_STATES::TEMP:
	  		f_temp();
	  		   break;
	  	  case MCU_STATES::CONFIRM:
	  		  f_confirm();
	  		  break;
	  	  case MCU_STATES::BUSY:
	  		  f_busy();
	  		  break;
	  	case MCU_STATES::CANCEL:
	  		  f_cancel();
	  		  break;
	  	  case MCU_STATES::DONE:
	  		  f_done();
	  		  break;
	  	  case MCU_STATES::ERR:
	  		  f_error();
	  		  break;
	  	  }

  }
  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Configure the main internal regulator output voltage
  */
  __HAL_RCC_PWR_CLK_ENABLE();
  __HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI;
  RCC_OscInitStruct.PLL.PLLM = 8;
  RCC_OscInitStruct.PLL.PLLN = 50;
  RCC_OscInitStruct.PLL.PLLP = RCC_PLLP_DIV4;
  RCC_OscInitStruct.PLL.PLLQ = 7;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }

  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV4;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV2;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_0) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief I2C1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_I2C1_Init(void)
{

  /* USER CODE BEGIN I2C1_Init 0 */

  /* USER CODE END I2C1_Init 0 */

  /* USER CODE BEGIN I2C1_Init 1 */

  /* USER CODE END I2C1_Init 1 */
  hi2c1.Instance = I2C1;
  hi2c1.Init.ClockSpeed = 100000;
  hi2c1.Init.DutyCycle = I2C_DUTYCYCLE_2;
  hi2c1.Init.OwnAddress1 = 0;
  hi2c1.Init.AddressingMode = I2C_ADDRESSINGMODE_7BIT;
  hi2c1.Init.DualAddressMode = I2C_DUALADDRESS_DISABLE;
  hi2c1.Init.OwnAddress2 = 0;
  hi2c1.Init.GeneralCallMode = I2C_GENERALCALL_DISABLE;
  hi2c1.Init.NoStretchMode = I2C_NOSTRETCH_DISABLE;
  if (HAL_I2C_Init(&hi2c1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN I2C1_Init 2 */

  /* USER CODE END I2C1_Init 2 */

}

/**
  * @brief UART4 Initialization Function
  * @param None
  * @retval None
  */
static void MX_UART4_Init(void)
{

  /* USER CODE BEGIN UART4_Init 0 */

  /* USER CODE END UART4_Init 0 */

  /* USER CODE BEGIN UART4_Init 1 */

  /* USER CODE END UART4_Init 1 */
  huart4.Instance = UART4;
  huart4.Init.BaudRate = 10000;
  huart4.Init.WordLength = UART_WORDLENGTH_8B;
  huart4.Init.StopBits = UART_STOPBITS_1;
  huart4.Init.Parity = UART_PARITY_NONE;
  huart4.Init.Mode = UART_MODE_TX_RX;
  huart4.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart4.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart4) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN UART4_Init 2 */

  /* USER CODE END UART4_Init 2 */

}

/**
  * Enable DMA controller clock
  */
static void MX_DMA_Init(void)
{

  /* DMA controller clock enable */
  __HAL_RCC_DMA1_CLK_ENABLE();

  /* DMA interrupt init */
  /* DMA1_Stream2_IRQn interrupt configuration */
  HAL_NVIC_SetPriority(DMA1_Stream2_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(DMA1_Stream2_IRQn);

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};
/* USER CODE BEGIN MX_GPIO_Init_1 */
/* USER CODE END MX_GPIO_Init_1 */

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(GPIOD, teclado_PIN4_OUT_Pin|teclado_PIN5_OUT_Pin|teclado_PIN6_OUT_Pin|teclado_PIN7_OUT_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pins : teclado_PIN0_IN_Pin teclado_PIN1_IN_Pin teclado_PIN2_IN_Pin teclado_PIN3_IN_Pin */
  GPIO_InitStruct.Pin = teclado_PIN0_IN_Pin|teclado_PIN1_IN_Pin|teclado_PIN2_IN_Pin|teclado_PIN3_IN_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_INPUT;
  GPIO_InitStruct.Pull = GPIO_PULLDOWN;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

  /*Configure GPIO pins : teclado_PIN4_OUT_Pin teclado_PIN5_OUT_Pin teclado_PIN6_OUT_Pin teclado_PIN7_OUT_Pin */
  GPIO_InitStruct.Pin = teclado_PIN4_OUT_Pin|teclado_PIN5_OUT_Pin|teclado_PIN6_OUT_Pin|teclado_PIN7_OUT_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(GPIOD, &GPIO_InitStruct);

/* USER CODE BEGIN MX_GPIO_Init_2 */
/* USER CODE END MX_GPIO_Init_2 */
}

/* USER CODE BEGIN 4 */

/*enum FPGA_TABLE {
	FAULT = 0x7FU,
	BUSY = 0x01U,
	AVAILABLE = 0x02U,
	FINISHED = 0x03U,
	UNDEF = 0x80U
};*/

/*Funciones Máquina de Estado*/
/*Funciones Máquina de Estado*/
void f_idle(){

	lcd_put_cur(0, 0);
	lcd_send_string("PRESIONE UN BOTON");
	lcd_put_cur(1, 0);
	lcd_send_string("PARA CONTINUAR");
	if(getKey()){
		state = MCU_STATES::SELECT;
		lcd_clear();
	}
	if(Gestor.getStatus(0) != FPGA_TABLE::AVAILABLE){
		state = MCU_STATES::ERR;
		lcd_clear();
	}
}

void f_select(){

	static int sel;
	sel = getKey();
	static char cof;
	cof = pads[sel];
	lcd_put_cur(0, 0);
	lcd_send_string("SELECCIONE UN");
	lcd_put_cur(1, 0);
	lcd_send_string("PRODUCTO");
	switch(cof){
	case '1':
		strcpy(coffee, "Cafe");
		cafe = Pedido_t::CAFE;
		state = MCU_STATES::TEMP;
		lcd_clear();
		break;
	case '2':
		strcpy(coffee, "Leche");
		cafe = Pedido_t::LECHE;
		state = MCU_STATES::TEMP;
		lcd_clear();
		break;
	case '3':
		strcpy(coffee, "Te");
		cafe = Pedido_t::TE;
		state = MCU_STATES::TEMP;
		lcd_clear();
		break;
	case '4':
		strcpy(coffee, "Chocolate");
		cafe = Pedido_t::CHOCOLATE;
		state = MCU_STATES::TEMP;
		lcd_clear();
		break;
	default:
		break;
	}

	if(Gestor.getStatus(0) == FPGA_TABLE::BUSY||Gestor.getStatus(0) == FPGA_TABLE::STARTED){
		state = MCU_STATES::ERR;
		lcd_clear();
	}

}

void f_confirm(){

	lcd_put_cur(0, 0);
	lcd_send_string(coffee);
	lcd_send_string("   ");
	lcd_send_string(dTemp);
	lcd_put_cur(1, 0);
	lcd_send_string("YES: A   NO: B");
	char conf = pads[getKey()];
	if(conf == 'A'){
		state = MCU_STATES::BUSY;
		lcd_clear();
	}else if(conf == 'B'){
		state = MCU_STATES::SELECT;
		lcd_clear();
	}

	if(Gestor.getStatus(0) == FPGA_TABLE::BUSY||Gestor.getStatus(0) == FPGA_TABLE::STARTED){
		state = MCU_STATES::ERR;
		lcd_clear();
	}
}

void f_busy(){

	//Falta enviar datos a FPGA
	if(Gestor.HacerPedido(cafe, time) != 0) state = MCU_STATES::ERR;

	lcd_put_cur(0, 0);
	lcd_send_string("PREPARANDO...");
	lcd_put_cur(1, 0);
	lcd_send_string("CANCELAR: D");
	HAL_Delay(200);

	/* Falta
	 * Interrupción de FPGA
	 * para cambiar a DONE
	 * (o a ERR)
	 */
	//No hay interrupción, tendremos que acceder a GestorPedidos y la caf correspondiente
	while(1){
			if(pads[getKey()] == 'D'){
					state = MCU_STATES::CANCEL;
					Gestor.CancelarPedido(0);
					Gestor.PedidoFinalizado(0);
			}
			switch(Gestor.getStatus(0)){
			case FPGA_TABLE::FINISHED:
				state = MCU_STATES::DONE;
			break;
			case FPGA_TABLE::BUSY:
				break;
			case FPGA_TABLE::FAULT://caso cancelar
				state = MCU_STATES::CANCEL;
				Gestor.CancelarPedido(0);
				Gestor.PedidoFinalizado(0);
			break;
			default:
				state = MCU_STATES::ERR;
				Gestor.CancelarPedido(0);
				Gestor.PedidoFinalizado(0);
				break;
			}
			if (state!=MCU_STATES::BUSY) break;//salida while
	}
	lcd_clear();
		/*if(Gestor.getStatus(0) == FPGA_TABLE::FINISHED){
			state = MCU_STATES::DONE;
			lcd_clear();
		} else if(Gestor.getStatus(0) != FPGA_TABLE::BUSY){
			state = MCU_STATES::ERR;
			lcd_clear();

	/*if(Gestor.getStatus(0) == FPGA_TABLE::FINISHED){
		state = MCU_STATES::DONE;
		lcd_clear();
	} else if(Gestor.getStatus(0) != FPGA_TABLE::BUSY||Gestor.getStatus(0) != FPGA_TABLE::STARTED){
		state = MCU_STATES::ERR;
		lcd_clear();
	}*/


}

void f_done(){

	lcd_put_cur(0, 0);
	lcd_send_string("LISTO! PUEDE");
	lcd_put_cur(1, 0);
	lcd_send_string("COGER SU PRODUCTO");
	if(pads[getKey()] == 'A'){
		state = MCU_STATES::IDLE;
		lcd_clear();
	}

	if(Gestor.getStatus(0) != FPGA_TABLE::FINISHED){
		state = MCU_STATES::ERR;
		lcd_clear();
	}

	Gestor.PedidoFinalizado(0);

}



void f_temp(){

	static char num = '1';

	lcd_put_cur(0, 0);
	lcd_send_string(coffee);
	lcd_put_cur(1, 0);
	lcd_send_string("Calor: ");
	num = pads[getKey()];

	if((num >= 49) && (num <= 53)){
		temp = num;
		dTemp[0] = num;
		lcd_send_string(dTemp);
		time = (num - 48)*t2t;
	}
	if(num == 'A'){
		state = MCU_STATES::CONFIRM;
		lcd_clear();
	}

	if(Gestor.getStatus(0) == FPGA_TABLE::BUSY||Gestor.getStatus(0) == FPGA_TABLE::STARTED){
		state = MCU_STATES::ERR;
		lcd_clear();
	}

}

void f_error(){

	lcd_put_cur(0, 0);
	lcd_send_string("ERROR!");
	lcd_put_cur(1, 0);
	lcd_send_string("PULSE D");
	if(pads[getKey()] == 'D'){
		state = MCU_STATES::IDLE;
		lcd_clear();
	}

}

void f_cancel(){
	lcd_put_cur(0, 0);
	lcd_send_string("CANCELADO");
	lcd_put_cur(1, 0);
	lcd_send_string("PULSE D");
	if(pads[getKey()] == 'D'){
		state = MCU_STATES::IDLE;
		lcd_clear();
	}
}

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */
