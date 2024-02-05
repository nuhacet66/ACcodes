.global _start

.equ Jtag, 0x10001000
#=======================================================
r_read_char:

	subi sp, sp, 12
	stw r4, 0(sp)
	stw r6, 4(sp)
	stw ra, 8(sp)
	movia r4, Jtag
	
rrc_espera:
 
	ldwio r2, 0(r4)
	andi r6, r2, 0x8000
	beq r6, r0, rrc_espera
	andi r2, r2, 0x0ff #se queda con el caracter
	ldw r4, 0(sp)
	ldw r6, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret
	
#=======================================================
r_write_char:

	 subi sp, sp, 12
	 stw r4, 0(sp)
	 stw r6, 4(sp)
	 stw ra, 8(sp)
	 movia r4, Jtag
	 
rwc_espera:

	ldwio r6, 4(r4)
	andhi r6, r6, 0xFFFF
	srli r6, r6, 16
	beq r6, r0, rwc_espera
	stbio r5, 0(r4)
	ldw r4, 0(sp)
	ldw r6, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret
	
#======================================================= 
leer_con_eco:

	subi sp, sp, 8
	stw r5, 0(sp)
	stw ra, 4(sp)
	call r_read_char
	mov r5, r2
	call r_write_char
	ldw r5, 0(sp)
	ldw ra, 4(sp)
	addi sp, sp, 8
	ret
	
#=======================================================
lee_entero_positivo:

	subi sp, sp, 16
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	stw r10, 12(sp)
	
mientras1:

	call leer_con_eco
	mov r8, r2
	movi r9, 48 # "0"
	blt r8, r9, mientras1
	movi r9, 57 # "9"
	bgt r8, r9, mientras1

	subi r10, r8, 48 #48 es el codigo ascii del cero 
	
mientras2:

	call leer_con_eco
	mov r8, r2
	movi r9, 48 # "0"
	blt r8, r9, finmientras
	movi r9, 57 # "9"
	bgt r8, r9, finmientras
	# muli r10, r10, 10 #para ejecutar en DE0-nano hay que cambiar esta instrucción
	mov r4, r10
	movi r5, 10
	call multiplicacion
	mov r10, r2
	add r10, r10, r8 #por una llamada a la rutina multiplica
	subi r10, r10, 48 #48 es el codigo ascii del cero
	jmpi mientras2
	
finmientras:

	mov r2, r10
	ldw ra, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	ldw r10, 12(sp)
	addi sp, sp, 16
	ret
	
#==============================================================
imprime_entero_positivo: #el entero viene en r5

	subi sp, sp, 16
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	stw r10, 12(sp)
	movi r10, 0
	
iep_mientras:
	
	mov r11, r5
	beq r5, r0, iep_finmientras 
	movi r8, 10
	# div r9, r5, r8 #para ejecutar en DE0 hay que cambiar estas instrucciones
	mov r4, r5
	mov r5, r8
	call division
	mov r9, r2
	# mul r8, r9, r8 #por llamadas a la rutina div (en r9 cociente, en r8 resto)
	mov r4, r9
	mov r5, r8
	call multiplicacion
	mov r8, r2
	mov r5, r11
	
	sub r8, r5, r8
	mov r5, r9
	subi sp, sp, 4
	stw r8, 0(sp)
	addi r10,r10, 1
	jmpi iep_mientras
	
iep_finmientras:

iep2_mientras:

	beq r10, r0, fin_iep2mientras
	ldw r5, 0(sp)
	addi r5, r5, 48 # "0"
	call r_write_char
	addi sp, sp, 4
	subi r10, r10, 1
	jmpi iep2_mientras
	
fin_iep2mientras:

	ldw ra, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	ldw r10, 12(sp)
	addi sp, sp, 16
	ret

imprimir_string:

	subi sp, sp, 12
	stw r4, 0(sp)
	stw r6, 4(sp)
	stw ra, 8(sp)

	mov r4, r5
	
rep:

	ldb r5, 0(r4)
	beq r5, r0, imp_fin
	call r_write_char
	addi r4, r4, 1
	jmpi rep
		
imp_fin:

	ldw r4, 0(sp)
	ldw r6, 4(sp)
	ldw ra, 8(sp)
	addi sp, sp, 12
	ret
	
# -------------------------Cuenta el número de milisegundos transcurridos.------------
.equ Timer, 0x10002000

.section .reset, "ax"
jmpi _start

.section .exceptions, "ax"
.global _manejador_interrupciones

