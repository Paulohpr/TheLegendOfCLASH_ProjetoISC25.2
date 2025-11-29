.text 
SETUP:
                # Mostra o menu (Frame 0)
                la a0,menu
                li a1,0
                li a2,0
                li a3,0
                call PRINT

# Loop esperando qualquer tecla
ESPERA_TECLA:   
                li t1,0xFF200000        # endereço do teclado MMIO
                lw t0,0(t1)             # lê o status do teclado
                andi t0,t0,0x0001       # verifica se há tecla pressionada
                beqz t0,ESPERA_TECLA    # se não há tecla, continua esperando
                lw t2,4(t1)             # lê a tecla pressionada
                
                # Tela de transição
                la a0,pushbutton
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                
                # Espera
                li a0,70000
                call DELAY
                
                # Tela preta
                la a0,blackscreen
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                
                # Espera
                li a0,30000
                call DELAY
                
                # Historia
                la a0,historia
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                
                # Espera
                li a0,100000
                call DELAY
                
                # Mapa spawn
                la a0,spawn
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                
                # Inicializa variáveis do jogo
                li s0,160           # X do personagem
                li s1,120           # Y do personagem
                li s2,0             # Offset X sprite (Frame atual)
                li s3,0             # Offset Y sprite (Direção)
                li s4,0             # Contador animação
                li s5,0             # Estado: 0=movimento, 1=ataque
                li s6,0             # Contador de frames do ataque
                li s11,0            # CONTROLE DE BUFFER (0 ou 1)
                
                j GAME_LOOP

# Loop principal do jogo
GAME_LOOP:
                # 1. INVERTE O BUFFER (prepara o frame oculto)
                li t0,1
                xor s11,s11,t0      # Alterna entre 0 e 1
                
                # 2. Desenha TUDO no frame OCULTO antes de mostrar
                la a0,spawn
                li a1,0 
                li a2,0 
                mv a3,s11           # Desenha no frame que será mostrado
                call PRINT
                
                # 3. Escolhe sprite baseado no estado
                li t0,0
                bne s5,t0,DESENHA_ATAQUE
                
DESENHA_MOVIMENTO:
                la a0,knight_movement
                mv a1,s0            # X
                mv a2,s1            # Y
                mv a4,s2            # frame sprite
                mv a5,s3            # animação sprite
                mv a3,s11           # Desenha no mesmo frame
                call PRINT_SPRITE
                j APOS_DESENHO
                
DESENHA_ATAQUE:
                la a0,knight_attack
                mv a1,s0            # X
                mv a2,s1            # Y
                mv a4,s2            # frame sprite
                mv a5,s3            # animação sprite
                mv a3,s11           # Desenha no mesmo frame
                call PRINT_SPRITE
                
APOS_DESENHO:
                # 4. AGORA SIM TROCA O BUFFER (mostra tudo de uma vez)
                li t0,0xFF200604    # Endereço de troca de frame
                sw s11,0(t0)        # Efetua a troca
                
                # 5. Lê input
                call LER_TECLA
                
                # 6. Atualiza animação baseado no estado
                li t0,0
                bne s5,t0,ANIMA_ATAQUE
                
                # Animação de movimento
                addi s4,s4,1
                li t0,10            # Velocidade ajustada (maior = mais lento)
                blt s4,t0,SKIP_ANIM
                
                li s4,0             # Reseta timer
                addi s2,s2,26       # Próximo frame
                
                # Limite de frames baseado na direção
                li t0,104           # Limite padrão: 4 frames (26*4=104) para Esquerda/Direita
                li t5,36            # linha 36 (segunda linha da sprite sheet)
                bne s3,t5,CHECK_LIMIT
                li t0,104           # Cima/Baixo também tem 4 frames (26*4=104)

CHECK_LIMIT:    
                blt s2,t0,SKIP_ANIM
                li s2,0             # Reinicia animação
                j SKIP_ANIM
                
ANIMA_ATAQUE:
                # Animação de ataque (mais rápida)
                addi s4,s4,1
                li t0,7             # Ataque um pouco mais rápido que movimento
                blt s4,t0,SKIP_ANIM
                
                li s4,0
                addi s2,s2,26       # Próximo frame
                addi s6,s6,1        # Incrementa contador de ataque
                
                # Verifica limite do ataque (assumindo 4 frames)
                li t0,104
                blt s2,t0,CHECK_FIM_ATAQUE
                li s2,0
                
