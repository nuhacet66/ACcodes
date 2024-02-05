.global _start

multiplicacion:
	
	# Salvado de registros en la pila
	addi sp, sp, -4
	stw ra, 0(sp)
	addi sp, sp, -16
	stw r4, 12(sp)
	stw r5, 8(sp)
	stw r8, 4(sp)
	stw r9, 0(sp)
	
	movi r2, 0		# R / R = 0
	movi r3, 0		# Indicador de desbordamiento
	movia r8, 0x80000000
	

	beq r5, r0, finsi			# B != 0
	
mientras:

	ble r5, r0, finsi			# B > 0
	andi r9, r5, 1
	beq r9, r0, finsi1			# (bit0 de B) = 1
	add r2, r2, r4				# R = R+a
	
finsi1:

	and r9, r2, r8
	beq r9, r0, finsi2			# Bit más significativo de R a 1
	movi r3, 1					# Indicamos desbordamiento
	
finsi2:

	srli r5, r5, 1
	slli r4, r4, 1
	jmpi mientras
	
	
finsi:
	
	 ldw r4, 12(sp)
	 ldw r5, 8(sp)
	 ldw r8, 4(sp)
	 ldw r9, 0(sp)
	 addi sp, sp, 16
	 ldw ra, 0(sp)
	 addi sp, sp, 4
	 ret
	
	

_start:

	movia sp, pila
	movi r4, 2 			# A
	movi r5, 3			# B
	call multiplicacion
	bne r3, r0, fail
	jmpi stop

fail:

	movi r2, 404

stop: jmpi stop



.data
	.skip 512
pila:
	
	