_manejador_interrupciones:

	addi sp, sp, -4
	stw et, 0(sp) /* guardar et en la pila */
	rdctl et, ctl4 /* leer registro de interrupciones pendientes */
	beq et, r0, noINT 
	subi ea, ea, 4 /* interrupción activada, se decrementa ea */
	subi sp, sp, 12 /* guardar registros en la pila */
	stw ea, 4(sp)
	stw ra, 8(sp)
	stw r2, 12(sp)
	andi r2, et, 0b01 /* se comprueba si la interrupción TIMER se ha activado */
	beq r2, r0, FIN /* salta a FIN si no se ha activado interrupción IRQ #1 */
	call Timer_cuenta /* IRQ#1 activada, salta a rutina descrita en la siguiente transparencia */
	
FIN:

	ldw ea, 4(sp) /* recuperar registros de la pila */
	ldw ra, 8(sp)
	ldw r2, 12(sp)
	addi sp, sp, 12
	
noINT:

	ldw et,0(sp)
	addi sp,sp,4 /* recuperar et de la pila */
	eret
	
.text
.global Timer_cuenta

Timer_cuenta:

	subi sp, sp, 12
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	movia r8, CUENTA_INTERRUPCION
	ldw r9, 0(r8)
	addi r9, r9, 1
	stw r9, 0(r8)
	movia r8, Timer
	stwio r0, 0(r8) 
	ldw ra, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	addi sp, sp, 12
	ret
	
.data
CUENTA_INTERRUPCION: .skip 4

.text
iniciar_cuenta:

	subi sp, sp, 12
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	movia r8, CUENTA_INTERRUPCION
	stw r0, 0(r8)
	movia r8, Timer
	movia r9, 50000
	stwio r9, 8(r8)
	srli r9, r9, 16
	stwio r9, 12(r8)
	stwio r0, 0(r8)
	rdctl r9, ienable
	ori r9, r9, 1
	wrctl ienable, r9
	rdctl r9, status
	ori r9, r9, 1
	wrctl status, r9 
	movi r9, 7
	stwio r9, 4(r8)
	ldw ra, 0(sp)
	ldw r8, 4(sp)
	ldw r9, 8(sp)
	addi sp, sp, 12
	ret
	
parar_cuenta:

	subi sp, sp, 12
	stw ra, 0(sp)
	stw r8, 4(sp)
	stw r9, 8(sp)
	movia r8, Timer
	movi r9, 8
	stwio r9, 4(r8)
	rdctl r9, ienable
	movia r8, 0xFFFFFFFE
	and r9, r9, r8
	wrctl status, r9
	rdctl r9, status
	movia r8, 0xFFFFFFFE
	and r9, r9, r8
	wrctl status, r9
	movia r8, CUENTA_INTERRUPCION
	ldw r2, 0(r8)
	ldw ra, 0(sp)
	ldw r8, 4(sp) 
	ldw r9, 8(sp)
	addi sp, sp, 12
	ret


#################################### Subrutina de multiplicación ###############################################################

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
	 
	 
#################################### Subrutina de división ###############################################################

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
	
for_d:
	
	mov r8, r5		# X = B
	movi r9, 1		# Ctemp = 1
	
mientras_d:

	bgt r8, r3, finmientras_d		# X <= R
	slli r8, r8, 1				# X << 1
	slli r9, r9, 1				# Ctemp << 1
	
	jmpi mientras_d
	
finmientras_d:
	
	srli r8, r8, 1				# X >> 1
	srli r9, r9, 1				# Ctemp >> 1
	
	sub r3, r3, r8				# R = R - X
	add r2, r2, r9				# C = C + Ctemp
	
	bge r3, r5, for_d				# R >= b
	
findivision:
	
	ldw r9, 0(sp)
	ldw r8, 4(sp)
	
	addi sp, sp, 8
	ldw ra, 0(sp)
	addi sp, sp, 4
	
	ret
	 

#################################### Subrutina de producto escalar ###############################################################


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

####################################################################################
	# Print del enunciado #
	movia r5, text1
	call imprimir_string

	movi r5, 10
	call r_write_char		# Salto de línea
	movi r5, 10
	call r_write_char		# Salto de línea
	
	# Print M #
	movia r5, text2
	call imprimir_string
	
	movia r23, m
	call lee_entero_positivo
	stw r2, 0(r23)

	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	# Print N #
	movia r5, text3
	call imprimir_string
	
	movia r23, n
	call lee_entero_positivo
	stw r2, 0(r23)

	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	# Print P #
	movia r5, text4
	call imprimir_string
	
	movia r23, p
	call lee_entero_positivo
	stw r2, 0(r23)

	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	# Input valores de las Matrices #
	# Matriz 1 #
	
	movia r5, text5
	call imprimir_string
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r16, matriz1
	
	movia r17, m
	ldw r17, 0(r17)
	movia r18, n
	ldw r18, 0(r18)
	
	movi r19, 0		# i = 0, Contador para introducir los valores

