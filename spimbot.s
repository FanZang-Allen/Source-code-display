
# syscall constants
PRINT_STRING            = 4
PRINT_CHAR              = 11
PRINT_INT               = 1

# memory-mapped I/O
VELOCITY                = 0xffff0010
ANGLE                   = 0xffff0014
ANGLE_CONTROL           = 0xffff0018

BOT_X                   = 0xffff0020
BOT_Y                   = 0xffff0024
GET_OPPONENT_HINT       = 0xffff00ec

TIMER                   = 0xffff001c
ARENA_MAP               = 0xffff00dc

SHOOT_UDP_PACKET        = 0xffff00e0
GET_BYTECOINS           = 0xffff00e4
USE_SCANNER             = 0xffff00e8

REQUEST_PUZZLE          = 0xffff00d0  ## Puzzle
SUBMIT_SOLUTION         = 0xffff00d4  ## Puzzle

BONK_INT_MASK           = 0x1000
BONK_ACK                = 0xffff0060

TIMER_INT_MASK          = 0x8000
TIMER_ACK               = 0xffff006c

REQUEST_PUZZLE_INT_MASK = 0x800       ## Puzzle
REQUEST_PUZZLE_ACK      = 0xffff00d8  ## Puzzle

RESPAWN_INT_MASK        = 0x2000      ## Respawn
RESPAWN_ACK             = 0xffff00f0  ## Respawn

WALL                    = 1
HOST_MASK               = 2
FRIENDLY_MASK           = 4
ENEMY_MASK              = 8
PLAYER_MASK             = 16

.data
### Puzzle
puzzle:     .byte 0:268
solution:   .byte 0:256
#### Puzzle

has_puzzle: .word 0

flashlight_space: .word 0
scanner_wb: .byte 0 0 0 0

.text
main:
    # Construct interrupt mask
    li      $t4, 0
    or      $t4, $t4, BONK_INT_MASK # request bonk
    or      $t4, $t4, REQUEST_PUZZLE_INT_MASK           # puzzle interrupt bit
    or      $t4, $t4, TIMER_INT_MASK
    or      $t4, $t4, RESPAWN_INT_MASK
    or      $t4, $t4, 1 # global enable
    mtc0    $t4, $12

    #Fill in your code here
    lw      $t0, BOT_X($0)
    li      $t1, 4
    bne     $t0, $t1, right_corner
left_corner:
    li      $a0, 1
    li      $a1, 2
    jal		shift
    li      $a0, 7
    li      $a1, 7
    jal		shift
    li      $a0, 7
    li      $a1, 8
    jal		shift
    j       move_loop
right_corner:
    li      $a0, 36
    li      $a1, 33
    jal		shift
    li      $a0, 24
    li      $a1, 25
    jal		shift
    li      $a0, 17
    li      $a1, 14
    jal		shift
move_loop:
    jal     firstpart
    jal     secondpart
    jal     thirdpart
    jal     fourthpart
    j       move_loop
infinite:
    j infinite

# void scan_(*scanner_wb, angle) 
scan_:
    sub     $sp, $sp, 12
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)
    sw      $a1, 8($sp)
    li      $t0, 1
    move    $t9, $a1
scanner_for:
    sw      $t9, ANGLE($0)   
    sw      $t0, ANGLE_CONTROL($0) # set angle
    lw      $t4, GET_BYTECOINS($0)
    li      $t5, 2
    bge     $t4, $t5, enough_scan
    jal     earn_point
enough_scan:
    lw      $a0, 4($sp)
    sw      $a0, USE_SCANNER($0)  # use scanner
    lb      $t1, 2($a0)
    and     $t7, $t1, PLAYER_MASK
    and     $t6, $t1, ENEMY_MASK
    bne     $t6, $0, shoot_twice
    and     $t3, $t1, FRIENDLY_MASK
    and     $t2, $t1, HOST_MASK
    beq     $t2, $0, done_shoot
    bne     $t3, $0, done_shoot
shoot_:
    lw      $t4, GET_BYTECOINS($0)
    li      $t5, 50
    bge     $t4, $t5, enough_shoot
    jal     earn_point
    j       enough_shoot
shoot_twice:
    lw      $t4, GET_BYTECOINS($0)
    li      $t5, 100
    bge     $t4, $t5, enough_shoot_twice
    jal     earn_point  # earn 50 points
    jal     earn_point  # earn 50 points
    j       enough_shoot_twice
enough_shoot:
    sw      $0, SHOOT_UDP_PACKET($0)
    j       done_shoot
enough_shoot_twice:
    sw      $0, SHOOT_UDP_PACKET($0)
    sw      $0, SHOOT_UDP_PACKET($0)
done_shoot:
    lw      $ra, 0($sp)
    lw      $a0, 4($sp)
    lw      $a1, 8($sp)
    add     $sp, $sp, 12
    jr      $ra

