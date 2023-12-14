/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.h
  * @brief          : Header for main.c file.
  *                   This file contains the common defines of the application.
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

/* Define to prevent recursive inclusion -------------------------------------*/
#ifndef __MAIN_H
#define __MAIN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Includes ------------------------------------------------------------------*/
#include "stm32f4xx_hal.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Exported types ------------------------------------------------------------*/
/* USER CODE BEGIN ET */

/* USER CODE END ET */

/* Exported constants --------------------------------------------------------*/
/* USER CODE BEGIN EC */

/* USER CODE END EC */

/* Exported macro ------------------------------------------------------------*/
/* USER CODE BEGIN EM */

/* USER CODE END EM */

/* Exported functions prototypes ---------------------------------------------*/
void Error_Handler(void);

/* USER CODE BEGIN EFP */

/* USER CODE END EFP */

/* Private defines -----------------------------------------------------------*/
#define teclado_PIN0_IN_Pin GPIO_PIN_0
#define teclado_PIN0_IN_GPIO_Port GPIOD
#define teclado_PIN1_IN_Pin GPIO_PIN_1
#define teclado_PIN1_IN_GPIO_Port GPIOD
#define teclado_PIN2_IN_Pin GPIO_PIN_2
#define teclado_PIN2_IN_GPIO_Port GPIOD
#define teclado_PIN3_IN_Pin GPIO_PIN_3
#define teclado_PIN3_IN_GPIO_Port GPIOD
#define teclado_PIN4_OUT_Pin GPIO_PIN_4
#define teclado_PIN4_OUT_GPIO_Port GPIOD
#define teclado_PIN5_OUT_Pin GPIO_PIN_5
#define teclado_PIN5_OUT_GPIO_Port GPIOD
#define teclado_PIN6_OUT_Pin GPIO_PIN_6
#define teclado_PIN6_OUT_GPIO_Port GPIOD
#define teclado_PIN7_OUT_Pin GPIO_PIN_7
#define teclado_PIN7_OUT_GPIO_Port GPIOD

/* USER CODE BEGIN Private defines */

/* USER CODE END Private defines */

#ifdef __cplusplus
}
#endif

#endif /* __MAIN_H */