input_m1:

	bge r19, r17, init_m2
	movi r20, 0		# j = 0

for_m1:

	bge r20, r18, finM1
	call lee_entero_positivo
	stw r2, 0(r16)			# Guardamos valor
	addi r16, r16, 4		# Incrementamos puntero Matriz1
	addi r20, r20, 1		# j++
	jmpi for_m1
	
finM1:
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	
	addi r19, r19, 1
	jmpi input_m1
	
	# Matriz 2 #
	
init_m2:
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r5, text6
	call imprimir_string
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r16, matriz2
	
	movia r17, n
	ldw r17, 0(r17)
	movia r18, p
	ldw r18, 0(r18)
	
	movi r19, 0		# i = 0, Contador para introducir los valores
	
input_m2:

	bge r19, r17, init_mm
	movi r20, 0		# j = 0

for_m2:

	bge r20, r18, finM2
	call lee_entero_positivo
	stw r2, 0(r16)			# Guardamos valor
	addi r16, r16, 4		# Incrementamos puntero Matriz2
	addi r20, r20, 1		# j++
	jmpi for_m2
	
finM2:
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	
	addi r19, r19, 1
	jmpi input_m2
	
	
	

init_mm:	
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
###############################################################################################
	call iniciar_cuenta
	# Multiplicación de matrices #
	
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
	slli r7, r21, 2					# r7 = 4P
	
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
	
	slli r22, r20, 2				# 4*N
	add r16, r16, r22				# F1 = F1 + 4*N
	
	addi r15, r15, 1				# i++
	jmpi para_matriz1
	
fin_para_matriz1:
	
	call parar_cuenta
	mov r7, r2
	
###################################################################################################

	# Print Matriz Resultante (MxP) #
	
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r5, text7
	call imprimir_string
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r8, m
	ldw r8, 0(r8)	# r8 = m
	movia r9, p
	ldw r9, 0(r9)	# r9 = p
	
	movia r10, matrizR
	
	movi r15, 0		# r15 = i = 0


print_mr:

	beq r15, r8, fin_print_mr
	movi r14, 0		# r14 = j = 0
	
print_c_mr:
	
	beq r14, r9, fin_print_c_mr
	
	ldw r5, 0(r10)	# Cargamos un elemento de la matriz R
	call imprime_entero_positivo
	movia r5, space
	call imprimir_string
	
	addi r10, r10, 4 	# Incrementamos puntero de la matriz R
	addi r14, r14, 1	# j++
	
	jmpi print_c_mr
	
fin_print_c_mr:
	
	# Pasamos a la siguiente fila
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	addi r15, r15, 1		# i++
	jmpi print_mr
	
fin_print_mr:
	
	movi r5, 10
	call r_write_char		# Salto de línea
	
	movia r5, text8
	call imprimir_string
	
	beq r7, r0, print_zero
	mov r5, r7
	call imprime_entero_positivo
	
	movia r5, text9
	call imprimir_string
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	jmpi stop

print_zero:
	
	movia r5, text0
	call imprimir_string
	
	movia r5, text9
	call imprimir_string
	
	movi r5, 13
	call r_write_char		# Retorno de carro
	movi r5, 10
	call r_write_char		# Salto de línea
	
	
stop:
	
	jmpi stop
	


.data

text1:		.ascii "           Multiplicacion de Matrices - Raul Mateus Sanchez"
			.byte 0
			
text2:		.ascii "Introduzca M, el numero de filas de la Matriz1: "
			.byte 0
			
text3:		.ascii "Introduzca N, el numero de columnas de la Matriz1: "
			.byte 0
			
text4:		.ascii "Introduzca P, el numero de filas de la Matriz2: "
			.byte 0
			
text5:		.ascii "Introduzca los valores de su Matriz1 separados por un espacio: "
			.byte 0
			
text6:		.ascii "Introduzca los valores de su Matriz2 separados por un espacio: "
			.byte 0

text7:		.ascii "La matriz resultante de multiplicar M1 y M2 es: "
			.byte 0
			
text8:		.ascii "Tiempo de ejecucion: "
			.byte 0
			
text9:		.ascii " ms"
			.byte 0
			
text0:		.ascii "0"
			.byte 0

space:		.ascii " "
			.byte 0
			.align 2
			
matriz1: 	.skip 100*4
matriz2: 	.skip 100*4
matrizR:	.skip 100*4
m:			.word 3
n:			.word 3
p:			.word 3

			.skip 512
pila:
	