# void scanner(*address, angle)
# scanner:
#     sub     $sp, $sp, 12
#     sw      $ra, 0($sp)
#     sw      $a0, 4($sp)
#     sw      $a1, 8($sp)
#     sw      $0, VELOCITY($0)  #stop
#     li      $t0, 1
#     move    $t9, $a1
#     li      $t8, 360
# scanner_for:
#     bgt     $t9, $t8, done_scanner
#     sw      $t9, ANGLE($0)
#     sw      $t0, ANGLE_CONTROL($0) #set angle
#     lw      $t4, GET_BYTECOINS($0)
#     li      $t5, 2
#     bge     $t4, $t5, enough_scan
#     jal     earn_point
# enough_scan:
#     lw      $a0, 4($sp)
#     sw      $a0, USE_SCANNER($0)  #use scanner
#     lb      $t1, 2($a0)
#     and     $t7, $t1, PLAYER_MASK
#     and     $t6, $t1, ENEMY_MASK
#     bne     $t6, $0, shoot_
#     and     $t3, $t1, FRIENDLY_MASK
#     and     $t2, $t1, HOST_MASK
#     beq     $t2, $0, done_shoot
#     bne     $t3, $0, done_shoot
# shoot_:
#     lw      $t4, GET_BYTECOINS($0)
#     li      $t5, 50
#     bge     $t4, $t5, enough_shoot
#     jal     earn_point
# enough_shoot:
#     sw      $0, SHOOT_UDP_PACKET($0)
# done_shoot:
#     add     $t9, $t9, 5
#     j       scanner_for
# done_scanner:
#     lw      $ra, 0($sp)
#     lw      $a0, 4($sp)
#     lw      $a1, 8($sp)
#     add     $sp, $sp, 12
#     jr      $ra

# void shift(target_x, target_y)
shift:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    lw      $t0, BOT_X($0)   #t0 = current x
    lw      $t1, BOT_Y($0)   #t1 = current y
    mul     $t2, $a0, 8
    addi    $t2, $t2, 4
    mul     $t3, $a1, 8
    addi    $t3, $t3, 4
    li      $t9, 1
    li      $t6, 10
shift_x:
    beq     $t2, $t0, shift_y
    bgt		  $t2, $t0, shift_right	# if target_x > current_X then shift_right
shift_left:
    li      $t4, 180
    sw      $t4, ANGLE($0)
    sw      $t9, ANGLE_CONTROL($0)
    lw      $t4, VELOCITY($0)
    add     $t4, $t4, 10
    sw      $t4, VELOCITY($0)
continue_left:
    lw      $t5, BOT_X($0)
    lw      $t4, VELOCITY($0)
    bne     $t4, $t6, skip_shift
    bne     $t5, $t2, continue_left
    li      $t4, 0
    sw      $t4, VELOCITY($0)
    j       shift_y      #continue shifting
shift_right:
    li      $t4, 0
    sw      $t4, ANGLE($0)
    sw      $t9, ANGLE_CONTROL($0)
    lw      $t4, VELOCITY($0)
    add     $t4, $t4, 10
    sw      $t4, VELOCITY($0)
continue_right:
    lw      $t5, BOT_X($0)
    lw      $t4, VELOCITY($0)
    bne     $t4, $t6, skip_shift
    bne     $t5, $t2, continue_right
    li      $t4, 0
    sw      $t4, VELOCITY($0)
    j       shift_y      #continue shifting
shift_y:
    beq     $t3, $t1, done_shift
    bgt     $t3, $t1, shift_down # if target_y > current_y then shift_down
shift_up:
    li      $t4, 270
    sw      $t4, ANGLE($0)
    sw      $t9, ANGLE_CONTROL($0)
    lw      $t4, VELOCITY($0)
    add     $t4, $t4, 10
    sw      $t4, VELOCITY($0)
continue_up:
    lw      $t5, BOT_Y($0)
    lw      $t4, VELOCITY($0)
    bne     $t4, $t6, skip_shift
    bne     $t5, $t3, continue_up
    li      $t4, 0
    sw      $t4, VELOCITY($0)
    j       done_shift     #continue shifting
shift_down:
    li      $t4, 90
    sw      $t4, ANGLE($0)
    sw      $t9, ANGLE_CONTROL($0)
    lw      $t4, VELOCITY($0)
    add     $t4, $t4, 10
    sw      $t4, VELOCITY($0)
continue_down:
    lw      $t5, BOT_Y($0)
    lw      $t4, VELOCITY($0)
    bne     $t4, $t6, skip_shift
    bne     $t5, $t3, continue_down
    li      $t4, 0
    sw      $t4, VELOCITY($0)
    j       done_shift     #continue shifting
done_shift:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    li      $v0, 1
    jr      $ra
skip_shift:
    jal     return
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    li      $v0, 0
    jr      $ra

# void earn_point() {
earn_point:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    la		$t0, puzzle
    sw      $t0, REQUEST_PUZZLE
load_puzzle:
    la      $t3, puzzle
    lw      $t1, 0($t3)
    beq     $t1, $0, load_puzzle
start:
    la      $a0, puzzle
    la      $a1, solution
    li      $a2, 0
    li      $a3, 0
    jal     solve   #solve board

    la		$t2, solution
    sw      $t2, SUBMIT_SOLUTION    #submit

    la      $a2, puzzle
    lw      $a0, 0($a2)
    lw      $a1, 4($a2)
    li      $t4, 0
    sw      $t4, 0($a2)      #clear row col
    sw      $t4, 4($a2)
    la      $a2, solution
    jal     solver_zero_board   # clear solution
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

