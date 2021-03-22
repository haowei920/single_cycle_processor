riscv_mp2test.s:
.align 4
.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    # Note that one/two/eight are data labels
    lw  x1, threshold # X1 <- 0x40
    lui  x2, 2       # X2 <= 2
    lui  x3, 8     # X3 <= 8

	lui  x12, 0   #X12 <= 0 << 12
	slti x5, x12, 12 #X5 = X12 < 12 ? 1 : 0
	xor x2,x2,x2
	lw x1, test
	la x2, test0
	sb x1, 0(x2)
	la x2, test1
	sb x1, 0(x2)
	la x2, test2
	sb x1, 0(x2)
	la x2, test3
	sb x1, 0(x2)
	
wrong:
	srai x12, x12, 1 #X12 <- X12 >> 1
	sltiu x11, x12,123 #X11 = X12 < 123 ? 1 : 0
	slti x11, x12, 123
	xori x20, x11, -1 #X20 <- X11 XOR #1111111111
	srai x19,x20,1 #X19 <- X20 >> 1 arithmetic shift
	srli x18,x20,1 #X18 <- X20 >> 1 logical shift
	ori x17, x20, 1 #x17 <- X20 OR #1
	slli x16, x20, 1 #X16 <- X20 << 1
	beq x17, x18, wrong # if x17 == x19 goto wrong
	bne x17, x19, wrong # if x17 != x19 goto wrong
	sub x15, x17, x19
	add x15, x17, x19
	xor x15, x17, x19
	or x15, x17, x19
	and x15, x17, x19
	sll x15, x17, x19
	srl x15, x17, x19
	#sra x15, x17, x19
	#slt x15, x17, x19
	#sltu x15, x17, x19
	#lw x21, bad
	#la x10, result
	#sw x21, 0(x10)
	#lw x23, result
	la x5, for_store
	jal x12, addfunction
	la x24, bad
	#addi x24, x24,1
	lhu x25,0(x24) 
	addi x24, x24,2
	lhu x25,0(x24)
	addi x24, x24,2
	lhu x25,0(x24)
	jalr x12,x13 , 244
	blt x17, x19, wrong # if x17 < x19 goto wrong
	bge x16, x18, wrong # if x16 >= x19 goto wrong
	bgeu x19, x18, loop1 # if x19 >= x18, go to loop1 
    addi x4, x3, 4    # X4 <= X3 + 4


addfunction:
	jalr x2, x5, 0
	addi x15,x15,1
loop1:
    slli x3, x3, 1    # X3 <= X3 << 1
    xori x5, x2, 127  # X5 <= XOR (X2, 7b'1111111)
    addi x5, x5, 1    # X5 <= X5 + 1
    addi x4, x4, 4    # X4 <= X4 + 4

    bleu x4, x1, loop1   # Branch based on x4 and x1

    andi x6, x3, 64   # X6 <= X3 + 64

    auipc x7, 8         # X7 <= PC + 8
    lw x8, good         # X8 <= 0x600d600d
    la x10, result      # X10 <= Addr[result]
    sb x8, 0(x10)       # [Result] <= 0x600d600d
    lw x9, result       # X9 <= [Result]
    bne x8, x9, deadend # PC <= deadend if x8 != x9
	


halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.
for_store:
	
	lw x8, bad
	lb x8, bad
	lbu x8,bad
	lh x8,bad
	lhu x8,bad
	la x2, bad
	addi x2,x2,1
	lb x8,0(x2)
	lbu x8, 0(x2)
	addi x2,x2,1
	lb x8, 0(x2)
	lbu x8, 0(x2)
	lh x8, 0(x2)
	lhu x8, 0(x2)
	addi x2,x2,1
	lb x8,0(x2)
	lbu x8, 0(x2)
#	xor x3,x3,x3
#	addi x3,x3,-1
#	addi x2,x2,2
#	sh x3, 0(x2)
#	lw x4, test
					

deadend:
    lw x8, bad     # X8 <= 0xdeadbeef
deadloop:
    beq x8, x8, deadloop

.section .rodata

bad:        .word 0xdeadbeef
threshold:  .word 0x00000040
result:     .word 0x00000000
good:       .word 0x600d600d
test:       .word 0x12345678
test0:      .byte 0xff
test1:		.byte 0xff
test2:		.byte 0xff
test3:		.byte 0xff