CHECK_FIM_ATAQUE:
                # Após completar animação, volta ao movimento
                li t0,4             # 4 frames de ataque
                blt s6,t0,SKIP_ANIM
                
                li s5,0             # Volta ao estado de movimento
                li s6,0             # Reseta contador de ataque
                li s2,0             # Reseta frame 
                
SKIP_ANIM:
                
                # 7. Delay (ajustado para evitar piscar)
                li a0,1500           # Aumentado para dar tempo do buffer processar
                call DELAY
                
                j GAME_LOOP

# Lê tecla e move personagem
LER_TECLA:
                li t1,0xFF200000
                lw t0,0(t1)
                andi t0,t0,0x0001
                beqz t0,FIM_LER_TECLA
                
                lw t2,4(t1)         # lê código da tecla
                
                # Verifica se está atacando (bloqueia movimento durante ataque)
                li t0,1
                beq s5,t0,CHECK_ATAQUE_ONLY
                
                # W (119) - cima
                li t3,119
                beq t2,t3,MOVE_CIMA
                
                # A (97) - esquerda
                li t3,97
                beq t2,t3,MOVE_ESQUERDA
                
                # S (115) - baixo
                li t3,115
                beq t2,t3,MOVE_BAIXO
                
                # D (100) - direita
                li t3,100
                beq t2,t3,MOVE_DIREITA
                
CHECK_ATAQUE_ONLY:
                # J (106) ou Espaço (32) - ataque
                li t3,106
                beq t2,t3,INICIA_ATAQUE
                
                li t3,32
                beq t2,t3,INICIA_ATAQUE
                
                j FIM_LER_TECLA

MOVE_CIMA:
                addi s1,s1,-2
                li s3,0             # Sprite linha 0 (primeira linha)
                j FIM_LER_TECLA

MOVE_BAIXO:
                addi s1,s1,2
                li s3,0             # Sprite linha 0 (primeira linha)
                j FIM_LER_TECLA

MOVE_ESQUERDA:
                addi s0,s0,-2
                li s3,36            # Sprite linha 36 (segunda linha)
                j FIM_LER_TECLA

MOVE_DIREITA:
                addi s0,s0,2
                li s3,36            # Sprite linha 36 (segunda linha)
                j FIM_LER_TECLA

INICIA_ATAQUE:
                # Só inicia se não estiver atacando
                li t0,1
                beq s5,t0,FIM_LER_TECLA
                
                li s5,1             # Estado de ataque
                li s2,0             # Reseta animação
                li s6,0             # Reseta contador
                j FIM_LER_TECLA

FIM_LER_TECLA:
                ret

#
# PRINT_SPRITE - Imprime sprite com offset
#
PRINT_SPRITE:
                # Calcula endereço do bitmap
                li t0,0xFF0
                add t0,t0,a3        # Soma o frame atual
                slli t0,t0,20       # 0xFF000000 ou 0xFF100000
                
                add t0,t0,a1        # + X
                li t1,320
                mul t1,t1,a2
                add t0,t0,t1        # + (Y * 320)
                
                # Setup Sprite
                lw t4,0(a0)         # largura total da sprite sheet
                lw t5,4(a0)         # altura total da sprite sheet
                
                # ========================================
                # AJUSTE AQUI O TAMANHO DE CADA FRAME:
                # ========================================
                li t6,26            # LARGURA de cada frame individual
                li s7,26            # ALTURA de cada frame individual
                # ========================================
                # Para calcular:
                # - Se sprite sheet é 130x72 com 5 frames: 130/5 = 26 pixels cada
                # - Se tem 2 linhas: 72/2 = 36 pixels de altura cada
                # ========================================
                
                # Calcula posição inicial no sprite sheet
                addi t1,a0,8        # início dos dados
                mul t2,a5,t4        # offset Y * largura total
                add t2,t2,a4        # + offset X
                add t1,t1,t2        # posição inicial
                
                # Desenha sprite
                mv t2,zero          # contador linha
                mv t3,zero          # contador coluna
                