# void shoot(int angle)
shoot:
    li      $t0, 1
    sw      $a0, ANGLE($0)
    sw      $t0, ANGLE_CONTROL($0)
    sw      $0, SHOOT_UDP_PACKET($0)
    jr      $ra


# void firstpart()
firstpart:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    li      $a0, 14
    li      $a1, 14
    jal     shift      #first host
    beq     $v0, $0, skip_first_part
    la      $a0, scanner_wb
    li      $a1, 0
    jal     scan_
    li      $a0, 14
    li      $a1, 9
    jal     shift
    beq     $v0, $0, skip_first_part
    li      $a0, 6
    li      $a1, 9
    jal     shift
    beq     $v0, $0, skip_first_part
    la      $a0, scanner_wb
    li      $a1, 290
    jal     scan_       #second host
    li      $a0, 6
    li      $a1, 13
    jal     shift
    beq     $v0, $0, skip_first_part
    jal     earn_point
    la      $a0, scanner_wb
    li      $a1, 180
    jal     scan_       #third host
    li      $a0, 6
    li      $a1, 6
    jal     shift
    beq     $v0, $0, skip_first_part
    li      $a0, 15
    li      $a1, 6
    jal     shift
    beq     $v0, $0, skip_first_part
    la      $a0, scanner_wb
    li      $a1, 220
    jal     scan_      #fourth host
    li      $a0, 15
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_first_part
    li      $a0, 17
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_first_part
skip_first_part:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

# void secondpart()
secondpart:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    li      $a0, 24
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_second_part
    li      $a0, 24
    li      $a1, 13
    jal     shift
    beq     $v0, $0, skip_second_part
    la      $a0, scanner_wb
    li      $a1, 330
    jal     scan_      #first
    li      $a0, 28
    li      $a1, 6
    jal     shift
    beq     $v0, $0, skip_second_part
    la      $a0, scanner_wb
    li      $a1, 0
    jal     scan_       #second
    la      $a0, scanner_wb
    li      $a1, 250
    jal     scan_       #third
    li      $a0, 33
    li      $a1, 11
    jal     shift
    beq     $v0, $0, skip_second_part
    la      $a0, scanner_wb
    li      $a1, 20
    jal     scan_      #fourth
    li      $a0, 25
    li      $a1, 13
    jal     shift
    beq     $v0, $0, skip_second_part
    li      $a0, 24
    li      $a1, 13
    jal     shift
    beq     $v0, $0, skip_second_part
    li      $a0, 24
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_second_part
    li      $a0, 17
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_second_part
skip_second_part:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

# void thirdpart()
thirdpart:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    li      $a0, 14
    li      $a1, 24
    jal     shift
    beq     $v0, $0, skip_third_part
    li      $a0, 13
    li      $a1, 24
    jal     shift
    beq     $v0, $0, skip_third_part
    la      $a0, scanner_wb
    li      $a1, 110
    jal     scan_     #first
    li      $a0, 13
    li      $a1, 28
    jal     shift
    beq     $v0, $0, skip_third_part
    li      $a0, 6
    li      $a1, 28
    jal     shift
    beq     $v0, $0, skip_third_part
    la      $a0, scanner_wb
    li      $a1, 210
    jal     scan_      #second
    la      $a0, scanner_wb
    li      $a1, 90
    jal     scan_      #third
    li      $a0, 11
    li      $a1, 33
    jal     shift
    beq     $v0, $0, skip_third_part
    la      $a0, scanner_wb
    li      $a1, 70
    jal     scan_      #fourth
    li      $a0, 11
    li      $a1, 25
    jal     shift
    beq     $v0, $0, skip_third_part
    li      $a0, 13
    li      $a1, 24
    jal     shift
    beq     $v0, $0, skip_third_part
    li      $a0, 17
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_third_part
skip_third_part:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

#void fourthpart()
fourthpart:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    li      $a0, 17
    li      $a1, 25
    jal     shift
    beq     $v0, $0, skip_fourth_part
    li      $a0, 25
    li      $a1, 25
    jal     shift
    beq     $v0, $0, skip_fourth_part
    la      $a0, scanner_wb
    li      $a1, 0
    jal     scan_       #first
    li      $a0, 31
    li      $a1, 32
    jal     shift
    beq     $v0, $0, skip_fourth_part
    la      $a0, scanner_wb
    li      $a1, 0
    jal     scan_      #second
    li      $a0, 33
    li      $a1, 29
    jal     shift
    beq     $v0, $0, skip_fourth_part
    la      $a0, scanner_wb
    li      $a1, 290
    jal     scan_      #third
    li      $a0, 24
    li      $a1, 33
    jal     shift
    beq     $v0, $0, skip_fourth_part
    la      $a0, scanner_wb
    li      $a1, 30
    jal     scan_       #fourth
    li      $a0, 24
    li      $a1, 25
    jal     shift
    beq     $v0, $0, skip_fourth_part
    li      $a0, 17
    li      $a1, 14
    jal     shift
    beq     $v0, $0, skip_fourth_part
skip_fourth_part:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

#void return()
return:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
    lw      $t0, BOT_X($0)   #t0 = current x
    lw      $t1, BOT_Y($0)   #t1 = current y
    li      $t2, 164
    bgt     $t1, $t2, third_fourth  # if  >  then

