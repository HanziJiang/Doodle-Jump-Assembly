#####################################################################
#
# CSC258H5S Fall 2020 Assembly Final Project
# University of Toronto, St. George
#
# Student: Hanzi Jiang, 1000000000
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 512
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# 
# - Milestone 5
# 
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
#
# For Milestone 4:
#    1. Game Over / Retry
#       The game halts and displays GG (Good Game) when the player
#       loses. After a few seconds, the player is able to retry by
#       typing s.
#    2. Different Levels / Dynamic Increase in Difficulty
#       There are seven levels. Level is determined by score. Higher
#       level has a faster speed and shorter platform width.
# For Milestone 5:
#    1. Boosting / Power-up
#       Rocket (yellow) makes the doodler jumps for an extra 140 pixels.
#       Spring (cyan) makes the doodler jumps for an extra 40 pixels.
#    2. Opponent
#       Game ends if doodler hits evil creature (red). Evil creature 
#       moves from left to right, top to bottom.  
#    3. Player Name
#       The user inputs his name before the game starts. After 
#       pressing Enter, a greeting message appears. Then he can type 
#       in s to start the game.
#
#####################################################################
.data
	displayAddress:      .word 0x10008000           # 268468224
	tempDisplayAddress:  .word 0x1000A080           # 268476544 = 268468224 + 8192 + 128
	doodlerOffset:       .word 5556                 # number of bytes from start to the upper left corner of doodle.
	springOffset:        .word 4508                 # number of bytes from start to the spring.
	rocketOffset:        .word 4                    # number of bytes from start to the rocket.
	platformOffsets:     .word 132, 1296, 1884, 2984, 3516, 4616, 5848, 6960      # number of bytes from start to the left of each platform
	evilOffset:          .word 1280                 # number of bytes from start to the eveil creature.                    
	platformWidth:       .word 9                    # number of pixels of a platform.
	numPlatform:         .word 8                    # number platforms.
	jumpHeight:          .word -20                  # number of pixels it jumps when touches a platform; negaive means up.
	springHeight:        .word -40                  # number of additional pixels it jumps when touches a spring; negaive means up.
	rocketHeight:        .word -140                 # number of additional pixels it jumps when touches a rocket; negaive means up.
	pixelsToGo:          .word 0                    # number of pixels to go; negative for going up, otherwise down.
	score:               .word 0                    
	overMessage:         .asciiz "\nGame Over.\nYour score is: "
	greeting:            .asciiz "\nWelcome, "
	playerName:          .space 20
	playerNamePointer:   .word 1
	sleepTime:           .word 30                   # sleep time in ms
    
            
.text
main:   
	
	lw $t0, tempDisplayAddress
	
	INFINITE_NAME_LOOP:
		jal HANDLE_NAME_INPUT
		j INFINITE_NAME_LOOP
	
	BEGIN:
	jal INITIALIZE_GAME
	
	# Infinite loop awaits for s to start the game.
	INFINITE_START_LOOP:
		jal HANDLE_START_INPUT
		j INFINITE_START_LOOP
	
	INFINITE_GAME_LOOP: 
		jal HANDLE_GAME_INPUT
		
 		jal UPDATE_EVIL
		jal DRAW_EVIL
		
 		jal UPDATE_DOODLER
		jal DRAW_PLATFORMS
		jal DRAW_SPRING
		jal DRAW_ROCKET
		jal DRAW_DOODLER
 		
 		jal MOVE_FROM_TEMP
 		
 		jal SLEEP
 
		j INFINITE_GAME_LOOP
		

