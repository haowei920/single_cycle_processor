
factorial.s:
 .align 4
 .section .text
 .globl _start
 
_start:
		lw a0, number
		jal factorial
		j deadloop
factorial:
         # Register a0 holds the input value
         # Register t0-t6 are caller-save, so you may use them without saving
         # Return value need to be put in register a0
         # Your code starts here
		 #lw x10, number #x10 is ao and a0 holds the number
		 xor x5, x5, x5 #clear x5. x5 is t0
		 la x31, result
		 sw x10, 0(x31) #store input into result
		 addi x5, x5, 2
		 bge x5, x10, done # If x5>=x10 goto done
		 la x28, multiplicand #reg 28 contains address of multiplier 
		 sw x10, 0(x28) # multiplier currently contains the first multiplier value
		 la x28, multiplier
		 addi x10, x10, -1 # decrease x10 by 1
		 sw x10, 0(x28)#  multiplicand contains first multiplicand value


mul_loop:
		xor x28, x28, x28
		xor x29, x29, x29
		lw x6, multiplicand
		lw x7, multiplier
mul_loop_again:
		add x29, x29, x6
		addi x7, x7, -1
		beq x7, x28, mul_done
		beq x1, x1, mul_loop_again
mul_done:		
		la x5, temp
		sw x29, 0(x5)
		
big_loop:
	la x5, result
	lw x6, temp 
	sw x6, 0(x5)
	
	lw x5, multiplier
	addi x5,x5,-2 #if multiplier is 2 we dont need to continue le
	xor x31,x31,x31
	beq x5,x31,done
	la x28, multiplicand #temp value becomes multiplicand
	sw x6, 0(x28)
	la x28, multiplier
	lw x6, multiplier
	addi x6, x6, -1 #x6 value reduced by 1
	sw x6, 0(x28)
	beq x1,x1,mul_loop
	
done:
	lw x10, result
	

ret:
	jr ra # Register ra holds the return address
deadloop:
    beq x8, x8, deadloop		
.section .rodata
 # if you need any constants
number:    .word 0x8
multiplicand: .word 0x00000000 
multiplier: .word 0x00000000 
temp: .word 0x00000000 
result: .word 0x00000000 
