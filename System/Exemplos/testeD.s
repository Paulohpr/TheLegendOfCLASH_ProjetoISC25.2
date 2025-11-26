.include "MACROSv24.s"

.data
NL: .string "\n"

.data
STR: .string "                         "

.text

MAIN: 
#li a7,6   	# um double do teclado e armazena em fa0 7
#ecall

li a7,106	# le do Keyboard MMIO
ecall


li a7,104		# apaga o número da tela
la a0,STR
li a1,96
li a2,120
li a3,0x00 		#preto
li a4,0
ecall 


li a7,2 	# imprime o double em fa0 na tela 3
ecall

la a0,NL
li a7,4
ecall

li a7,102 	# imprime o double em fa0 na tela gráfica 103
li a1,96
li a2,120
li a3,0x38 #0b 0011 1000
li a4,0
ecall


j MAIN

li a7,10
ecall

.include "SYSTEMv24.s"
