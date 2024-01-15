# Trabajo para Sistemas Electrónicos Digitales

    Autoría de: Echedey Luis, Lucas Gómez y Lucas Herrera.

Consta de dos proyectos principales para ser evaluados conjuntamente:

* SED_FPGA_Project
* SED_MICRO_Project

## SED_FPGA_Project

    Hardware: Artix 7
    Lenguaje: VHDL

Simula, mediante un temporizador, una máquina expendedora de bebidas calientes.
Implementa una máquina de estados, una entidad de comunicaciones y el control de sus 7-segmentos.

## SED_MICRO_Project

    Hardware: STM32F4[07/11] Discovery board
    Lenguaje: C y C++

Es la interfaz que permite controlar, preliminarmente, varias FPGAs.
Consta de una botonera de 16 caracteres y una pantalla LCD.
También tiene una máquina de estados.

## Comunicación

Para comunicar ambas placas se emplea protocolo UART, a 3 hilos: MCU->FPGA, FPGA->MCU y GND.

Nótese que si ambas placas están conectadas mediante USB a un mismo disposivo, se puede
obviar el cable de tierra, pues eso lo comparten mediante las citadas conexiones.

Para comprobar la integridad de las comunicaciones de la FPGA, se provee el proyecto
`Sandbox/Test00`, que permite enviarle un byte y recibir constantemente lo que llegue.

De momento solo se envía un byte que codifica toda la información necesaria para seleccionar
el tipo de producto (café, té, leche, chocolate) y un tiempo, con una resolución de 3s
y un máximo de tiempo de calentado de 251 segundos.

Se cancela lo que sea que esté haciendo mediante el código especial `0xFF`.

Mediante enumerados la FPGA devuelve su disponibilidad. Si mientras hace algo, se le pide
que haga otra cosa, responde que está ocupada.

## `Report/`

Diagramas empleados en la memoria.

---

README creado por cortesía de Echedey.