first_second:
    bgt     $t0, $t2, second  # if  >  then
    move    $a0, $t0
    move    $a1, $t1
    jal     firstpart_return
    j       return_finish
second:
    move    $a0, $t0
    move    $a1, $t1
    jal     secondpart_return
    j       return_finish

third_fourth:
    bgt     $t0, $t2, fourth  # if  >  then
    move    $a0, $t0
    move    $a1, $t1
    jal     thirdpart_return
    j       return_finish
fourth:
    move    $a0, $t0
    move    $a1, $t1
    jal     fourthpart_return

return_finish:
    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra


# inner host: The inmost host in each area
# mid   host: the host in middle in the three hosts left
# left  host: The host in the left in the two hosts left
# right  host: The host in the right in the two hosts left

#void firstpart_return(*BOT_X, *BOT_Y)
firstpart_return:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

# see which host in the first part
    li      $t0, 84
    ble     $a1, $t0, mid_right1
    ble     $a0, $t0, left_host1
    j       inner_host1

mid_right1:
    ble     $a0, $t0, mid_host1
    j       right_host1

    ##### return instrction for each host in detail #####
right_host1:
    li      $a0, 15
    li      $a1, 14
    jal     shift
    j       inner_host1

left_host1:
    li      $a0, 5
    li      $a1, 15
    jal     shift
    li      $a0, 14
    li      $a1, 14
    jal     shift
    j       inner_host1

mid_host1:
    li      $a0, 10
    li      $a1, 11
    jal     shift
# at this point, mid host following operation is same as inner host
# no need for jump

inner_host1:
    li      $a0, 17
    li      $a1, 14
    jal     shift

    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra


#void secondpart_return(*BOT_X, *BOT_Y)
secondpart_return:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)

# see which host in the second part
    li      $t0, 84
    li      $t1, 244
    ble     $a1, $t0, mid_left2
    ble     $a0, $t1, inner_host2
    j       right_host2
mid_left2:
    ble     $a0, $t1, left_host2
    j       mid_host2

    #####return instrction for each host in detail#####
right_host2:
    li      $a0, 38
    li      $a1, 6
    jal     shift
    j       mid_host2
# at this point, right host following operation is same as mid host
left_host2:
    li      $a0, 27
    li      $a1, 6
    jal     shift
# at this point, left host following operation is same as mid host
# no need for jump
mid_host2:
    li      $a0, 28
    li      $a1, 12
    jal     shift
# at this point, mid host following operation is same as inner host
# no need for jump
inner_host2:
    li      $a0, 26
    li      $a1, 15
    jal     shift
    li      $a0, 17
    li      $a1, 14
    jal     shift

    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra

#void thirdpart_return(*BOT_X, *BOT_Y)
thirdpart_return:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
# see which host in the first part
    li      $t0, 84
    li      $t1, 244
    ble     $a0, $t0, left_mid3
    ble     $a1, $t1, inner_host3
    j       right_host3

left_mid3:
    ble     $a1, $t1, left_host3
    j       mid_host3
    ##### return instrction for each host in detail #####

right_host3:
    li      $a0, 12
    li      $a1, 34
    jal     shift
    j       mid_host3

left_host3:
    li      $a0, 1
    li      $a1, 33
    jal     shift
mid_host3:
    li      $a0, 11
    li      $a1, 27
    jal     shift

inner_host3:
    li      $a0, 13
    li      $a1, 24
    jal     shift
    li      $a0, 17
    li      $a1, 14
    jal     shift

    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra



#void fourthpart_return(*BOT_X, *BOT_Y)
fourthpart_return:
    sub     $sp, $sp, 4
    sw      $ra, 0($sp)
# see which host in the second part
    li      $t0, 244
    ble     $a0, $t0, inner_left4
    ble     $a1, $t0, right_host4
    j       mid_host4
inner_left4:
    ble     $a1, $t0, inner_host4
    j       left_host4
      #####return instrction for each host in detail#####

left_host4:
    li      $a0, 24
    li      $a1, 25
    jal     shift
    j       inner_host4

right_host4:
    li      $a0, 33
    li      $a1, 32
    jal     shift

mid_host4:
    li      $a0, 30
    li      $a1, 25
    jal     shift

inner_host4:
    li      $a0, 17
    li      $a1, 14
    jal     shift

    lw      $ra, 0($sp)
    add     $sp, $sp, 4
    jr      $ra



# void toggle_light(int row, int col, LightsOut* puzzle, int action_num){
#     int num_rows = puzzle->num_rows;
#     int num_cols = puzzle->num_cols;
#     int num_colors = puzzle->num_colors;
#     unsigned char* board = (puzzle-> board);
#     board[row*num_cols + col] = (board[row*num_cols + col] + action_num) % num_colors;
#     if (row > 0){
#         board[(row-1)*num_cols + col] = (board[(row-1)*num_cols + col] + action_num) % num_colors;
#     }
#     if (col > 0){
#         board[(row)*num_cols + col-1] = (board[(row)*num_cols + col-1] + action_num) % num_colors;
#     }
#
#     if (row < num_rows - 1){
#         board[(row+1)*num_cols + col] = (board[(row+1)*num_cols + col] + action_num) % num_colors;
#     }
#
#     if (col < num_cols - 1){
#         board[(row)*num_cols + col+1] = (board[(row)*num_cols + col+1] + action_num) % num_colors;
#     }
# }