INITIALIZE_GAME:
	# Repaint tempDisplayAddress
	REPAINT:
		li $t2, 0x000000
		li $t1, 0
		REPAINT_LOOP:
			bgt $t1, 8188, RESET_DOODLER
			add $t3, $t1, $t0
			sw $t2, 0($t3)
			add $t1, $t1, 4
			j REPAINT_LOOP
	
	# Reset doodlerOffset
	RESET_DOODLER:
	    la $t2, doodlerOffset
		li $t1, 5556
		sw $t1, ($t2)
		
	# Reset springOffset
	RESET_SPRING:
		la $t2, springOffset
		li $t1, 4508
		sw $t1, ($t2)
		
	# Reset score
	RESET_SCORE:
		la $t2, score
		li $t1, 0
		sw $t1, ($t2)
		
	# Reset rocketOffset
	RESET_ROCKET:
		la $t2, rocketOffset
		li $t1, 4
		sw $t1, ($t2)
		
	# Reset evilOffset
	RESET_EVIL:
		la $t2, evilOffset
		li $t1, 1280
		sw $t1, ($t2)
		
	# Reset platformOffsets
	RESET_PLATFORMS:
		la $t2, platformOffsets
		li $t1, 132
		sw $t1, 0($t2)
		li $t1, 1296
		sw $t1, 4($t2)
		li $t1, 1884
		sw $t1, 8($t2)
		li $t1, 2984
		sw $t1, 12($t2)
		li $t1, 3516
		sw $t1, 16($t2)
		li $t1, 4616
		sw $t1, 20($t2)
		li $t1, 5848
		sw $t1, 24($t2)
		li $t1, 6960
		sw $t1, 28($t2)
		
	# Reset platformWidth
	RESET_PLATFORM_WIDTH:
		la $t2, platformWidth
		li $t1, 9
		sw $t1, ($t2)
		
	# Reset pixelsToGo
	RESET_PIXELS_TO_GO:
		la $t2, pixelsToGo
		li $t1, 0
		sw $t1, ($t2)
		
	# Reset sleepTime
	RESET_SLEEP:
		la $t2, sleepTime
		li $t1, 30
		sw $t1, ($t2)
		
	jr $ra


# Copy content from tempDisplayAddress to displayAddress.		
MOVE_FROM_TEMP:
    lw $t0, tempDisplayAddress
	lw $t8, displayAddress
	li $t2, 0x000000
	add $t5, $zero, $zero
	LOOP: bgt $t5, 8188, END_LOOP
		add $t7, $t0, $t5    # $t7 = Address(tempDisplayAddress[i])
		add $t3, $t8, $t5    # $t3 = Address(displayAddress[i])
		lw $t9, 0($t7)
		sw $t9, 0($t3)
		sw $t2, 0($t7)
		addi $t5, $t5, 4
		j LOOP
	END_LOOP:
	jr $ra

		
END_GAME:
	# Print messages.
	li $v0, 4
	la $a0, overMessage
	syscall
	
	# Print score.
	li $v0, 1
	lw $a0, score
	syscall
	
	jal DRAW_GG
	
	# Wait a few seconds.
	li $v0, 32
	li $a0, 6000
 	syscall
	
	j BEGIN
	
    
HANDLE_START_INPUT:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
 	beqz $t8, HANDLE_START_INPUT_RETURN
 	
 	lw $t2, 0xffff0004
 	beq $t2, 0x73, HANDLE_S
 	
 	HANDLE_START_INPUT_RETURN:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
	
 	HANDLE_S:
 		j INFINITE_GAME_LOOP
 		
 		
HANDLE_NAME_INPUT:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
 	beqz $t8, HANDLE_NAME_INPUT_RETURN
 	
 	lw $t2, 0xffff0004
 	beq $t2, 0x0a, HANDLE_ENTER
 	
 	# Return if not character.
 	blt $t2, 0x41, HANDLE_NAME_INPUT_RETURN
 	bgt $t2, 0x7a, HANDLE_NAME_INPUT_RETURN
 	bge $t2, 0x61, HANDLE
 	ble $t2, 0x6a, HANDLE
 	j HANDLE_NAME_INPUT_RETURN
 	
 	HANDLE:
 	HANDLE_CHARACTER:
 		la $t4, playerNamePointer
 		la $t5, playerName
 		lw $t3, playerNamePointer
 		
 		# Initialize playerNamePointer if its the first letter
 		bne $t3, 1, NOT_FIRST_LETTER
 		sw $t5, 0($t4)
 		
 		NOT_FIRST_LETTER:
 		
 		# Write current letter
 		lw $t3, playerNamePointer
 		sb $t2, 0($t3)
 		
 		# Increment playerNamePointer
 		addi $t3, $t3, 1
 		sw $t3, 0($t4)
 		
		
 	HANDLE_NAME_INPUT_RETURN:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
	
 	HANDLE_ENTER:
 		# Print greeting message.
 		li $v0, 4
		la $a0, greeting
		syscall
 		li $v0, 4
		la $a0, playerName
		syscall
		
 		j INFINITE_START_LOOP
		
		
