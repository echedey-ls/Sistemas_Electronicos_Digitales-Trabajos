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

//traducción a nuestro protocolo propio de UART
uint8_t Prod2msg(Prod_t prod, uint8_t time){
	uint8_t msg = time & b11111100;
	msg = msg | prod;
	return msg;
}

//si no hay máquinas devuelve 1, si todas están ocupadas, devuelve 2, si todo ok 0
uint8_t HacerPedido(Pedido p){
	if (cafetera_vec.size()==0){
		delete p;
		Pedido::last_id-1;
		return 1;
		//si no se consigue, no se añade y por tanto bajamos el id que
		//habíamos subido
	}

	uint8_t caf_index;
	for (uint8_t i=0; i<cafetera_vec.size(); i++){
		if(cafetera_vec[i].getStatus() == AVAILABLE){
			caf_index = i;
			break;
		} //si no hemos entrado en el if anterior en el último bucle, no hay cafeteras
		//disponibles, mandaremos mensaje de error
		else if(i==cafetera_vec.size()-1) caf_index = cafetera_vec.size();
	}
	//este es el caso en el que no hay disponibles
	if (caf_index == cafetera_vec.size()){
		delete p;
		Pedido::last_id-1;
		return 2;
	}
	//en este caso, mandamos el pedido a la máquina
	else {
		p.setAssignedCaf(caf_index);//le asignamos la primera libre
		active_orders.push_back(p); //añadimos el pedido a los que están siendo atendidos
	 	cafetera_vec(caf_index).Send(Prod2msg(p.getProduct(), p.getTime()));
	 	return 0;
	}
}

uint8_t HacerPedido(Pedido_t prod, uint8_t time){
	Pedido p(prod, time);
	return this->HacerPedido(p);
}