.globl toggle_light
toggle_light:
    ## Variables corresponding to registers:

    ##
    ##    $t6 = tmp_var
    ##    $t5 = array_index
    ##    $t3 = board
    ##    $t4 = cond_var
    ##    $t2 = num_colors
    ##    $t1 = num_cols
    ##    $t0 = num_rows
    ##    $a3 = action_num
    ##    $a2 = puzzle
    ##    $a1 = col
    ##    $a0 = row
    ##
    ## End aliases



        # assign  $t0   = *0($a2)
        lw      $t0, 0($a2)
        # assign  $t1   = *4($a2)
        lw      $t1, 4($a2)
        # assign  $t2 = *8($a2)
        lw      $t2, 8($a2)
        # assign  $t3   = 12($a2)
        add      $t3, $a2, 12

        # assign  $t5 = $t3&[$a0 * $t1 + $a1]
        mul     $t5, $a0, $t1
        add     $t5, $t5, $a1
        add     $t5, $t5, $t3
        # assign  $t6 = (*::($t5) + $a3) % $t2
        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        div     $t6, $t2
        mfhi    $t6
        # assign  $t6 =>:: $t5
        sb      $t6, 0($t5)

    toggle_light_row_greater_if:
        ble     $a0, $0, toggle_light_col_greater_if

        # assign  $t5 = $t3&[($a0 - 1) * $t1 + $a1]
        addi    $t5, $a0, -1
        mul     $t5, $t5, $t1
        add     $t5, $t5, $a1
        add     $t5, $t5, $t3
        # assign  $t6 = (*::($t5) + $a3) % $t2
        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        div     $t6, $t2
        mfhi    $t6
        # assign  $t6 =>:: $t5
        sb      $t6, 0($t5)

    toggle_light_col_greater_if:
        ble     $a1, $0, toggle_light_row_less_if

        # assign  $t5 = $t3&[($a0) * $t1 + $a1 - 1]
        mul     $t9, $a0, $t1
        add     $t9, $t9, $a1
        addi    $t5, $t9, -1
        add     $t5, $t5, $t3
        # assign  $t6 = (*::($t5) + $a3) % $t2
        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        div     $t6, $t2
        mfhi    $t6
        # assign  $t6 =>:: $t5
        sb      $t6, 0($t5)

    toggle_light_row_less_if:
        # assign  $t4 = $t0 - 1
        addi    $t4, $t0, -1
        bge     $a0, $t4, toggle_light_col_less_if

        # assign  $t5 = $t3&[($a0 + 1) * $t1 + $a1]
        addi    $t5, $a0, 1
        mul     $t5, $t5, $t1
        add     $t5, $t5, $a1
        add     $t5, $t5, $t3
        # assign  $t6 = (*::($t5) + $a3) % $t2
        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        div     $t6, $t2
        mfhi    $t6
        # assign  $t6 =>:: $t5
        sb      $t6, 0($t5)

    toggle_light_col_less_if:
        # assign  $t4 = $t1 - 1
        addi    $t4, $t1, -1
        bge     $a1, $t4, toggle_light_end

        # assign  $t5 = $t3&[($a0) * $t1 + $a1 + 1]
        mul     $t5, $a0, $t1
        add     $t5, $t5, $a1
        addi    $t5, $t5, 1
        add     $t5, $t5, $t3
        # assign  $t6 = (*::($t5) + $a3) % $t2
        lbu     $t6, 0($t5)
        add     $t6, $t6, $a3
        div     $t6, $t2
        mfhi    $t6
        # assign  $t6 =>:: $t5
        sb      $t6, 0($t5)

    toggle_light_end:
    jr      $ra


# const int MAX_GRIDSIZE = 16;
# struct LightsOut {
#     int num_rows;
#     int num_cols;
#     int num_color;
#     unsigned char board[MAX_GRIDSIZE*MAX_GRIDSIZE];
#     bool clue[MAX_GRIDSIZE*MAX_GRIDSIZE]; //(using bytes in SpimBot)
#     };