HANDLE_GAME_INPUT:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t8, 0xffff0000
 	beqz $t8, HANDLE_GAME_INPUT_RETURN
 	
 	lw $t2, 0xffff0004
 	beq $t2, 0x6a, HANDLE_J
 	beq $t2, 0x6b, HANDLE_K
	
 	# Get return address from stack
 	HANDLE_GAME_INPUT_RETURN:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
 		
	HANDLE_J:
		la $t1, doodlerOffset
 		lw $t7, doodlerOffset
 		addi $t6, $t7, -4
 		sw $t6, ($t1)
 		j HANDLE_GAME_INPUT_RETURN
	
 	HANDLE_K:
 		la $t1, doodlerOffset
 		lw $t7, doodlerOffset
 		addi $t6, $t7, 4
 		sw $t6, ($t1)
 		j HANDLE_GAME_INPUT_RETURN


DRAW_SPRING:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Color
	li $t4, 0x0fe8ff
        
    lw $t1 springOffset
	add $t5, $t0, $t1  
	sw $t4, 0($t5)
	
 	# Get return address from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
 	jr $ra
 	
 
DRAW_EVIL:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Color
	li $t4, 0xf00000
        
    lw $t1 evilOffset
	add $t5, $t0, $t1  
	sw $t4, ($t5)
	
 	# Get return address from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
 	jr $ra
 	
 	
DRAW_ROCKET:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Color
	li $t4, 0xfff000
        
    lw $t1 rocketOffset
	add $t5, $t0, $t1  
	sw $t4, 0($t5)
	
 	# Get return address from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
 	jr $ra
 	

DRAW_DOODLER:
    # Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Colors
	li $t4, 0xfff000
    li $t3, 0x0fff00
    li $t2, 0xffffff
        
    lw $t1 doodlerOffset
	add $t5, $t0, $t1    # t5 = Address of doodler's first pixel.
	sw $t3, 8($t5)
	sw $t3, 132($t5)
	sw $t3, 140($t5)
	sw $t3, 256($t5)
	sw $t3, 272($t5)
	sw $t3, 388($t5)
	sw $t3, 396($t5)
	sw $t3, 520($t5)
	sw $t4, 512($t5)
	sw $t4, 528($t5)
	
 	# Get return address from stack
	lw $ra, 0($sp)
	addi $sp, $sp, 4
 	jr $ra
 	
 	
DRAW_PLATFORMS:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
    li $t2, 0xcccccc
	add $t7, $zero, $zero    
	lw $t8, numPlatform
	la $t1, platformOffsets   # $t1 = Address(platformOffsets).
	
	# Loop over all platforms to draw.
	DRAW_PLATFORM: bge $t7, $t8, DRAW_PLATFORM_END
        sll $t6, $t7, 2       # j = i * 4.
        add $t6, $t6, $t1     # $t6 = Address(platformOffsets[j]).
		lw $t6, 0($t6)        # $t6 = platformOffsets[j].
		add $t6, $t6, $t0     # $t9 = Address of platform first pixel.
		
		add $t3, $zero, $zero
		lw $t4, platformWidth
		
		# Loop over every pixel of a platform.
		PLATFORM_WIDTH: bge $t3, $t4, PLATFORM_WIDTH_END
			sll $t5, $t3, 2
			add $t5, $t5, $t6
			sw $t2, 0($t5)
			addi $t3, $t3, 1
			j PLATFORM_WIDTH
		PLATFORM_WIDTH_END:
			
		addi $t7, $t7, 1
		
		j DRAW_PLATFORM
	
	DRAW_PLATFORM_END:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra


