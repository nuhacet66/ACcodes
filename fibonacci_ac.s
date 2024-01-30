.text
.global FIBONACCI
FIBONACCI:
	subi sp, sp,24 /*reserva de espacio para el stack*/
	stw r4, 0(sp)
	stw r4, 2(sp)
	stw r4, 4(sp)
	stw r4, 8(sp)
	stw r4, 12(sp)
	stw r4, 16(sp)
	stw r4, 20(sp)
	
	movi r4, 0
	movi	r5, 1024 /*p*/
	
LOOP:
	bge r4, r5, STOP
	ldb r0, V(r4)
	addi r4, r4, 1 /*x*/
	br LOOP
	
	
STOP:
	ldw r4, 0(sp)
	ldw r4, 2(sp)
	ldw r4, 4(sp)
	ldw r4, 8(sp)
	ldw r4, 12(sp)
	ldw r4, 16(sp)
	ldw r4, 20(sp)
	
	ret
.data
V:
		.skip 65536
N:
		.word 8
NUMBERS:
		.word 0, 1
RESULT:
		.skip 32
.end		
	