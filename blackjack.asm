.data
	#action prompt
	ActionPrompt: .asciiz "Enter h (hit) or s (stand): "

	#used to before showing hand
	HandInd: .asciiz "Hand: "
	DHandInd: .asciiz "Dealer's Hand: "

	#Used before showing hand values
	ValueInd: .asciiz "Value: "
	newline: .asciiz "\n"
	
	#Some space to hold a player and dealer's hand string
	PlyHand: .space 128
	DealerHand: .space 128
	#Used for getting Player's input
	PlyInput: .space 2
	
	#Messages
	WinMsg: .asciiz "You win!"
	ReasonMsg: .asciiz "Bust out!\n"
	LoseMsg: .asciiz "The dealer wins!"
	TieMsg: .asciiz "Dealer & player tie!"

.text
#$k0 is the Players hand value & $k1 is the dealers
li $k0 0
li $k1 0

#shuffle the deck before starting
jal shuffle

#Load their Hand space
la $s1, DealerHand
la $s2, PlyHand

#deal out a card
jal deal
    
move $a0, $v0 #move the card string into $a0
move $a1, $s1 #move the Dealer's space int $a1
jal store_string #append $a0 into $a1
move $s1, $a1 #$a1 points to the last inserted char after function we move it to $s1

addi $sp, $sp, -8 #decrement stack pointer by 8 bytes for function call
sw $ra, 0($sp) #store the return address into first 4 bytes
sw $a0, 4($sp) #store the popped card string
    
jal getCardVal
    
addi $sp, $sp, 8 #Restore the stack pointer back to original offset

move $t0, $v0 #move the card value int to $t0
add $k1, $k1, $t0 #add the card value to their Hand Vale Var

#Print Dealer Hand Indicator
li $v0, 4
la $a0, DHandInd
syscall

#Print the Dealers current hand
la $a0, DealerHand
syscall

#Print Value Indicator
la $a0, ValueInd
syscall

#Print the Dealers hand value
li $v0, 1
move $a0, $k1
syscall

#Print Newline x2
li $v0, 4
la $a0, newline
syscall
syscall

GameLoop:
    #deal card to player
    jal deal
    
    #store the card string into PlyHand space
    move $a0, $v0
    move $a1, $s2
    jal store_string
    move $s2, $a1
    
    addi $sp, $sp, -8 #decrement stack pointer by 8 bytes for function call
    sw $ra, 0($sp) #store the return address into first 4 bytes
    sw $a0, 4($sp) #store card string pointer
    
    jal getCardVal
    
    addi $sp, $sp, 8 #Restore the stack pointer back to original offset

    move $t0, $v0 #move card value into $t0
    add $k0, $k0, $t0#increment player's hand value
    
    #print hand indicator
    li $v0, 4

    la $a0, HandInd
    syscall
    #print hand data
    la $a0, PlyHand
    syscall
    #print value indicator
    la $a0, ValueInd
    syscall
    #print hand value
    li $v0, 1
    move $a0, $k0
    syscall
    #print newline
    li $v0, 4
    la $a0, newline
    syscall
    
    #if the new value is 21 then it's the dealers turn
    beq $k0, 21, DealerLoop
    #We busted out
    bgt $k0, 21, BustOut
    
    #Print the Action Prompt
    la $a0, ActionPrompt
    syscall

    li $v0, 8 #take in input
    la $a0, PlyInput #load space
    li $a1, 2 #store the space
    move $t0, $a0 #move string to $t0
    syscall
    #Newline
    li $v0, 4
    la $a0, newline
    syscall
    
    #Read the char byte if it's not h then its the Dealer's turn
    lb $t1, 0($t0)
    bne $t1, 'h', DealerLoop
    
    j GameLoop
DealerLoop:

    jal deal
    
    move $a0, $v0
    move $a1, $s1
    jal store_string
    move $s1, $a1
    
    addi $sp, $sp, -8 #decrement stack pointer by 8 bytes for function call
    sw $ra, 0($sp) #store the return address into first 4 bytes
    sw $a0, 4($sp) #store the card string
    
    jal getCardVal
    
    addi $sp, $sp, 8 #Restore the stack pointer back to original offset

    move $t0, $v0
    add $k1, $k1, $t0 #increment dealer's hand value
    
    #The Dealer stands at 17
    bge  $k1, 17, CalculateWinner
    j DealerLoop
BustOut:
    #Player Lost through bust out
    li $v0, 4
    la $a0, ReasonMsg
    syscall
    la $a0, LoseMsg
    syscall
    j stop
CalculateWinner:
    #Player didn't bust out
    li $v0, 4
    la $a0, newline
    syscall
    #print the hand indicator
    la $a0, DHandInd
    syscall
    #Print Dealer's final hand
    la $a0, DealerHand
    syscall
    #print the value indicator
    la $a0, ValueInd
    syscall
    
    #print the dealers hand value
    li $v0, 1
    move $a0, $k1
    syscall
    #newLine
    li $v0, 4
    la $a0, newline
    syscall
    
    #Player wins if their hand value is greater than the dealers or is 21
    bgt $k1, 21 PlyWins
    bgt $k0, $k1 PlyWins
    #Tie if they have equal value
    beq $k0, $k1 Tie
    #print the lose message
    la $a0, LoseMsg
    syscall
    b stop
    PlyWins:
        #print the win message
        la $a0, WinMsg
        syscall
        b stop
    Tie:
        #print the tie message
        la $a0, TieMsg
        syscall
stop:
# terminate the program 
li $v0, 10 
syscall

#function to append string into space
store_string:
    lb $t0, 0($a0)
    beq $t0, '0', append_10 #check if we need to prepend a 1
    store:
        sb $t0, 0($a1)
    
        lb $t0, 1($a0)
        sb $t0, 1($a1)
    
        li $t0, 32
        sb $t0, 2($a1)
    
        addi $a1, $a1, 3
        j fin
        append_10:
            #prepend a '1' char for 10 value card
            li $t1, 49
            sb $t1, 0($a1)
        
            addi $a1, $a1, 1 #point to next byte
            j store
   fin:
       jr $ra