# If doodler touches spring, write 1 into $v1; otherwise 0.
TOUCH_SPRING:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, springOffset
	lw $t2, doodlerOffset
	# Lower bound and upper bound.
	addi $t3, $t2, 512   # 128 * 4
	addi $t4, $t3, 16    # 128 * 4 + 4 * 4
	
	# Doodler touches spring if: 
	# springOffset >= doodlerOffset + 128 * 4 and springOffset <= platformOffsets + 128 * 4 + 4 * 4.
	blt $t1, $t3, NO_SPRING
	bgt $t1, $t4, NO_SPRING
		li $v1, 1
		j RETURN_TOUCH_SPRING
	
	NO_SPRING:
		addi $v1, $zero, 0
		
	RETURN_TOUCH_SPRING:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
 		
 
# If doodler touches the evil creature, write 1 into $v1; otherwise 0.
TOUCH_EVIL:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, evilOffset
	lw $t2, doodlerOffset
	j CHECK_EVIL
	
	HIT_EVIL:
		li $v1, 1
		j RETURN_TOUCH_EVIL
	
	# Doodler touches the evil creature if: 
	# evilOffset == doodlerOffset + 2 * 4; or
	# in (doodlerOffset + 128) + 1 * 4 to (doodlerOffset + 128) + 3 * 4; or
	# in (doodlerOffset + 256) to (doodlerOffset + 256) + 4 * 4; or
	# in (doodlerOffset + 384) + 1 * 4 to (doodlerOffset + 384) + 3 * 4; or
	# in (doodlerOffset + 512) to (doodlerOffset + 512) + 4 * 4.
	CHECK_EVIL:
		addi $t3, $t2, 8
		beq $t1, $t3, HIT_EVIL
		
		addi $t3, $t2, 132
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 136
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 140
		beq $t1, $t3, HIT_EVIL
		
		addi $t3, $t2, 256
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 260
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 264
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 268
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 272
		beq $t1, $t3, HIT_EVIL
		
		addi $t3, $t2, 388
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 392
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 396
		beq $t1, $t3, HIT_EVIL
		
		addi $t3, $t2, 512
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 516
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 520
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 524
		beq $t1, $t3, HIT_EVIL
		addi $t3, $t2, 528
		beq $t1, $t3, HIT_EVIL
			
	NO_EVIL:
		addi $v1, $zero, 0
		
	RETURN_TOUCH_EVIL:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
 		
 		
 # If doodler touches rocket, write 1 into $v1; otherwise 0.
TOUCH_ROCKET:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	lw $t1, rocketOffset
	lw $t2, doodlerOffset
	# Lower bound and upper bound.
	addi $t3, $t2, 512   # 128 * 4
	addi $t4, $t3, 16    # 128 * 4 + 4 * 4
	
	# Doodler touches spring if: 
	# springOffset >= doodlerOffset + 128 * 4 and springOffset <= platformOffsets + 128 * 4 + 4 * 4.
	blt $t1, $t3, NO_ROCKET
	bgt $t1, $t4, NO_ROCKET
		li $v1, 1
		j RETURN_TOUCH_ROCKET
	
	NO_ROCKET:
		addi $v1, $zero, 0
		
	RETURN_TOUCH_ROCKET:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
 		
 		
UPDATE_EVIL:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t3, evilOffset
	lw $t4, evilOffset
	addi $t4, $t4, 4
	sw $t4, ($t3)
	
	lw $t2, evilOffset
	# If creature outside of screen.
	blt $t2, 8192, RETURN_UPDATE_EVIL
	# Reset offset of creature.
	sw $zero, ($t3)
	
	RETURN_UPDATE_EVIL:
		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
	
	