SPRITE_LINHA:
                lbu a6,0(t1)        # Lê pixel
                
                # Verifica transparência (199 = magenta)
                li s8,199
                beq a6,s8,SKIP_PIXEL
                
                sb a6,0(t0)         # Desenha pixel
                
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
                blt t2,s7,SPRITE_LINHA
                
                ret

#
# PRINT - Fundo
#
PRINT:          li t0,0xFF0 
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
        
PRINT_LINHA:    lw t6,0(t1)
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
# DELAY
#
DELAY:          li t0,5000              .data
# ==============================================================
# DADOS (COM ALINHAMENTO PARA EVITAR CRASH)
# ==============================================================
.align 2
CHAR_POS:       .half 160,120           # x, y do personagem
OLD_CHAR_POS:   .half 160,120           # x, y anterior
CHAR_STATE:     .byte 0                 # 0=movimento, 1=ataque
ANIM_FRAME:     .byte 0                 # frame atual
ANIM_COUNTER:   .byte 0                 # contador velocidade
ATTACK_COUNTER: .byte 0                 # contador ataque
CURRENT_MAP:    .byte 0                 # 0=spawn, 1=mobs, 2=finalboss

# Constantes de Colisão
.align 2
TREE_LIMIT_Y:   .word 50    
RIVER_START_X:  .word 128   
RIVER_END_X:    .word 192   
BRIDGE_START_Y: .word 108   
BRIDGE_END_Y:   .word 138   

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
                li t1,0xFF200000
                lw t0,0(t1)
                andi t0,t0,0x0001
                beqz t0,ESPERA_TECLA
                lw t2,4(t1)
                
                # Sequência de Telas
                la a0,pushbutton
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                li a0,70000
                call DELAY
                
                la a0,blackscreen
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                li a0,30000
                call DELAY
                
                la a0,historia
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                li a0,100000
                call DELAY
                
                # Desenha mapa inicial nos dois frames
                la a0,spawn
                li a1,0
                li a2,0
                li a3,0
                call PRINT
                li a3,1
                call PRINT
                
                li s0,0             # Frame atual
                
                j GAME_LOOP

# ===============================================
# GAME LOOP
# ===============================================
GAME_LOOP:
                call KEY2           # Lê teclado
                
                xori s0,s0,1        # Inverte frame
                
                call UPDATE_ANIMATION
                
                # Desenha o mapa correto baseado em CURRENT_MAP
                la t0,CURRENT_MAP
                lbu t1,0(t0)
                
                li t2,0
                beq t1,t2,DRAW_MAP_SPAWN
                li t2,1
                beq t1,t2,DRAW_MAP_MOBS
                li t2,2
                beq t1,t2,DRAW_MAP_FINAL
                
DRAW_MAP_SPAWN:
                la a0,spawn
                j CONTINUE_DRAW
                
DRAW_MAP_MOBS:
                la a0,overworld_mobs
                j CONTINUE_DRAW
                
DRAW_MAP_FINAL:
                la a0,overworld_finalboss
                
CONTINUE_DRAW:
                li a1,0
                li a2,0
                mv a3,s0
                call PRINT
                
                la t0,CHAR_POS
                lh a1,0(t0)         # x
                lh a2,2(t0)         # y
                
                la t1,CHAR_STATE
                lbu t2,0(t1)
                li t3,0
                beq t2,t3,DRAW_MOVEMENT
                
DRAW_ATTACK:
                la a0,knight_attack
                j DRAW_SPRITE
                
DRAW_MOVEMENT:
                la a0,knight_movement
                
DRAW_SPRITE:
                mv a3,s0            # Frame atual
                call PRINT_SPRITE_ANIM
                
                # Troca o buffer
                li t0,0xFF200604
                sw s0,0(t0)
                
                # Delay (Velocidade do jogo)
                li a0,630     
                call DELAY          
                
                j GAME_LOOP

# ===============================================
# UPDATE_ANIMATION
# ===============================================
UPDATE_ANIMATION:
                la t0,ANIM_COUNTER
                lbu t1,0(t0)
                addi t1,t1,1
                
                la t2,CHAR_STATE
                lbu t3,0(t2)
                li t4,15            # Velocidade movimento
                beq t3,zero,CHECK_ANIM_SPEED
                li t4,10            # Velocidade ataque
                
