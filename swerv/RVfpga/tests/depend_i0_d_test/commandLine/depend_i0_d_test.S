.globl _start
_start:

# Register t3 is also called register 28 (x28)
li t3, 0x1					# t3 = 1

REPEAT:
	MUL t3, t3, t3			# t3 = t3 * t3
	mul t3, t3, t3		    # t3 = t3 * t3
	mul t3, t3, t3			# t3 = t3 * t3
	mul t3, t3, t3			# t3 = t3 * t3
	beq  zero, zero, REPEAT	# Repeat the loop
    nop

.end