# bool solve(LightsOut* puzzle, unsigned char* solution, int row, int col){
#     int num_rows = puzzle->num_rows;
#     int num_cols = puzzle->num_cols;
#     int num_colors = puzzle->num_colors;
#     int next_row = ((col == num_cols-1) ? row + 1 : row);
#     if (row >= num_rows || col >= num_cols) {
#          return board_done(num_rows,num_cols,puzzle->board);
#     }
#     if (row != 0) {
#         int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
#         solution[row*num_cols + col] = actions;
#         toggle_light(row, col, puzzle, actions);
#         if (solve(puzzle,solution, next_row, (col + 1) % num_cols)) {
#             return true;
#         }
#         solution[row*num_cols + col] = 0;
#         toggle_light(row, col, puzzle, num_colors - actions);
#         return false;
#     }
#
#     for(char actions = 0; actions < num_colors; actions++) {
#         solution[row*num_cols + col] = actions;
#         toggle_light(row, col, puzzle, actions);
#         if (solve(puzzle,solution, next_row, (col + 1) % num_cols)) {
#             return true;
#         }
#         toggle_light(row, col, puzzle, num_colors - actions);
#         solution[row*num_cols + col] = 0;
#     }
#     return false;
# }
.globl solve
solve:
    ## Stack setup
    ##
    ## Index 4  Variable puzzle
    ## Index 0  Variable ra
    addi    $sp, $sp, -40
    sw      $ra, 0($sp)
    sw      $a0, 4($sp)
    sw      $s0, 8($sp)
    sw      $s1, 12($sp)
    sw      $s2, 16($sp)
    sw      $s3, 20($sp)
    sw      $s4, 24($sp)
    sw      $s5, 28($sp)
    sw      $s6, 32($sp)
    sw      $s7, 36($sp)
    ##
    ## End stack setup block

    ## Variables corresponding to registers:

    ##
    ##    $t0 = tmp_var
    ##    $s4 = actions
    ##    $s3 = next_row
    ##    $s2 = num_colors
    ##    $s1 = num_cols
    ##    $s0 = num_rows
    ##    $s6 = col
    ##    $s5 = row
    ##    $a3 = col_in
    ##    $a2 = row_in
    ##    $s7 = solution
    ##    $a1 = solution_in
    ##    $a0 = puzzle
    ##
    ## End aliases



    # .stackalloc (4)solution
    # .stackalloc (4)row (4)col


        move    $s7, $a1
        move    $s5, $a2
        move    $s6, $a3

        # assign  $s0   = *0($a0)
        lw      $s0, 0($a0)
        # assign  $s1   = *4($a0)
        lw      $s1, 4($a0)
        # assign  $s2 = *8($a0)
        lw      $s2, 8($a0)


    solve_next_row_ternary:
        # assign  $t0 = $s1 - 1
        addi    $t0, $s1, -1
        bne     $s6, $t0, solve_next_row_ternary_else

        # assign  $s3 = $s5 + 1
        addi    $s3, $s5, 1
        j       solve_next_row_ternary_end
    solve_next_row_ternary_else:
        # assign  $s3 = $s5
        move    $s3, $s5
    solve_next_row_ternary_end:

    solve_if_done:
        bge     $s5, $s0, solve_if_done_cond
        bge     $s6, $s1, solve_if_done_cond
        j       solve_if_done_skip
    solve_if_done_cond:
        # return board_done(num_rows,num_cols,puzzle->board);
        move    $a0, $s0
        move    $a1, $s1
        # assign  $a2 = *12($a0)
        lw      $a2, 4($sp)
        add     $a2,$a2,12

        jal     solver_board_done

    ## Stack frame teardown block
    ##
    lw      $ra, 0($sp)
    lw      $s0, 8($sp)
    lw      $s1, 12($sp)
    lw      $s2, 16($sp)
    lw      $s3, 20($sp)
    lw      $s4, 24($sp)
    lw      $s5, 28($sp)
    lw      $s6, 32($sp)
    lw      $s7, 36($sp)
    addi    $sp, $sp, 40
    ##
    ## End stack teardown

    jr      $ra

    solve_if_done_skip:
