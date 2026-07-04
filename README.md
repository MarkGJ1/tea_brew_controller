# Tea Brew Controller
A fully synthesizable digital timer circuit coupled with UART and a custom three-wire communication interface written in VHDL. <br>
The Tea Brew Controller counts the elapsed time using an internal RTC and, once the tea bag has been submerged for long enough, transmits a 1kHz soundwave, flashes an LED, and sends a message to the PC via UART.

All simulations and compilations were performed in ModelSim.<br>
Synthesis, place-and-route were done in GOWIN FPGA Designer.<br>
Programming was done using [openFPGALoader](https://github.com/trabucayre/openFPGALoader).<br>
Target-board: Tang Nano 9K (GW1NR-LV9QN88PC6/I5)

## DEMO
![DEMO](DEMO.gif)

## Project Structure
- py: python scripts used for communicating between the target board and PC (UART 9600 8N2).
- src: synthesizable modules and top level.
- tb: testbenches for the project

## Block Diagram of the Architecture
- TBA...

### Previous toolchain (legacy)
> This section reflects an earlier version of the project. See the [original modules](https://github.com/MarkGJ1/tea_brew_controller/commit/9bd1245fca169cd15b82d5c88ca72abe201ece68) for full context.

All simulations and compilations were performed in ModelSim.<br>
Synthesis, place-and-route, and programming were done in Intel's Quartus Prime Lite.<br>
For hardware, the MAX1000 board was used as the flashing target.<br>
Originally a part of an university course "Computer-aided Circuit Design 2" taught by Prof. Dr.-Ing. Andreas Siggelkow.
