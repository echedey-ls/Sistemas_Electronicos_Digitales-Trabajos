/*
 * GestorPedidos.hpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#ifndef INC_GESTORPEDIDOS_HPP_
#define INC_GESTORPEDIDOS_HPP_

#include "cafetera.hpp"
#include "Pedido.hpp"
#include <vector>

class GestorPedidos{
	std::vector<Cafetera> cafetera_vec;
	std::vector<Pedido*> active_orders;
public:
	GestorPedidos(std::vector<Cafetera> v):cafetera_vec(v){}
	GestorPedidos(Cafetera caf1, Cafetera caf2, Cafetera caf3);
	GestorPedidos(Cafetera caf1);
	GestorPedidos(UART_HandleTypeDef * caf1, UART_HandleTypeDef * caf2, UART_HandleTypeDef * caf3);
	void AddCafetera(Cafetera c){cafetera_vec.push_back(c);}
	uint8_t huart_p2Cafetera_index(UART_HandleTypeDef * uart_dir);
	uint8_t getRawStatus(uint8_t caf_index){return cafetera_vec[caf_index].getRawStatus();}
	FPGA_TABLE getStatus(uint8_t caf_index){return cafetera_vec[caf_index].getStatus();}
	uint8_t HacerPedido(Pedido* p);
	uint8_t HacerPedido(Pedido_t prod, uint8_t time);
};



#endif /* INC_GESTORPEDIDOS_HPP_ */