CHECK_ANIM_SPEED:
                blt t1,t4,SKIP_ANIM_UPDATE
                
                li t1,0
                sb t1,0(t0)         # Reseta contador
                
                la t0,ANIM_FRAME
                lbu t1,0(t0)
                addi t1,t1,1
                
                li t2,5
                blt t1,t2,SAVE_FRAME
                li t1,0
                
                la t3,CHAR_STATE
                lbu t4,0(t3)
                beqz t4,SAVE_FRAME
                
                la t5,ATTACK_COUNTER
                lbu t6,0(t5)
                addi t6,t6,1
                sb t6,0(t5)
                
                li t2,1
                blt t6,t2,SAVE_FRAME
                
                li t6,0
                sb t6,0(t5)
                li t6,0
                sb t6,0(t3)
                
SAVE_FRAME:
                sb t1,0(t0)
                ret
                
SKIP_ANIM_UPDATE:
                sb t1,0(t0)
                ret

# ===============================================
# KEY2 - Leitura do teclado
# ===============================================
KEY2:
                li t1,0xFF200000
                lw t0,0(t1)
                andi t0,t0,0x0001
                beq t0,zero,FIM_KEY
                lw t2,4(t1)
                
                la t0,CHAR_STATE
                lbu t1,0(t0)
                li t3,1
                beq t1,t3,CHECK_ATTACK_KEY
                
                li t0,'w'
                beq t2,t0,CHAR_CIMA
                li t0,'a'
                beq t2,t0,CHAR_ESQ
                li t0,'s'
                beq t2,t0,CHAR_BAIXO
                li t0,'d'
                beq t2,t0,CHAR_DIR
                
CHECK_ATTACK_KEY:
                li t0,'j'
                beq t2,t0,CHAR_ATTACK
                li t0,' '
                beq t2,t0,CHAR_ATTACK
                
FIM_KEY:        ret

# ===============================================
# MOVIMENTOS (COM PROTEÇÃO E TROCA DE MAPA)
# ===============================================
CHAR_ESQ:
                la t0,CHAR_POS
                lh t1,0(t0)         # Carrega X atual
                
                # Verifica PRIMEIRO se está na borda esquerda para voltar mapa
                li t3,6             # Se X <= 6, volta para mapa anterior
                ble t1,t3,PREVIOUS_MAP
                
                # Se não está na borda, move normalmente
                la t1,OLD_CHAR_POS
                lw t2,0(t0)
                sw t2,0(t1)
                
                lh t1,0(t0)
                addi t1,t1,-2
                
                # Proteção de borda (não deixa passar de 2)
                li t3,2
                blt t1,t3,RET_MOVE
                
                sh t1,0(t0)
                ret

PREVIOUS_MAP:
                # Volta para o mapa anterior
                la t0,CURRENT_MAP
                lbu t1,0(t0)
                
                # Se já está no primeiro mapa (spawn), não faz nada
                beqz t1,RET_MOVE
                
                addi t1,t1,-1       # Mapa anterior (2->1, 1->0)
                sb t1,0(t0)
                
                # Reposiciona personagem na DIREITA do mapa anterior
                la t0,CHAR_POS
                li t1,290           # X = 290 (direita)
                sh t1,0(t0)
                
                # Atualiza OLD_CHAR_POS
                la t0,OLD_CHAR_POS
                li t1,290
                sh t1,0(t0)
                
                ret

CHAR_DIR:
                la t0,CHAR_POS
                lh t1,0(t0)         # Carrega X atual
                
                # Verifica PRIMEIRO se está na borda direita para trocar mapa
                li t3,294           # Mudei de 318 para 294 (mais fácil de alcançar)
                bge t1,t3,CHANGE_MAP
                
                # Se não está na borda, move normalmente
                la t1,OLD_CHAR_POS
                lw t2,0(t0)
                sw t2,0(t1)
                
                lh t1,0(t0)
                addi t1,t1,2
                
                # Proteção de borda (não deixa passar de 296)
                li t3,296
                bgt t1,t3,RET_MOVE
                
                sh t1,0(t0)
                ret

CHANGE_MAP:
                # Troca para o próximo mapa
                la t0,CURRENT_MAP
                lbu t1,0(t0)
                
                addi t1,t1,1        # Próximo mapa (0->1, 1->2)
                li t2,3
                blt t1,t2,SAVE_NEW_MAP
                li t1,2             # Se passar de 2, fica em 2
                
