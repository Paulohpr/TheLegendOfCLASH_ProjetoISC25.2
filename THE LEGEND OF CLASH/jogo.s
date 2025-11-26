.text 
SETUP:			
				# Mostra o menu
				la a0,menu
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT

# Loop esperando qualquer tecla
ESPERA_TECLA:	
				li t1,0xFF200000		# endereço do teclado MMIO
				lw t0,0(t1)				# lê o status do teclado
				andi t0,t0,0x0001		# verifica se há tecla pressionada
				beqz t0,ESPERA_TECLA	# se não há tecla, continua esperando
				lw t2,4(t1)				# lê a tecla pressionada (opcional, se quiser usar)
				
				# Quando uma tecla for pressionada, vai para a tela de transição
				la a0,pushbutton
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT
				
				# Espera alguns segundos
				li a0,70000
				call DELAY
				
				# Depois vai para a tela preta
				la a0,blackscreen
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT
				
				# Espera alguns segundos (metade do pushbutton)
				li a0,30000
				call DELAY
				
				# Mostra a história do jogo
				la a0,historia
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT

# Loop esperando qualquer tecla para pular a história
ESPERA_TECLA_HISTORIA:	
				li t1,0xFF200000		# endereço do teclado MMIO
				lw t0,0(t1)				# lê o status do teclado
				andi t0,t0,0x0001		# verifica se há tecla pressionada
				beqz t0,ESPERA_TECLA_HISTORIA	# se não há tecla, continua esperando
				lw t2,4(t1)				# lê a tecla pressionada
				
				j LOOP_JOGO

# Loop principal do jogo
LOOP_JOGO:		
				# Aqui vai o código do seu jogo
				
				j LOOP_JOGO

#
#			a0 = endereço imagem
#			a1 = x
#			a2 = y
#			a3 = frame (0 ou 1)
##
#			t0 = endereço do bitmap display
#			t1 = endereço da imagem
#			t2 = contador de linha
#			t3 = contador de coluna
#			t4 = largura
#			t5 = altura
#
PRINT:			li t0,0xFF0 
				add t0,t0,a3
				slli t0,t0,20
				
				add t0,t0,a1
				
				li t1,320
				mul t1,t1,a2
				add t0,t0,t1
				
				addi t1,a0,8
				
				mv t2,zero
				mv t3,zero 
				
				lw t4,0(a0)
				lw t5,4(a0)
		
PRINT_LINHA:	lw t6,0(t1)
				sw t6,0(t0)
				addi t0,t0,4
				addi t1,t1,4
				
				addi t3,t3,4
				blt t3,t4,PRINT_LINHA
				
				addi t0,t0,320
				sub t0,t0,t4
				 
				mv t3,zero
				addi t2,t2,1
				bgt t5,t2,PRINT_LINHA
				
				ret

#
#			a0 = tempo em milissegundos
#
DELAY:			li t0,5000				# ajuste esse valor conforme necessário
				mul t0,t0,a0			# multiplica pelo tempo desejado
				li t1,0
DELAY_LOOP:		addi t1,t1,1
				blt t1,t0,DELAY_LOOP
				ret

.data 
.include "menu.s"
.include "pushbutton.s"
.include "blackscreen.s"
.include "historia.s"