UPDATE_DOODLER:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	jal UPDATE_PIXELS_TO_GO
	
 	# If doodler hits evil creature, end game.
 	jal TOUCH_EVIL
 	beq $v1, 1, END_GAME
 	
 	la $t1, doodlerOffset
 	lw $t7, doodlerOffset
 	la $t3, pixelsToGo
 	lw $t2, pixelsToGo
		
 	# If is going up.
 	bgez $t2, GO_DOWN
 	
 		# If doodler is too high, roll down platforms instead.
 		bgt $t7, 1792, NO_ROLL
 			jal ROLL_DOWN
 			la $t3, pixelsToGo
 			lw $t2, pixelsToGo
 			addi $t2, $t2, 1
 			sw $t2, ($t3)
 			j RETURN_UPDATE_DOODLER
 	
 		NO_ROLL:
 			addi $t6, $t7, -128
 			sw $t6, ($t1)
 			addi $t2, $t2, 1
 			sw $t2, ($t3)
 			j RETURN_UPDATE_DOODLER
		
 	# Else if is going down.
 	GO_DOWN:
 		# If doodler is too low, exit the game.
 		bgt $t7, 8192, END_GAME
 		
 		# Make doodler go down one row.
 		addi $t6, $t7, 128
 		sw $t6, ($t1)
 		j RETURN_UPDATE_DOODLER
 		
 	RETURN_UPDATE_DOODLER:
 		# Get return address from stack
		lw $ra, 0($sp)
		addi $sp, $sp, 4
 		jr $ra
 	
 
# Update pixelsToGo if touches platform or spring.
UPDATE_PIXELS_TO_GO:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	PLATFORM_UPDATE:
		jal TOUCH_PLATFORM
		lw $t2, pixelsToGo
		bltz $t2, UPDATE_PIXELS_TO_GO_RETURN     # Check if going down.
		blez $v1, UPDATE_PIXELS_TO_GO_RETURN     # Check if touches a platform.
			la $t3, pixelsToGo
			lw $t7, jumpHeight
			sw $t7, ($t3)
	
	SPRING_UPDATE:	
		jal TOUCH_SPRING
		blez $v1, ROCKET_UPDATE                  # Check if touches a spring.
		    lw $t2, pixelsToGo
			lw $t6, pixelsToGo
			la $t3, pixelsToGo
			lw $t7, springHeight
			add $t7, $t7, $t6
			sw $t7, ($t3)
			
	ROCKET_UPDATE:	
		jal TOUCH_ROCKET
		blez $v1, UPDATE_PIXELS_TO_GO_RETURN     # Check if touches a rocket.
		    lw $t2, pixelsToGo
			lw $t6, pixelsToGo
			la $t3, pixelsToGo
			lw $t7, rocketHeight
			add $t7, $t7, $t6
			sw $t7, ($t3)
	
	UPDATE_PIXELS_TO_GO_RETURN:
		# Get return address from stack.
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
	

# Check if the doodler is going down and touches a platform. 
# Store the boolean result into $v0.
TOUCH_PLATFORM:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# $t4 = doodlerOffset + 128 * 5 - 4 * (platformWidth - 1). 
	# The smallest platform offset such that doodler touches the platform. 
	addi $t1, $zero, 5
	sll $t1, $t1, 7
	lw $t3, doodlerOffset
	add $t1, $t1, $t3
	lw $t2, platformWidth
	subi $t2, $t2, 1
	sll $t2, $t2, 2
	sub $t4, $t1, $t2
	
	# $t5 = doodlerOffset + 128 * 5 + 4 * (5 - 1).
	# The largest platform offset such that doodler touches the platform. 
	addi $t6, $zero, 5
	subi $t6, $t6, 1
	sll $t6, $t6, 2
	add $t5, $t6, $t1
	
	# Loop over all platforms to check if doodler touches any platform.
	add $t7, $zero, $zero    
	lw $t8, numPlatform
	la $t1, platformOffsets 
	CHECK_PLATFORM: bge $t7, $t8, CHECK_PLATFORM_END
	
		# $t2 = current platform offset.
		sll $t9, $t7, 2      # $t9 = i * 4
		add $t3, $t9, $t1    # $t3 = Address(platformOffsets[i]).
		lw $t2, 0($t3)       # $t2 = platformOffsets[i].
		
		# If doodler touches platform.
		# That is, if current platform offset is in between the min and max.
		blt $t2, $t4, NO_TOUCH
		bgt $t2, $t5, NO_TOUCH
			addi $v1, $zero, 1
			j RETURN_TOUCH_PLATFORM
			
		NO_TOUCH:
		addi $t7, $t7, 1
	
		j CHECK_PLATFORM
	
	CHECK_PLATFORM_END:
		addi $v1, $zero, 0
	
	RETURN_TOUCH_PLATFORM:
		# Get return address from stack.
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra


