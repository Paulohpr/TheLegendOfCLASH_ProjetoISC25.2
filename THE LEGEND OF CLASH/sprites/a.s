    # player.s  -- RISC-V RV32I
    # Estrutura Player (32-bit ints)
    # Offsets (bytes)
    .section .data
    .align 4

# --- constantes de inicialização ---
INIT_POS_X      = 336
INIT_POS_Y      = 432
INIT_WIDTH      = 48
INIT_HEIGHT     = 48
INIT_DIRECTION  = 0
INIT_HP         = 6        # inteiro; ajuste se preferir ponto flutuante

# --- Player structure layout (24 words = 96 bytes) ---
# pos: x,y,width,height,direction        -> words 0..4
# hitbox: x,y,width,height              -> words 5..8
# tracebox: topLeft.x, topLeft.y, topRight.x, topRight.y,
#           bottomLeft.x, bottomLeft.y, bottomRight.x, bottomRight.y -> words 9..16
# frames: run, attack, cooldown, invincibility, knockback -> words 17..21
# hp -> word 22
# attacks_count -> word 23

# Offsets in bytes
    .equ POS_X,            0*4
    .equ POS_Y,            1*4
    .equ POS_W,            2*4
    .equ POS_H,            3*4
    .equ POS_DIR,          4*4

    .equ HIT_X,            5*4
    .equ HIT_Y,            6*4
    .equ HIT_W,            7*4
    .equ HIT_H,            8*4

    .equ T_TL_X,           9*4
    .equ T_TL_Y,          10*4
    .equ T_TR_X,          11*4
    .equ T_TR_Y,          12*4
    .equ T_BL_X,          13*4
    .equ T_BL_Y,          14*4
    .equ T_BR_X,          15*4
    .equ T_BR_Y,          16*4

    .equ FR_RUN,          17*4
    .equ FR_ATTACK,       18*4
    .equ FR_COOLDOWN,     19*4
    .equ FR_INVINC,       20*4
    .equ FR_KNOCKBACK,    21*4

    .equ HP,              22*4
    .equ ATTACKS_COUNT,   23*4

# Example player instance (you can create vários)
player0:
    .word INIT_POS_X
    .word INIT_POS_Y
    .word INIT_WIDTH
    .word INIT_HEIGHT
    .word INIT_DIRECTION

    .word INIT_POS_X + 12      # hitbox x = pos.x + 12
    .word INIT_POS_Y + 12      # hitbox y
    .word 24                   # hitbox width
    .word 24                   # hitbox height

    .word INIT_POS_X + 9       # topLeft.x
    .word INIT_POS_Y + 24      # topLeft.y
    .word INIT_POS_X + 39      # topRight.x
    .word INIT_POS_Y + 24      # topRight.y
    .word INIT_POS_X + 9       # bottomLeft.x
    .word INIT_POS_Y + 45      # bottomLeft.y
    .word INIT_POS_X + 39      # bottomRight.x
    .word INIT_POS_Y + 45      # bottomRight.y

    .word 0    # frames.run
    .word 0    # frames.attack
    .word 0    # frames.cooldown
    .word 0    # frames.invincibility
    .word 0    # frames.knockback

    .word INIT_HP
    .word 0    # attacks_count

    .text
    .globl player_reset
# -----------------------------------------------------
# player_reset(a0 = player_ptr)
# seta todos valores para o estado inicial
# -----------------------------------------------------
player_reset:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0             # s0 = player_ptr

    # pos
    li t0, INIT_POS_X
    sw t0, (s0 + POS_X)
    li t0, INIT_POS_Y
    sw t0, (s0 + POS_Y)
    li t0, INIT_WIDTH
    sw t0, (s0 + POS_W)
    li t0, INIT_HEIGHT
    sw t0, (s0 + POS_H)
    li t0, INIT_DIRECTION
    sw t0, (s0 + POS_DIR)

    # hitbox
    li t0, INIT_POS_X
    addi t0, t0, 12
    sw t0, (s0 + HIT_X)
    li t0, INIT_POS_Y
    addi t0, t0, 12
    sw t0, (s0 + HIT_Y)
    li t0, 24
    sw t0, (s0 + HIT_W)
    sw t0, (s0 + HIT_H)

    # tracebox
    li t0, INIT_POS_X
    addi t0, t0, 9
    sw t0, (s0 + T_TL_X)
    li t0, INIT_POS_Y
    addi t0, t0, 24
    sw t0, (s0 + T_TL_Y)

    li t0, INIT_POS_X
    addi t0, t0, 39
    sw t0, (s0 + T_TR_X)
    li t0, INIT_POS_Y
    addi t0, t0, 24
    sw t0, (s0 + T_TR_Y)

    li t0, INIT_POS_X
    addi t0, t0, 9
    sw t0, (s0 + T_BL_X)
    li t0, INIT_POS_Y
    addi t0, t0, 45
    sw t0, (s0 + T_BL_Y)

    li t0, INIT_POS_X
    addi t0, t0, 39
    sw t0, (s0 + T_BR_X)
    li t0, INIT_POS_Y
    addi t0, t0, 45
    sw t0, (s0 + T_BR_Y)

    # frames
    li t0, 0
    sw t0, (s0 + FR_RUN)
    sw t0, (s0 + FR_ATTACK)
    sw t0, (s0 + FR_COOLDOWN)
    sw t0, (s0 + FR_INVINC)
    sw t0, (s0 + FR_KNOCKBACK)

    # hp and attacks
    li t0, INIT_HP
    sw t0, (s0 + HP)
    li t0, 0
    sw t0, (s0 + ATTACKS_COUNT)

    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# -----------------------------------------------------
