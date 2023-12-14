/*
 * keypad.c
 *
 *  Created on: Dec 6, 2023
 *      Author: Lucas Herrera
 */

#include "keypad.h"

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

void getKey(char* str){
	int btns = 0;
	for(int i = 0; i < 4; i++){
		HAL_GPIO_WritePin(BANK, outs[i], GPIO_PIN_SET);
		HAL_GPIO_WritePin(BANK, (outall ^ outs[i]), GPIO_PIN_RESET);
		for(int j = 0; j < 4; j++){
			if(HAL_GPIO_ReadPin(BANK, inps[j])) btns = i*4 + j + 1;
		}
	}
	str[0] = pads[btns];
	str[1] = '\0';
}