# Update score by the amount stored in the parameter $a1
UPDATE_SCORE:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	la $t3, score
	lw $t4, score          # Old score.
	add $t5, $t4, $a1      # New score.
	
		# Change difficulty according to old and new score.
	LEVEL_1:
		bge $t4, 200, LEVEL_2
		blt $t5, 200, LEVEL_2
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_2:
		bge $t4, 400, LEVEL_3
		blt $t5, 400, LEVEL_3
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_3:
		bge $t4, 600, LEVEL_4
		blt $t5, 600, LEVEL_4
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_4:
		bge $t4, 800, LEVEL_5
		blt $t5, 800, LEVEL_5
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_5:
		bge $t4, 1000, LEVEL_6
		blt $t5, 1000, LEVEL_6
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_6:
		bge $t4, 1200, LEVEL_7
		blt $t5, 1200, LEVEL_7
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_7:
		bge $t4, 1400, LEVEL_8
		blt $t5, 1400, LEVEL_8
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	LEVEL_8:
		bge $t4, 1400, RETURN_UPDATE_SCORE
		blt $t5, 1400, RETURN_UPDATE_SCORE
		jal DECREASE_PLATFORM_WIDTH
		jal DECREASE_SLEEP_TIME
	
	RETURN_UPDATE_SCORE:
		sw $t5, ($t3)
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
	
			
# Decrease platformWidth by 1.
DECREASE_PLATFORM_WIDTH:
	lw $t6, platformWidth
	addi $t6, $t6, -1
	la $t7, platformWidth
	sw $t6, ($t7)
	
	jr $ra
	
	
# Decrease sleepTime by 5.
DECREASE_SLEEP_TIME:
	lw $t6, sleepTime
	addi $t6, $t6, -5
	la $t7, sleepTime
	sw $t6, ($t7)
	
	jr $ra

	
ROLL_PLATFORMS:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
 	add $t7, $zero, $zero    
	lw $t8, numPlatform
	la $t1, platformOffsets 
	UPDATE_PLATFORM: bge $t7, $t8, UPDATE_PLATFORM_END
	
		sll $t9, $t7, 2      # $t9 = i * 4
		add $t3, $t9, $t1    # $t3 = Address(platformOffsets[i])
		lw $t2, 0($t3)       # $t2 = platformOffsets[i]
		addi $t2, $t2, 128   # $t2 += 128
		sw $t2, 0($t3)       # platformOffsets[i] = $t2
		
		addi $t7, $t7, 1     # $t7 += 1
	
		j UPDATE_PLATFORM
	
	UPDATE_PLATFORM_END:
	
	# Check if any platform is outside screen;
	# If yes, add new platform.
	addi $t3, $t8, -1        # t3 = index of last element j
	sll $t3, $t3, 2          # t3 = j * 4
	add $t2, $t3, $t1        # $t2 = Address(platformOffsets[-1])
	lw $t4, 0($t2)           # $t4 = platformOffsets[-i]
	li $t5, 8164
	ble $t4, $t5, NO_ADD_PLATFORM
	
	addi $t6, $t3, -4
	MOVE_VALUE: bltz $t6, END_MOVE_VALUE
		add $t8, $t6, $t1    # $t8 = Address(platformOffsets[j])
		lw $t2, 0($t8)       # $t2 = platformOffsets[j]
		sw $t2, 4($t8)       # platformOffsets[j+1] = $t2
		addi $t6, $t6, -4
		j MOVE_VALUE
	END_MOVE_VALUE:
	
	# Fill in first element(random generated) of platformOffsets
	lw $t3, platformWidth
	addi $t4, $zero, 33
	sub $t3, $t4, $t3
	li $v0, 42
	move $a1, $t3
	syscall
	sll $a0, $a0, 2
	sw $a0, 0($t1)
	
	NO_ADD_PLATFORM:
		# Get return address from stack.
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra


