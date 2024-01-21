/*
 * cafetera.hpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#ifndef INC_CAFETERA_HPP_
#define INC_CAFETERA_HPP_

#include "stm32f4xx_hal.h"

//#include "stm32f4xx_hal.h"
enum FPGA_TABLE {
	FAULT = 0x7FU,
	BUSY = 0x01U,
	STARTED = 0x04U,
	AVAILABLE = 0x02U,
	FINISHED = 0x03U,
	UNDEF = 0x80U
	UNKNOWN = 0x00U
};

class Cafetera{
	uint8_t status;
	UART_HandleTypeDef *UART_DIR;
public:
	Cafetera(UART_HandleTypeDef * uart_dir):UART_DIR(uart_dir){}
	void init(){
		HAL_UART_Receive_DMA(UART_DIR, &status, 1);
	}
	void Send(uint8_t msg){HAL_UART_Transmit(UART_DIR, &msg, 1, 5);}
	//void SendProd( msg){HAL_UART_Transmit(UART_DIR, msg, 1, 5);}
	uint8_t getRawStatus(){return status;}
	UART_HandleTypeDef * getUART_DIR() {return UART_DIR;}
	FPGA_TABLE getStatus(){
		switch(status){
		case FAULT:
			return FAULT;
			break;
		case BUSY:
			return BUSY;
			break;
		case AVAILABLE:
			return AVAILABLE;
			break;
		case FINISHED:
			return FINISHED;
			break;
		case UNDEF:
			return UNDEF;
			break;
		default:
			return UNDEF;
			break;
		}
	}
};



#endif /* INC_CAFETERA_HPP_ */
