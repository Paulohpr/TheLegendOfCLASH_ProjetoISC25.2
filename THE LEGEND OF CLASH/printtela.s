.text 

SETUP_MAP:		la a0,spawn
				li a1,0 # Alterar esse valores para fazer com que a imagem ande para o eixo x ou y (eixo x aqui)
				li a2,0 # eixo y
				li a3,0
				call PRINT
				li a3, 1
				call PRINT
				
GAME_LOOP:		la a0,char
				li a1, 16
				li a2, 0
				li a3, 0
				call PRINT
				
				
				
				
				
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

PRINT:			li t0,0xFF0 # vai carregar em t0 o endereço 0xFF0 (bitmap display)
				add t0,t0,a3
				slli t0,t0,20
				
				add t0,t0,a1
				
				li t1,320
				mul t1,t1,a2
				add t0,t0,t1
				
				addi t1,a0,8 ## vai fazer com que a imagem apareca de 4 em 4 pixeis, ou seja vai carregar mais rapido
				
				mv t2,zero
				mv t3,zero 
				
				lw t4,0(a0) ## no caso a imagem do menu eh uma word, por isso lw = load WORD
				lw t5,4(a0)
		
PRINT_LINHA:		lw t6,0(t1)
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

.data 
.include "sprites/overworld_spawn.s"
