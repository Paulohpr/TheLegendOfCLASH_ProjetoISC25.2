.data
# ==============================================================
# DADOS (COM ALINHAMENTO PARA EVITAR CRASH)
# ==============================================================
.align 2
CHAR_POS:       .half 10,120            # x=10, y=120 (SPAWN EM X=10)
OLD_CHAR_POS:   .half 10,120            # x, y anterior
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
                
                # Reposiciona personagem: X=290 (direita), Y mantém
                la t0,CHAR_POS
                lh t2,2(t0)         # Pega Y atual
                li t1,290           # X = 290
                sh t1,0(t0)
                sh t2,2(t0)         # Mantém Y
                
                # Atualiza OLD_CHAR_POS
                la t0,OLD_CHAR_POS
                sh t1,0(t0)
                sh t2,2(t0)
                
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
                
                # Reposiciona personagem: X=10 (esquerda), Y mantém
                la t0,CHAR_POS
                lh t2,2(t0)         # Pega Y atual
                li t1,10            # X = 10
                sh t1,0(t0)
                sh t2,2(t0)         # Mantém Y
                
                # Atualiza OLD_CHAR_POS
                la t0,OLD_CHAR_POS
                sh t1,0(t0)
                sh t2,2(t0)
                
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
                
                # Som de ataque removido temporariamente (causa crash)
                # TODO: Implementar com pitch bend quando RARS suportar
                
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