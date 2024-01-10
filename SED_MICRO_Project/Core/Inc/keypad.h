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

extern uint16_t outall;
extern uint16_t inps[4];
extern uint16_t outs[4];

extern const char pads[17];

//uint16_t getKey();

int getKey();

#endif /* INC_KEYPAD_H_ */
