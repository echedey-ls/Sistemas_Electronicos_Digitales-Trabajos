/*
 * GestorPedidos.hpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#ifndef INC_GESTORPEDIDOS_HPP_
#define INC_GESTORPEDIDOS_HPP_

#include "cafetera.hpp"
#include <vector>

class GestorPedidos{
	std::vector<Cafetera> cafetera_vec;
public:
	GestorPedidos(std::vector<Cafetera> v):cafetera_vec(v){}
	void AddCafetera(Cafetera c){cafetera_vec.push_back(c);}
	uint8_t huart_p2Cafetera_index(UART_HandleTypeDef * uart_dir);
	uint8_t HacerPedido();
};



#endif /* INC_GESTORPEDIDOS_HPP_ */
