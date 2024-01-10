/*
 * keypad.c
 *
 *  Created on: Dec 6, 2023
 *      Author: Lucas Herrera
 */

#include "keypad.h"

uint16_t outall = GPIO_PIN_4|GPIO_PIN_5|GPIO_PIN_6|GPIO_PIN_7;

uint16_t inps[] = {GPIO_PIN_0, GPIO_PIN_1, GPIO_PIN_2, GPIO_PIN_3};
uint16_t outs[] = {GPIO_PIN_4, GPIO_PIN_5, GPIO_PIN_6, GPIO_PIN_7};

const char pads[] = {'\0',
		'1', '4', '7', '*',
		'2', '5', '8', '0',
		'3', '6', '9', '#',
		'A', 'B', 'C', 'D'
};

/*
uint16_t getKey(){
	uint16_t btns = 0;
	//HAL_GPIO_WritePin(BANK, OUTALL, GPIO_PIN_RESET);
	for(int i = 0; i < 4; i++){
		HAL_GPIO_WritePin(BANK, outs[i], GPIO_PIN_SET);
		HAL_GPIO_WritePin(BANK, (outall ^ outs[i]), GPIO_PIN_RESET);
		for(int j = 0; j < 4; j++) btns = (btns<<1) + HAL_GPIO_ReadPin(BANK, inps[j]);
	}
	return btns;
}
*/

int getKey(){
	static int pre_btn = 0;
	int btns = 0;
	for(int i = 0; i < 4; i++){
		HAL_GPIO_WritePin(BANK, outs[i], GPIO_PIN_SET);
		HAL_GPIO_WritePin(BANK, (outall ^ outs[i]), GPIO_PIN_RESET);
		for(int j = 0; j < 4; j++){
			if(HAL_GPIO_ReadPin(BANK, inps[j])) btns = i*4 + j + 1;
		}
	}
	if(btns == pre_btn) return 0;
	else {
		pre_btn = btns;
		return btns;
	}

}