#if (row != 0) {
#         int actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
#         solution[row*num_cols + col] = actions;
#         toggle_light(row, col, puzzle, actions);
#         if (solve(puzzle,solution, next_row, (col + 1) % num_cols)) {
#             return true;
#         }
#         solution[row*num_cols + col] = 0;
#         toggle_light(row, col, puzzle, num_colors - actions);
#         return false;
#     }
    beq     $s5, $zero, solve_if_row_not_zero_skip
    sub     $t0, $s5, 1
    mul     $t0, $t0, $s1
    add     $t0, $t0, $s6    # (row-1)*num_cols + col
    lw      $a0, 4($sp)
    add     $a0, $a0, 12
    add     $t2, $t0, $a0   # t0: offset, a0: puzzle->board
    lbu     $t1, 0($t2)     # puzzle->board[(row-1)*num_cols + col]
    sub     $t1, $s2, $t1
    rem     $s4, $t1, $s2   # s4: actions = (num_colors - puzzle->board[(row-1)*num_cols + col]) % num_colors;
    add     $t0, $t0, $s1
    add     $t0, $t0, $s7
    sb      $s4, 0($t0)     # solution[row*num_cols + col] = actions


    move    $a0, $s5
    move    $a1, $s6
    lw      $a2, 4($sp)
    move    $a3, $s4
    jal     toggle_light    #toggle_light(row, col, puzzle, actions);

    lw      $a0, 4($sp)
    move    $a1, $s7
    move    $a2, $s3
    add     $a3, $s6, 1
    rem     $a3, $a3, $s1
    jal     solve           #solve(puzzle,solution, next_row, (col + 1) % num_cols)

    beq     $v0, 0, solve_if_row_not_zero_solved_skip
    ## Stack frame teardown block
    ##
    lw      $ra, 0($sp)
    lw      $s0, 8($sp)
    lw      $s1, 12($sp)
    lw      $s2, 16($sp)
    lw      $s3, 20($sp)
    lw      $s4, 24($sp)
    lw      $s5, 28($sp)
    lw      $s6, 32($sp)
    lw      $s7, 36($sp)
    addi    $sp, $sp, 40
    ##
    ## End stack teardown

    jr      $ra

    solve_if_row_not_zero_solved_skip:
    mul    $t0, $s5, $s1
    add     $t0, $t0, $s6
    add     $t0, $t0, $s7
    sb      $zero, 0($t0)         #         solution[row*num_cols + col] = 0;

    lw      $a2, 4($sp)
    move    $a0, $s5
    move    $a1, $s6
    sub     $a3, $s2, $s4
    jal     toggle_light    #toggle_light(row, col, puzzle, num_colors - actions);

    move    $v0, $zero          # return false
    ## Stack frame teardown block
    ##
    lw      $ra, 0($sp)
    lw      $s0, 8($sp)
    lw      $s1, 12($sp)
    lw      $s2, 16($sp)
    lw      $s3, 20($sp)
    lw      $s4, 24($sp)
    lw      $s5, 28($sp)
    lw      $s6, 32($sp)
    lw      $s7, 36($sp)
    addi    $sp, $sp, 40
    ##
    ## End stack teardown

    jr      $ra
    solve_if_row_not_zero_skip:

        # Saving things to the stack
        sw      $a0, 4($sp) # sstk    $puzzle, puzzle

        li      $s4, 0
    solve_for_actions:
        bge     $s4, $s2, solve_for_actions_end

        # assign  $s4 =>:: $s7&[$s5 * $s1 + $s6]
        mul     $t9, $s5, $s1
        add     $t9, $t9, $s6
        add     $t9, $t9, $s7
        sb      $s4, 0($t9)

        # toggle_light(row, col, puzzle, actions);
        move    $a0, $s5
        move    $a1, $s6
        lw      $a2, 4($sp) # lstk    $a2, puzzle
        move    $a3, $s4
        jal     toggle_light

    # if (solve(puzzle,solution, next_row, (col + 1) % num_cols)) {
    solve_recurse_if:
        lw      $a0, 4($sp) # lstk    $a0, puzzle
        move    $a1, $s7
        move    $a2, $s3
        # assign  $a3 = ($s6 + 1) % $s1
        addi    $a3, $s6, 1
        div     $a3, $s1
        mfhi    $a3
        jal     solve

        beq     $v0, $0, solve_recurse_if_skip

    ## Stack frame teardown block
    ##
    lw      $ra, 0($sp)
    lw      $s0, 8($sp)
    lw      $s1, 12($sp)
    lw      $s2, 16($sp)
    lw      $s3, 20($sp)
    lw      $s4, 24($sp)
    lw      $s5, 28($sp)
    lw      $s6, 32($sp)
    lw      $s7, 36($sp)
    addi    $sp, $sp, 40
    ##
    ## End stack teardown

    jr      $ra

    solve_recurse_if_skip:
    # }

        # toggle_light(row, col, puzzle, num_colors - actions);
        move    $a0, $s5
        move    $a1, $s6
        lw      $a2, 4($sp) # lstk    $a2, puzzle
        # assign  $a3 = $s2 - $s4
        sub     $a3, $s2, $s4
        jal     toggle_light

        # assign  $zero =>:: $s7&[$s5 * $s1 + $s6]
        mul     $t9, $s5, $s1
        add     $t9, $t9, $s6
        add     $t9, $t9, $s7
        sb      $zero, 0($t9)

    solve_for_actions_inc:
        add     $s4, $s4, 1
        j       solve_for_actions
    solve_for_actions_end:

    # @RETURN $zero
    move    $v0, $zero

    ## Stack frame teardown block
    ##
    lw      $ra, 0($sp)
    lw      $s0, 8($sp)
    lw      $s1, 12($sp)
    lw      $s2, 16($sp)
    lw      $s3, 20($sp)
    lw      $s4, 24($sp)
    lw      $s5, 28($sp)
    lw      $s6, 32($sp)
    lw      $s7, 36($sp)
    addi    $sp, $sp, 40
    ##
    ## End stack teardown

    jr      $ra


# void zero_board(int num_rows, int num_cols, unsigned char* solution){
#     for (int row = 0; row < num_rows; row++) {
#         for (int col = 0; col < num_cols; col++) {
#             solution[(row)*num_cols + col] = 0;
#         }
#     }
# }
.globl solver_zero_board
solver_zero_board:
    ## Variables corresponding to registers:

    ##
    ##    $t1 = col
    ##    $t0 = row
    ##    $a2 = solution
    ##    $a1 = num_cols
    ##    $a0 = num_rows
    ##
    ## End aliases


        li      $t0, 0
    solver_zero_board_for_row:
        bge     $t0, $a0, solver_zero_board_for_row_end

        li      $t1, 0
    solver_zero_board_for_col:
        bge     $t1, $a1, solver_zero_board_for_col_end

        # assign  $zero =>:: $a2&[$t0 * $a1 + $t1]
        mul     $t9, $t0, $a1
        add     $t9, $t9, $t1
        add     $t9, $t9, $a2
        sb      $zero, 0($t9)

        add     $t1, $t1, 1
        j       solver_zero_board_for_col
    solver_zero_board_for_col_end:

        add     $t0, $t0, 1
        j       solver_zero_board_for_row
    solver_zero_board_for_row_end:

    jr      $ra


