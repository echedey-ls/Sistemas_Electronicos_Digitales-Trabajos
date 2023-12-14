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

const char pads[] = {'\0',
		'1', '4', '7', '*',
		'2', '5', '8', '0',
		'3', '6', '9', '#',
		'A', 'B', 'C', 'D'
};

void getKey(char* str);

#endif /* INC_KEYPAD_H_ */
