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
	 
	 
				# (vector1, salto, vector2, salto, tamaño)
producto_escalar:
	
	# Salvado de registros en la pila
	addi sp, sp, -4
	stw fp, 0(sp)	# Puntero a parámetros pasados por pila
	mov fp, sp
	
	addi sp, sp, -32
	stw r15, 0(sp)
	stw r14, 4(sp)
	stw r12, 8(sp)
	stw r11, 12(sp)
	stw r10, 16(sp)
	stw r9, 20(sp)
	stw r8, 24(sp)
	stw ra, 28(sp)
	
	mov r8, r4			# Vector1
	mov r9, r5			# Salto Vector1
	mov r10, r6			# Vector2
	mov r11, r7			# Salto Vector2
	ldw r12, 4(fp)		# Tamaño
	
	movi r14, 0		# R = 0
	movi r15, 0		# i = 0
	
para:
	
	bge r15, r12, finpara		# Para i = 0 hasta N-1
	
	ldw r4, 0(r8)
	add r8, r8, r9				# Vector1 += salto1
	ldw r5, 0(r10)
	add r10, r10, r11			# Vector2 += salto2
	
	call multiplicacion
	bne r3, r0, fail			# Comprobamos que no existe desbordamiento
	
	add r14, r14, r2			# R += call multiplicar
	addi r15, r15, 1			# i++
	
	jmpi para
	

finpara:
	
	mov r2, r14					# Movemos R al registro r2, para devolverlo
	ldw r15, 0(sp)
	ldw r14, 4(sp)
	ldw r12, 8(sp)
	ldw r11, 12(sp)
	ldw r10, 16(sp)
	ldw r9, 20(sp)
	ldw r8, 24(sp)
	ldw ra, 28(sp)
	
	addi sp, sp, 32
	ldw fp, 0(sp)
	
	addi sp, sp, 4
	ret
	
fail:
	
	addi r15, r15, 1	#i++
	jmpi para

_start:
	
	movia sp, pila
	movia r16, matriz1		# F1 = Matriz1
	movia r18, matrizR		# r18 = MatrizR
	
	movia r19, m
	ldw r19, 0(r19)			# r19 = m
	movia r20, n
	ldw r20, 0(r20)			# r20 = n
	movia r21, p
	ldw r21, 0(r21)			# r21 = p
	
	movi r15, 0				# i = 0
	
para_matriz1:
	
	bge r15, r19, fin_para_matriz1	# i = 0 hasta M-1
	movia r17, matriz2				# C2 = Matriz2
	
	movi r14, 0						# j = 0
	
para_matriz2:

	bge r14, r21, fin_para_matriz2	# j = 0 hasta P-1
	mov r4, r16						# r4 = F1
	movi r5, 4						# r5 = 4
	mov r6, r17						# r6 = C2
	muli r7, r21, 4					# r7 = 4P
	
	addi sp, sp, -4
	stw r20, 0(sp)					# Pasamos por pila N
	
	call producto_escalar

save_matrizr:
	
	stw r2, 0(r18)					# Guardamos el resultado del producto escalar en la matrizR
	addi r18, r18, 4				# Incrementamos el puntero al vector matrizR
	addi r17, r17, 4				# Incrementamos el puntero al vector matriz2
	
	addi r14, r14, 1				# j++
	jmpi para_matriz2

fin_para_matriz2:
	
	muli r22, r20, 4				# 4*N
	add r16, r16, r22				# F1 = F1 + 4*N
	
	addi r15, r15, 1				# i++
	jmpi para_matriz1
	
fin_para_matriz1:
	
stop:
	
	jmpi stop
	



.data

matriz1: 	.word 1, 1, 1, 1, 1, 1, 1, 1, 1
matriz2: 	.word 1, 1, 1, 1, 1, 1, 1, 1, 1
matrizR:	.skip 40
m:			.word 3
n:			.word 3
p:			.word 3

			.skip 512
pila:
	
	