SAVE_NEW_MAP:
                sb t1,0(t0)
                
                # Reposiciona personagem na esquerda do novo mapa
                la t0,CHAR_POS
                li t1,10            # X = 10 (esquerda)
                sh t1,0(t0)
                
                # Atualiza OLD_CHAR_POS
                la t0,OLD_CHAR_POS
                li t1,10
                sh t1,0(t0)
                
                ret

CHAR_CIMA:
                la t0,CHAR_POS
                la t1,OLD_CHAR_POS
                lw t2,0(t0)
                sw t2,0(t1)
                
                lh t1,2(t0)
                # Proteção de borda
                li t3,2
                blt t1,t3,RET_MOVE
                
                addi t1,t1,-2
                sh t1,2(t0)
                ret

CHAR_BAIXO:
                la t0,CHAR_POS
                la t1,OLD_CHAR_POS
                lw t2,0(t0)
                sw t2,0(t1)
                
                lh t1,2(t0)
                # Proteção de borda
                li t3,220
                bgt t1,t3,RET_MOVE
                
                addi t1,t1,2
                sh t1,2(t0)
                ret

RET_MOVE:       ret

CHAR_ATTACK:
                la t0,CHAR_STATE
                lbu t1,0(t0)
                bnez t1,FIM_KEY
                
                li t1,1
                sb t1,0(t0)
                
                la t0,ANIM_FRAME
                sb zero,0(t0)
                la t0,ATTACK_COUNTER
                sb zero,0(t0)
                ret

# ===============================================
# PRINT_SPRITE_ANIM
# ===============================================
PRINT_SPRITE_ANIM:
                li t0,0xFF0
                add t0,t0,a3
                slli t0,t0,20
                
                add t0,t0,a1        
                li t1,320
                mul t1,t1,a2
                add t0,t0,t1        
                
                lw t4,0(a0)         
                lw t5,4(a0)         
                
                li t6,26            
                li s7,22            
                
                la s8,ANIM_FRAME
                lbu s9,0(s8)
                li s10,26
                mul s9,s9,s10       
                
                addi t1,a0,8
                add t1,t1,s9        
                
                mv t2,zero
                mv t3,zero
                
SPRITE_LINHA_A:
                lbu a6,0(t1)
                
                li s6,199
                beq a6,s6,SKIP_PIXEL_A
                
                sb a6,0(t0)
                
SKIP_PIXEL_A:
                addi t0,t0,1
                addi t1,t1,1
                addi t3,t3,1
                blt t3,t6,SPRITE_LINHA_A
                
                addi t0,t0,320
                sub t0,t0,t6
                
                sub t1,t1,t6
                add t1,t1,t4
                
                mv t3,zero
                addi t2,t2,1
                blt t2,s7,SPRITE_LINHA_A
                
                ret

# ===============================================
# PRINT
# ===============================================
PRINT:
                li t0,0xFF0 
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
        
PRINT_LINHA:    lw t6,0(t1)
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

# ===============================================
# DELAY
# ===============================================
DELAY:
                li t0,5000
                mul t0,t0,a0
                li t1,0
DELAY_LOOP:
                addi t1,t1,1
                blt t1,t0,DELAY_LOOP
                ret

# ===============================================
# INCLUDES COM ALINHAMENTO (ANTI-CRASH)
# ===============================================
.data 
.include "sprites/tela_menu.s"
.align 2
.include "sprites/pushbutton.s"
.align 2
.include "sprites/blackscreen.s"
.align 2
.include "sprites/historia.s"
.align 2
.include "sprites/overworld_spawn.s"
.align 2
.include "sprites/overworld_mobs.s"
.align 2
.include "sprites/overworld_finalboss.s"
.align 2
.include "sprites/knight_movement.s"
.align 2
.include "sprites/knight_attack.s"
                mul t0,t0,a0            
                li t1,0
DELAY_LOOP:     addi t1,t1,1
                blt t1,t0,DELAY_LOOP
                ret

.data 
.include "sprites/tela_menu.s"
.include "sprites/pushbutton.s"
.include "sprites/blackscreen.s"
.include "sprites/historia.s"
.include "sprites/overworld_spawn.s"
.include "sprites/knight_movement.s"
.include "sprites/knight_attack.s"
