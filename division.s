.global _start

division:
	
	# Salvado de registros en la pila
	addi sp, sp, -4
	stw ra, 0(sp)
	
	addi sp, sp, -8
	stw r8, 4(sp)
	stw r9, 0(sp)
	
	movi r2, 0		# C
	mov r3, r4		# R
	
	ble r5, r0, findivision		# B > 0
	blt r4, r5, findivision		# a >= b
	
for:
	
	mov r8, r5		# X = B
	movi r9, 1		# Ctemp = 1
	
mientras:

	bgt r8, r3, finmientras		# X <= R
	slli r8, r8, 1				# X << 1
	slli r9, r9, 1				# Ctemp << 1
	
	jmpi mientras
	
finmientras:
	
	srli r8, r8, 1				# X >> 1
	srli r9, r9, 1				# Ctemp >> 1
	
	sub r3, r3, r8				# R = R - X
	add r2, r2, r9				# C = C + Ctemp
	
	bge r3, r5, for				# R >= b
	
findivision:
	
	ldw r9, 0(sp)
	ldw r8, 4(sp)
	
	addi sp, sp, 8
	ldw ra, 0(sp)
	addi sp, sp, 4
	
	ret

_start:

	movia sp, pila
	movi r4, 12		# A
	movi r5, 5		# B
	call division
	movia r8, cociente
	stw r2, 0(r8)
	movia r8, resto
	stw r3, 0(r8)
	
	jmpi stop
	
stop: jmpi stop




.data

cociente: 	.skip 4
resto:		.skip 4

	.skip 512
pila:
	