ROLL_SPRING:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Roll down the spring.
	la $t3, springOffset
	lw $t2, ($t3)
	addi $t2, $t2, 128
	sw $t2, 0($t3)
	
	lw $t7, platformOffsets
	# If spring outside of screen.
	blt $t2, 8192, RETURN_ROLL_SPRING
	# If second row has a platform.
	bge $t7, 128, RETURN_ROLL_SPRING
	# Reset offset of spring.
	lw $t5, platformWidth
	li $v0, 42
	move $a1, $t5
	syscall
	sll $a0, $a0, 2
	add $a0, $a0, $t7
	addi $t5, $a0, -128 
	sw $t5, ($t3)
	
	# Get return address from stack.
	RETURN_ROLL_SPRING:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
		
		
ROLL_EVIL:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Roll down the evil creature.
	la $t3, evilOffset
	lw $t2, ($t3)
	addi $t2, $t2, 128
	sw $t2, 0($t3)
	
	# If creature outside of screen.
	blt $t2, 8192, RETURN_ROLL_EVIL
	# Reset offset of creature.
	sw $zero, ($t3)
	
	# Get return address from stack.
	RETURN_ROLL_EVIL:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra
		
		
ROLL_ROCKET:
	# Push return address to stack
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Roll down the rocket.
	la $t3, rocketOffset
	lw $t2, ($t3)
	addi $t2, $t2, 128
	sw $t2, 0($t3)
	
	lw $t7, platformOffsets
	# If rocket outside of screen.
	blt $t2, 8192, RETURN_ROLL_ROCKET
	# If second row has a platform.
	bge $t7, 128, RETURN_ROLL_ROCKET
	# Reset offset of rocket.
	lw $t5, platformWidth
	li $v0, 42
	move $a1, $t5
	syscall
	sll $a0, $a0, 2
	add $a0, $a0, $t7
	addi $t5, $a0, -128 
	sw $t5, ($t3)
	
	# Get return address from stack.
	RETURN_ROLL_ROCKET:
		lw $ra, 0($sp)
		addi $sp, $sp, 4
		jr $ra

 
ROLL_DOWN:
	# Push return address to stack.
	addi $sp, $sp, -4
	sw $ra, 0($sp)
	
	# Update score.
	addi $a1, $zero, 1
	jal UPDATE_SCORE
	
	# Roll down components.
	jal ROLL_PLATFORMS
	jal ROLL_SPRING
	jal ROLL_ROCKET
	jal ROLL_EVIL
	
	# Get return address from stack.
	lw $ra, 0($sp)
	addi $sp, $sp, 4
	jr $ra	
	
	
SLEEP:
	lw $t1, sleepTime
	li $v0, 32
	move $a0, $t1
 	syscall
 	jr $ra
 	
DRAW_GG:
	lw $t9, displayAddress
	li $t1, 0xffffff
	
	li $t2, 2616
	add $t2, $t2, $t9 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	
	
	li $t2, 2644
	add $t2, $t2, $t9 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 128 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, 4 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -128 
	sw $t1, ($t2)
	add $t2, $t2, -4 
	sw $t1, ($t2)
	
	jr $ra
 	
EXIT:
 	li $v0, 10
    syscall
 
