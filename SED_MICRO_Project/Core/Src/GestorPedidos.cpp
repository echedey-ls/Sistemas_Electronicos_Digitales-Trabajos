/*
 * GestorPedidos.cpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#include "GestorPedidos.hpp"

uint8_t huart_p2Cafetera_index(UART_HandleTypeDef * uart_dir){
	for (uint8_t i=0; i<cafetera_vec.size(); i++){
		if(uart_dir == cafetera_vec[i].getUART_DIR()){
			return i;
		}
	}
}
//si no hay máquinas devuelve 1, si todas están ocupadas, devuelve 2, si todo ok 0
uint8_t HacerPedido(){
	if (cafetera_vec.size()==0)return 1;

	uint8_t caf_index;
	for (uint8_t i=0; i<cafetera_vec.size(); i++){
		if(cafetera_vec[i].getStatus() == AVAILABLE){
			caf_index = i;
			break;
		} //si no hemos entrado en el if anterior en el último bucle, no hay cafeteras
		//disponibles, mandaremos mensaje de error
		else if(i==cafetera_vec.size()-1) caf_index = cafetera_vec.size();
	}
	if (caf_index == cafetera_vec.size())return 2;
	//en este caso, mandamos el pedido a la máquina
	/*else {
	 	 cafetera_vec(caf_index).Send(1);
	 	 return 0;
	  }
	 */
}
