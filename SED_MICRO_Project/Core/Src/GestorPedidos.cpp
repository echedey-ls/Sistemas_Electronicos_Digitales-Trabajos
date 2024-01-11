/*
 * GestorPedidos.cpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#include "GestorPedidos.hpp"
#include "Pedido.hpp"

GestorPedidos::GestorPedidos(Cafetera caf1){
	cafetera_vec.push_back(caf1);
}

GestorPedidos::GestorPedidos(Cafetera caf1, Cafetera caf2=Cafetera(nullptr), Cafetera caf3=Cafetera(nullptr)){
	cafetera_vec.push_back(caf1);
	if(caf2.getUART_DIR()!= nullptr)cafetera_vec.push_back(caf2);
	if(caf3.getUART_DIR()!= nullptr)cafetera_vec.push_back(caf3);
}

GestorPedidos::GestorPedidos(UART_HandleTypeDef * caf1, UART_HandleTypeDef * caf2=nullptr, UART_HandleTypeDef * caf3=nullptr){
	cafetera_vec.push_back(Cafetera(caf1));
	if(caf2!=nullptr)cafetera_vec.push_back(Cafetera(caf2));
	if(caf3!=nullptr)cafetera_vec.push_back(Cafetera (caf3));
}

uint8_t GestorPedidos::huart_p2Cafetera_index(UART_HandleTypeDef * uart_dir){
	for (uint8_t i=0; i<cafetera_vec.size(); i++){
		if(uart_dir == cafetera_vec[i].getUART_DIR()){
			return i;
		}
	}
	return cafetera_vec.size();//error
}

//traducción a nuestro protocolo propio de UART
uint8_t Prod2msg(const Pedido_t prod, uint8_t time){
	uint8_t msg = time & 0b11111100;
	switch(prod){
	case Pedido_t::CAFE:
		msg = msg | Pedido_t::CAFE;
		break;
	case Pedido_t::CHOCOLATE:
		msg = msg | Pedido_t::CHOCOLATE;
		break;
	case Pedido_t::LECHE:
		msg = msg | Pedido_t::LECHE;
		break;
	case Pedido_t::TE:
		msg = msg | Pedido_t::TE;
		break;
	default:
		return 0x04; //error
		break;
	}
	return msg;
}

//si no hay máquinas devuelve 1, si todas están ocupadas, devuelve 2, si todo ok 0
uint8_t GestorPedidos::HacerPedido(Pedido* p){
	if (cafetera_vec.size()==0){
		delete p;
		Pedido::last_id = Pedido::last_id-1;
		return 1;
		//si no se consigue, no se añade y por tanto bajamos el id que
		//habíamos subido
	}

	uint8_t caf_index;
	FPGA_TABLE stat;
	for (uint8_t i=0; i<cafetera_vec.size(); i++){
		stat = cafetera_vec[i].getStatus();
		if((stat == FPGA_TABLE::AVAILABLE)||(stat == FPGA_TABLE::FINISHED)
				||(stat == FPGA_TABLE::FAULT)){
			caf_index = i;
			break;
		} //si no hemos entrado en el if anterior en el último bucle, no hay cafeteras
		//disponibles, mandaremos mensaje de error
		else if(i==cafetera_vec.size()-1) caf_index = cafetera_vec.size();
	}
	//este es el caso en el que no hay disponibles
	if (caf_index == cafetera_vec.size()){
		delete p;
		Pedido::last_id = Pedido::last_id-1;
		return 2;
	}
	//en este caso, mandamos el pedido a la máquina
	else {
		p->setAssignedCaf(caf_index);//le asignamos la primera libre
		active_orders.push_back(p); //añadimos el pedido a los que están siendo atendidos
	 	cafetera_vec[caf_index].Send(Prod2msg(p->getProduct(), p->getTime()));
	 	return 0;
	}
}

uint8_t GestorPedidos::HacerPedido(Pedido_t prod, uint8_t time){
	return this->HacerPedido(new Pedido(prod, time));
}

uint8_t GestorPedidos::PedidoFinalizado(uint8_t caf_index){
	for (uint8_t i=0; i<active_orders.size(); i++){
		if(caf_index == active_orders[i]->getAssignedCaf()){
			delete active_orders[i]; //borramos el objeto "pedido" que ya ha sido atendido
			active_orders.erase(active_orders.begin()+i);//quitamos el pedido que ha sido atendido
			return i; //return de la posición de pedido quitada
		}
	}
	return active_orders.size();//error
}
