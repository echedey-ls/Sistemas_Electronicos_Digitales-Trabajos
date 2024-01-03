/*
 * keypad.h
 *
 *  Created on: Dec 6, 2023
 *      Author: Lucas Herrera
 */

#include "stm32f4xx_hal.h"

#ifndef INC_KEYPAD_H_
#define INC_KEYPAD_H_

#define BANK GPIOD

uint16_t outall = GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;

uint16_t inps[] = {GPIO_PIN_0, GPIO_PIN_1, GPIO_PIN_2, GPIO_PIN_3};
uint16_t outs[] = {GPIO_PIN_4, GPIO_PIN_5, GPIO_PIN_6, GPIO_PIN_7};

//uint16_t getKey();

int getKey();

#endif /* INC_KEYPAD_H_ */