# // it just checks if all lights are off
# bool board_done(int num_rows, int num_cols,unsigned char* board){
#     for (int row = 0; row < num_rows; row++) {
#         for (int col = 0; col < num_cols; col++) {
#             if (board[(row)*num_cols + col] != 0) {
#                 return false;
#             }
#         }
#     }
#     return true;
# }
.globl solver_board_done
solver_board_done:
    ## Variables corresponding to registers:

    ##
    ##    $t2 = condition_val
    ##    $t1 = col
    ##    $t0 = row
    ##    $a2 = board
    ##    $a1 = num_cols
    ##    $a0 = num_rows
    ##
    ## End aliases


        li      $t0, 0
    solver_board_done_for_row:
        bge     $t0, $a0, solver_board_done_for_row_end

        li      $t1, 0
    solver_board_done_for_col:
        bge     $t1, $a1, solver_board_done_for_col_end

        # assign  $t2 = $a2[$t0 * $a1 + $t1]
        mul     $t2, $t0, $a1
        add     $t2, $t2, $t1
        add     $t2, $t2, $a2
        lb     $t2, 0($t2)
    solver_board_done_if:
        beq     $t2, $0, solver_board_done_if_skip

        # @RETURN $zero
        move    $v0, $zero
    jr      $ra

    solver_board_done_if_skip:

        add     $t1, $t1, 1
        j solver_board_done_for_col
    solver_board_done_for_col_end:


        add     $t0, $t0, 1
        j solver_board_done_for_row
    solver_board_done_for_row_end:

        # @RETURN 1
        li      $v0, 1
    jr      $ra


.kdata
chunkIH:    .space 40
non_intrpt_str:    .asciiz "Non-interrupt exception\n"
unhandled_str:    .asciiz "Unhandled interrupt type\n"
.ktext 0x80000180
interrupt_handler:
.set noat
    move    $k1, $at        # Save $at
                            # NOTE: Don't touch $k1 or else you destroy $at!
.set at
    la      $k0, chunkIH
    sw      $a0, 0($k0)        # Get some free registers
    sw      $v0, 4($k0)        # by storing them to a global variable
    sw      $t0, 8($k0)
    sw      $t1, 12($k0)
    sw      $t2, 16($k0)
    sw      $t3, 20($k0)
    sw      $t4, 24($k0)
    sw      $t5, 28($k0)

    # Save coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    mfhi    $t0
    sw      $t0, 32($k0)
    mflo    $t0
    sw      $t0, 36($k0)

    mfc0    $k0, $13                # Get Cause register
    srl     $a0, $k0, 2
    and     $a0, $a0, 0xf           # ExcCode field
    bne     $a0, 0, non_intrpt



interrupt_dispatch:                 # Interrupt:
    mfc0    $k0, $13                # Get Cause register, again
    beq     $k0, 0, done            # handled all outstanding interrupts

    and     $a0, $k0, BONK_INT_MASK     # is there a bonk interrupt?
    bne     $a0, 0, bonk_interrupt

    and     $a0, $k0, TIMER_INT_MASK    # is there a timer interrupt?
    bne     $a0, 0, timer_interrupt

    and     $a0, $k0, REQUEST_PUZZLE_INT_MASK
    bne     $a0, 0, request_puzzle_interrupt

    and     $a0, $k0, RESPAWN_INT_MASK
    bne     $a0, 0, respawn_interrupt

    li      $v0, PRINT_STRING       # Unhandled interrupt types
    la      $a0, unhandled_str
    syscall
    j       done

bonk_interrupt:
    #Fill in your bonk handler code here
    li	    $a0, 180
    sw	    $a0, ANGLE		# set angle to turn 180 degrees
	sw	    $zero, ANGLE_CONTROL	# send the turn command
	li	    $a0, 0
	sw	    $a0, VELOCITY
    li      $a0, 1
    sw      $a0, BONK_ACK
    j       interrupt_dispatch      # see if other interrupts are waiting

timer_interrupt:
    #Fill in your timer interrupt code here
    sw      $0, VELOCITY($0)
    li      $a0, 1
    sw      $a0, TIMER_ACK
    j        interrupt_dispatch     # see if other interrupts are waiting

request_puzzle_interrupt:
    #Fill in your puzzle interrupt code here
    li      $a0, 1
    sw      $a0, REQUEST_PUZZLE_ACK
    j       interrupt_dispatch

respawn_interrupt:
    li      $a0, -1
    sw      $a0, VELOCITY
    sw      $0, RESPAWN_ACK
    #Fill in your respawn handler code here
    j       interrupt_dispatch

non_intrpt:                         # was some non-interrupt
    li      $v0, PRINT_STRING
    la      $a0, non_intrpt_str
    syscall                         # print out an error message
    # fall through to done

done:
    la      $k0, chunkIH

    # Restore coprocessor1 registers!
    # If you don't do this and you decide to use division or multiplication
    #   in your main code, and interrupt handler code, you get WEIRD bugs.
    lw      $t0, 32($k0)
    mthi    $t0
    lw      $t0, 36($k0)
    mtlo    $t0

    lw      $a0, 0($k0)             # Restore saved registers
    lw      $v0, 4($k0)
    lw      $t0, 8($k0)
    lw      $t1, 12($k0)
    lw      $t2, 16($k0)
    lw      $t3, 20($k0)
    lw      $t4, 24($k0)
    lw      $t5, 28($k0)

.set noat
    move    $at, $k1        # Restore $at
.set at
    eret
