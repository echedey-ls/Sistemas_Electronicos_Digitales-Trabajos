/*
 * Pedido.hpp
 *
 *  Created on: Jan 2, 2024
 *      Author: lucas
 */

#ifndef INC_PEDIDO_HPP_
#define INC_PEDIDO_HPP_

//WIP
//TBD codificar los valores en Pedido_t
enum Pedido_t{
	CAFE,
	LECHE,
	TE,
	CHOCOLATE
};

class Pedido{
	friend class GestorPedidos;
	static unint8_t last_id = 1;
	uint8_t ID;
	Pedido_t producto;
	uint8_t tiempo;
	uint8_t assigned_cafetera;
public:
	Pedido(Pedido_t prod, uint8_t time):producto(prod), tiempo(time) {ID = last_id++;}
	//post-incremento, tomará last_id, y después last_id será last_id+1
	uint8_t getID(){return ID;}
	uint8_t getAssignedCaf(){return assigned_cafetera;}
	void setAssignedCaf(uint8_t a_c){assigned_cafetera = a_c;}
	uint8_t getTime(){return tiempo;}
	Pedido_t getProduct(){return producto;}
	char* Prod2char(){
		switch(producto){
		case CAFE:
			return "CAFE";
			break;
		case LECHE:
			return "LECH";
			break;
		case TE:
			return "TE  ";
			break;
		case CHOCOLATE:
			return "CHOC";
			break;
		}
	}
};



#endif /* INC_PEDIDO_HPP_ */
