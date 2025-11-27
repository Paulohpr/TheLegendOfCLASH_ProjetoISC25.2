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
				
				# Espera 10 segundos
				li a0,100000
				call DELAY
				
				# Mostra o mapa spawn
				la a0,spawn
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT
				
				# Inicializa posição do personagem
				li s0,160			# posição X do personagem (centro da tela)
				li s1,120			# posição Y do personagem (centro da tela)
				li s2,0				# offset X no sprite sheet (qual frame mostrar)
				li s3,0				# offset Y no sprite sheet (qual animação)
				li s4,0				# contador de frames para animação
				
				j GAME_LOOP

# Loop principal do jogo
GAME_LOOP:
				# Redesenha o mapa
				la a0,spawn
				li a1,0 
				li a2,0 
				li a3,0
				call PRINT
				
				# Desenha o personagem na posição atual
				la a0,knight
				mv a1,s0			# posição X na tela
				mv a2,s1			# posição Y na tela
				mv a4,s2			# offset X no sprite (qual frame)
				mv a5,s3			# offset Y no sprite (qual animação)
				li a3,0
				call PRINT_SPRITE
				
				# Lê input do teclado
				call LER_TECLA
				
				# Atualiza animação
				addi s4,s4,1
				li t0,8
				blt s4,t0,SKIP_ANIM
				li s4,0
				addi s2,s2,26		# próximo frame (largura de cada sprite = 26)
				li t0,104			# 4 frames * 26 = 104
				blt s2,t0,SKIP_ANIM
				li s2,0
SKIP_ANIM:
				
				# Pequeno delay para controlar velocidade
				li a0,500
				call DELAY
				
				j GAME_LOOP

# Lê tecla e move personagem
LER_TECLA:
				li t1,0xFF200000
				lw t0,0(t1)
				andi t0,t0,0x0001
				beqz t0,FIM_LER_TECLA
				
				lw t2,4(t1)			# lê código da tecla
				
				# Verifica W (119) - cima
				li t3,119
				beq t2,t3,MOVE_CIMA
				
				# Verifica A (97) - esquerda
				li t3,97
				beq t2,t3,MOVE_ESQUERDA
				
				# Verifica S (115) - baixo
				li t3,115
				beq t2,t3,MOVE_BAIXO
				
				# Verifica D (100) - direita
				li t3,100
				beq t2,t3,MOVE_DIREITA
				
				j FIM_LER_TECLA

MOVE_CIMA:
				addi s1,s1,-2		# move para cima
				li s3,0				# linha 0 do sprite (andando pra cima)
				j FIM_LER_TECLA

MOVE_BAIXO:
				addi s1,s1,2		# move para baixo
				li s3,0				# linha 0 do sprite
				j FIM_LER_TECLA

MOVE_ESQUERDA:
				addi s0,s0,-2		# move para esquerda
				li s3,18			# linha 1 do sprite (andando pra esquerda)
				j FIM_LER_TECLA

MOVE_DIREITA:
				addi s0,s0,2		# move para direita
				li s3,18			# linha 1 do sprite (andando pra direita)
				j FIM_LER_TECLA

FIM_LER_TECLA:
				ret

#
# PRINT_SPRITE - Imprime sprite com offset
#			a0 = endereço do sprite sheet
#			a1 = x na tela
#			a2 = y na tela
#			a3 = frame
#			a4 = offset X no sprite (qual coluna)
#			a5 = offset Y no sprite (qual linha)
#
PRINT_SPRITE:
				# Calcula endereço do bitmap
				li t0,0xFF0
				add t0,t0,a3
				slli t0,t0,20
				add t0,t0,a1
				li t1,320
				mul t1,t1,a2
				add t0,t0,t1
				
				# Pega largura e altura total do sprite sheet
				lw t4,0(a0)			# largura total
				lw t5,4(a0)			# altura total
				
				# Define tamanho do sprite individual (26x18)
				li t6,26			# largura do sprite
				li s5,18			# altura do sprite
				
				# Calcula posição inicial no sprite sheet
				addi t1,a0,8		# início dos dados
				mul t2,a5,t4		# offset Y * largura total
				add t2,t2,a4		# + offset X
				add t1,t1,t2		# posição inicial
				
				# Desenha sprite
				mv t2,zero			# contador linha
				mv t3,zero			# contador coluna
				
SPRITE_LINHA:
				lbu a6,0(t1)
				
				# Verifica transparência (199 = magenta/transparente)
				li s6,199
				beq a6,s6,SKIP_PIXEL
				
				sb a6,0(t0) ## Utilizando a6 pq t7 n existe!!!
				
SKIP_PIXEL:
				addi t0,t0,1
				addi t1,t1,1
				addi t3,t3,1
				blt t3,t6,SPRITE_LINHA
				
				# Próxima linha
				addi t0,t0,320
				sub t0,t0,t6
				
				# Pula para próxima linha no sprite sheet
				sub t1,t1,t6
				add t1,t1,t4
				
				mv t3,zero
				addi t2,t2,1
				blt t2,s5,SPRITE_LINHA
				
				ret

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
.include "sprites/tela_menu.s"
.include "sprites/pushbutton.s"
.include "sprites/blackscreen.s"
.include "sprites/historia.s"
.include "sprites/overworld_spawn.s"
.include "sprites/knight.s"
