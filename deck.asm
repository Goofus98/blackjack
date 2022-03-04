.data 
	Card: .space 3 #space to hold a Card Name
	Deck: .asciiz "2S","2C","2D","2H",
            "3S","3C","3D","3H",
            "4S","4C","4D","4H",
            "5S","5C","5D","5H",
            "6S","6C","6D","6H",
            "7S","7C","7D","7H",
            "8S","8C","8D","8H",
            "9S","9C","9D","9H",
            "0S","0C","0D","0H", #the 10 value cards
            "JS","JC","JD","JH",
            "QS","QC","QD","QH",
            "KS","KC","KD","KH",
            "AS","AC","AD","AH"
.text
.globl shuffle
.globl deal
.globl getCardVal


#private function to index the deck string for a card string
index:
    lw $s0, 4($sp) #get the index we want to return
    la $t7, Deck #point to the begining of the deck
    beq $s0, $zero, end #if its the first card then just return $t7
    loop:
        lb $t1, 0($t7) #get the char of current card in deck
        addi $t7, $t7, 1#have $t7 point to the next char
        beq $t1 $zero decrement #if we reached the end of the card string length then decrement index count

        j loop

        decrement:
            subi $s0, $s0, 1
            beq $s0, $zero, end #if 0 then $t7 now points to the begining of the string we want
            j loop
    end:
        move $v0, $t7 #move string to v0
        jr $ra #jump back to the return address

#shuffles the deck using Fisher–Yates shuffle
shuffle:
    li $a1, 51 #hold the number of cards - 1. This is out counter
    shuff_loop:
    	beq $a1, 2, done #we finished shuffling

	li $v0, 42  #generates the random number 0 - counter.
	syscall

	move $s0, $a0 #random number moved to $s0

        addi $sp, $sp, -8 #decrement stack pointer by 8 bytes for function call
	sw $ra, 0($sp) #store the return address into first 4 bytes
	sw $s0, 4($sp) #store the random num for argument

	jal index #index the deck for random number

	#post function
	lw $ra, 0($sp) #load the ra from stack pointer into $ra
	addi $sp, $sp, 8 #Restore the stack pointer back to original offset

	move $t0, $v0 #move the string pointer to $t0
	
	addi $sp, $sp, -8 #decrement stack pointer by 8 bytes for function call
	sw $ra, 0($sp) #store the return address into first 4 bytes
	sw $a1, 4($sp) #store the current counter number

	jal index #index the deck for current counter

	#post function
	lw $ra, 0($sp) #load the ra from stack pointer into $ra
	addi $sp, $sp, 8 #Restore the stack pointer back to original offs
	
	move $t2, $v0 #store the pointer to return string in $t2
	
	#swap the contents of the strings
	lb $t3, 0($t0)
	lb $t4, 0($t2)
	
	sb $t3, 0($t2)
	sb $t4, 0($t0)
	
	lb $t3, 1($t0)
	lb $t4, 1($t2)
	
	sb $t3, 1($t2)
	sb $t4, 1($t0)
	
	subi $a1, $a1, 1 #decrement the counter
	j shuff_loop
    done:
	jr $ra #jump back to the return address in main
	
#Pops a card from the deck
deal:
    la $t0, Deck #load the first string of deck
    la $v0, Card #load the CArd space to write to
    find:
    	lb $t1, 0($t0)
    	bne $t1 $zero ret # we found the next card to pop
        addi $t0 $t0 1 # point ot next char
        j find
    ret:
        #write the string data to Card space
        lb $t2, 0($t0)
        sb $t2, 0($v0)
        
        lb $t2, 1($t0)
        sb $t2, 1($v0)
	
	#set the string in Deck to null
	sb $zero, 0($t0)
	sb $zero, 1($t0)

        jr $ra #jump back to the return address

#Returns a cards int value. Takes a Card string as argument     
getCardVal:
    lw $t0, 4($sp)#Load the string
    deduce:
    	lb $t1, 0($t0)
    	#We only need to read the first Char to deduce
	beq $t1, '0', ret10
	beq $t1, 'J', ret10
	beq $t1, 'Q', ret10
	beq $t1, 'K', ret10
	beq $t1, 'A', ret11
 	
 	#the card is not the above suits then we andi w/ 0x0F the char digit to return an int value
 	andi $t1, $t1, 0x0F
 	
     	j ret_int
    ret10:
    	li $t1, 10
    	b ret_int
    ret11:
    	li $t1, 11
    	b ret_int
    ret_int:
	move $v0, $t1 #move the int into $v0
        jr $ra #jump back to the return address