# player_step(a0 = player_ptr)
# Atualiza frames: run, cooldown, knockback, invincibility, attack/attacks array
# -----------------------------------------------------
    .globl player_step
player_step:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0

    # if frames.run <= 0 set to 16
    lw t0, (s0 + FR_RUN)
    blez t0, .set_run_to_16
    j .continue_step
.set_run_to_16:
    li t0, 16
    sw t0, (s0 + FR_RUN)

.continue_step:
    # if cooldown > 0 -> cooldown--
    lw t0, (s0 + FR_COOLDOWN)
    beqz t0, .skip_cd_dec
    addi t0, t0, -1
    sw t0, (s0 + FR_COOLDOWN)
.skip_cd_dec:

    # if knockback > 0 -> knockback--
    lw t0, (s0 + FR_KNOCKBACK)
    beqz t0, .skip_kb_dec
    addi t0, t0, -1
    sw t0, (s0 + FR_KNOCKBACK)
.skip_kb_dec:

    # if invincibility > 0 -> invincibility--
    lw t0, (s0 + FR_INVINC)
    beqz t0, .skip_inv_dec
    addi t0, t0, -1
    sw t0, (s0 + FR_INVINC)
.skip_inv_dec:

    # attack handling: if frames.attack > 0 -> frames.attack-- else if attacks_count>0 attacks_count--
    lw t0, (s0 + FR_ATTACK)
    beqz t0, .attack_zero
    addi t0, t0, -1
    sw t0, (s0 + FR_ATTACK)
    j .done_step
.attack_zero:
    lw t1, (s0 + ATTACKS_COUNT)
    blez t1, .done_step
    addi t1, t1, -1
    sw t1, (s0 + ATTACKS_COUNT)

.done_step:
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# -----------------------------------------------------
# player_setDirection(a0 = player_ptr, a1 = direction_code)
# direction_code: 0 = 'down', 1 = 'left', 2 = 'up', 3 = 'right'
# sets pos.direction to sprite offset mapping:
#   down -> 0
#   left -> 48
#   up -> 96
#   right -> 144
# -----------------------------------------------------
    .globl player_setDirection
player_setDirection:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0
    mv t0, a1

    li t1, 0
    beq t0, zero, .dir_down   # code 0 -> down
    li t1, 48
    beq t0, 1, .dir_left
    li t1, 96
    beq t0, 2, .dir_up
    li t1, 144
    beq t0, 3, .dir_right
    # default
    li t1, 0

.dir_down:
    sw t1, (s0 + POS_DIR)
    j .end_setdir
.dir_left:
    sw t1, (s0 + POS_DIR)
    j .end_setdir
.dir_up:
    sw t1, (s0 + POS_DIR)
    j .end_setdir
.dir_right:
    sw t1, (s0 + POS_DIR)

.end_setdir:
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# -----------------------------------------------------
# player_move(a0 = player_ptr, a1 = dx, a2 = dy, a3 = direction_code)
# aplica movimento e atualiza hitbox e tracebox
# checa hp>0 e cooldown==0; decrementa frames.run
# -----------------------------------------------------
    .globl player_move
player_move:
    addi sp, sp, -24
    sw ra, 20(sp)
    sw s0, 16(sp)
    mv s0, a0
    mv t0, a1    # dx
    mv t1, a2    # dy

    # if hp <= 0 return
    lw t2, (s0 + HP)
    blez t2, .ret_move

    # if cooldown != 0 return
    lw t3, (s0 + FR_COOLDOWN)
    bnez t3, .ret_move

    # frames.run--
    lw t4, (s0 + FR_RUN)
    addi t4, t4, -1
    sw t4, (s0 + FR_RUN)

    # setDirection(a3)
    mv a1, a3
    mv a0, s0
    call player_setDirection

    # pos.x += dx
    lw t5, (s0 + POS_X)
    add t5, t5, t0
    sw t5, (s0 + POS_X)
    # pos.y += dy
    lw t6, (s0 + POS_Y)
    add t6, t6, t1
    sw t6, (s0 + POS_Y)

    # hitbox.x += dx
    lw t7, (s0 + HIT_X)
    add t7, t7, t0
    sw t7, (s0 + HIT_X)
    # hitbox.y += dy
    lw t8, (s0 + HIT_Y)
    add t8, t8, t1
    sw t8, (s0 + HIT_Y)

    # tracebox topLeft
    lw t9, (s0 + T_TL_X)
    add t9, t9, t0
    sw t9, (s0 + T_TL_X)
    lw t9, (s0 + T_TL_Y)
    add t9, t9, t1
    sw t9, (s0 + T_TL_Y)

    # topRight
    lw t9, (s0 + T_TR_X)
    add t9, t9, t0
    sw t9, (s0 + T_TR_X)
    lw t9, (s0 + T_TR_Y)
    add t9, t9, t1
    sw t9, (s0 + T_TR_Y)

    # bottomLeft
    lw t9, (s0 + T_BL_X)
    add t9, t9, t0
    sw t9, (s0 + T_BL_X)
    lw t9, (s0 + T_BL_Y)
    add t9, t9, t1
    sw t9, (s0 + T_BL_Y)

    # bottomRight
    lw t9, (s0 + T_BR_X)
    add t9, t9, t0
    sw t9, (s0 + T_BR_X)
    lw t9, (s0 + T_BR_Y)
    add t9, t9, t1
    sw t9, (s0 + T_BR_Y)

    # (Opcional) chamar rotina de redraw / colisão aqui
    # e.g., call_drawImage or call_redraw_player
    # mv a0, s0
    # call call_drawPlayer

.ret_move:
    lw ra, 20(sp)
    lw s0, 16(sp)
    addi sp, sp, 24
    ret

# -----------------------------------------------------
# player_takeDamage(a0 = player_ptr, a1 = damage)
# se hp<=0 return
# se frames.invincibility == 0:
#   frames.invincibility = 45
#   frames.knockback = 8
#   hp -= damage
#   attacks_count-- (remove last)
#   (placeholder) play sound
# -----------------------------------------------------
    .globl player_takeDamage
player_takeDamage:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0
    mv t0, a1    # damage

    lw t1, (s0 + HP)
    blez t1, .end_takeDamage    # if hp <= 0 return

    lw t2, (s0 + FR_INVINC)
    bnez t2, .end_takeDamage    # if invincibility != 0 return

    # set invincibility = 45, knockback = 8
    li t3, 45
    sw t3, (s0 + FR_INVINC)
    li t3, 8
    sw t3, (s0 + FR_KNOCKBACK)

    # hp -= damage
    sub t1, t1, t0
    sw t1, (s0 + HP)

    # attacks_count-- if >0
    lw t4, (s0 + ATTACKS_COUNT)
    blez t4, .skip_att_dec
    addi t4, t4, -1
    sw t4, (s0 + ATTACKS_COUNT)
.skip_att_dec:

    # placeholder: play hurt sound
    # mv a0, <sound id or pointer>
    # call call_playSound

.end_takeDamage:
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# -----------------------------------------------------
# player_attack(a0 = player_ptr)
# if hp<=0 return
# if frames.cooldown != 0 return
# if frames.knockback != 0 return
# frames.cooldown = 18
# frames.attack = 15
# attacks_count++
# (placeholder) spawn Sword instance
# -----------------------------------------------------
    .globl player_attack
player_attack:
    addi sp, sp, -16
    sw ra, 12(sp)
    sw s0, 8(sp)
    mv s0, a0

    # hp <= 0 ? ret
    lw t0, (s0 + HP)
    blez t0, .end_attack

    # cooldown != 0 ? ret
    lw t1, (s0 + FR_COOLDOWN)
    bnez t1, .end_attack

    # knockback != 0 ? ret
    lw t2, (s0 + FR_KNOCKBACK)
    bnez t2, .end_attack

    li t3, 18
    sw t3, (s0 + FR_COOLDOWN)
    li t3, 15
    sw t3, (s0 + FR_ATTACK)

    # attacks_count++
    lw t4, (s0 + ATTACKS_COUNT)
    addi t4, t4, 1
    sw t4, (s0 + ATTACKS_COUNT)

    # placeholder: spawn Sword (pass player pos, direction)
    # mv a0, s0
    # call call_spawnSword

.end_attack:
    lw ra, 12(sp)
    lw s0, 8(sp)
    addi sp, sp, 16
    ret

# -----------------------------------------------------
# Exemplo minimal de main (chamada de funções)
# -----------------------------------------------------
    .globl main
main:
    # Carrega endereço do player0 em a0 e chama reset
    la a0, player0
    call player_reset

    # Exemplo de uso: mover player dx=4 dy=0 direction=3 (right)
    la a0, player0
    li a1, 4
    li a2, 0
    li a3, 3
    call player_move

    # passo do game loop
    la a0, player0
    call player_step

    # player attack
    la a0, player0
    call player_attack

    # player takes 1 damage
    la a0, player0
    li a1, 1
    call player_takeDamage

    # exit (RARS e similares: ecall 10)
    li a7, 10
    ecall
