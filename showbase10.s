.text
.align 2
.global _start

@ ssize_t sys_write(unsigned int fd, const char * buf, size_t count)
@         r7                 r0      r1                r2
@==================================================
_start:
   

showbase10:

	mov     r0, #1         @ STDOUT
    	mov     r2, #1       @ Length
	LDR r11,=const
	LDR r11,[r11,#0]

	CMP r11,#0
	BGE skipminus
	LDR r1,=minussign
	MOV r7,#4
	SWI 0
	LDR r1,=showb10out
	CMP r11,#-10
	BGT exit3
	B   chkpt

skipminus:
	LDR r1,=showb10out	
	CMP r11,#10
	BLT exit3

chkpt:
	MOV r12,#10
	MOV r9,#0
	MOV R10,R11
	CMP R11,#0
	BGE divplus
divminus:
	CMP r10,#-10
	BGT endpt
	SDIV r10,r10,r12
	ADD r9,r9,#1
	B divminus
divplus:
	CMP r10,#10
	BLT endpt
	SDIV r10,r10,r12
	ADD r9,r9,#1
	B divplus
endpt:
	MOV r12,#0
	MOV r8,#10
	MOV r7,#1
chkpt1:
	CMP r12,r9
	BGE exit2
	MUL r10,r7,r8
	MOV r7,r10
	ADD r12,r12,#1
	B chkpt1
exit2:
	SUB	R9,R9,#1
	PUSH	{R9}
	SDIV r12,r11,r10
	MOV 	r9,r12
	CMP	R9,#0
	BGE	skipinv
	MOV	r7,#-1
	MUL	R9,R7,R9
skipinv:
	MOV     R7, #4 
	add	R9,R9,#0x30
	STRB	R9,[R1]
	swi 	0
	ADD	r1,r1,#1
	MUL	r7,r10,r12
	
	CMP	R7,#0
	BGE	skipaddnum
	MOV	r12,#-1
	MUL	R7,R12,R7
	ADD	R11,R11,R7
	B	chkpt2
skipaddnum:
	SUB	r11,r11,r7

chkpt2:
	CMP	R11,#0
	BGT	chknumplus
	BLT	chknumminus
	POP	{R9}
	MOV	R10,#0x30
	STRB	R10,[R1]
	MOV	R7,#4
	MOV	R12,#0
printlead0:
	CMP	R12,R9
	BEQ	exit3
	SWI	0
	ADD	R12,R12,#0x1
	B	printlead0

chknumminus:
	POP	{R9}
	MOV	R12,#0
	MOV	R9,#-1
	MUL	R10,R9,R10
	MOV	R9,#10
betwzero2:
	CMP	R11,R10
	BLE	exbetwzero2
	SDIV	R10,R10,R9
	ADD	R12,R12,#1
	B	betwzero2
exbetwzero2:
	MOV	R9,#1
	MOV	R10,#0x30
	STRB	R10,[R1]
	MOV	R7,#4
printbetz2:
	CMP	R9,R12
	BEQ	chknummnchkpt
	SWI	0
	ADD	R9,R9,#0x1
	B	printbetz2
chknummnchkpt:
	CMP	R11,#-10
	BGE	exit3
	B	chkpt


chknumplus:
	POP	{R9}
	MOV	R12,#0
	MOV	R9,#10
betwzero1:
	CMP	R11,R10
	BGE	exbetwzero1
	SDIV	R10,R10,R9
	ADD	R12,R12,#1
	B	betwzero1
exbetwzero1:
	MOV	R9,#1
	MOV	R10,#0x30
	STRB	R10,[R1]
	MOV	R7,#4
printbetz1:
	CMP	R9,R12
	BEQ	chknumplchkpt
	SWI	0
	ADD	R9,R9,#0x1
	B	printbetz1
chknumplchkpt:
	CMP	R11,#10
	BLE	exit3
	B	chkpt

	

exit3:
	CMP	R11,#0
	BGE	skipinv2
	MOV	R7,#-1
	MUL	R11,R7,R11
skipinv2:
	mov     r7, #4
	add	r11,r11,#0x30
	STRB	r11,[r1]
	swi 	0
	@MOV 	PC,LR
	@==================================================
@ int sys_exit(int status)
@     r7       r0
    mov     r0, #0          @ Return code
    mov     r7, #1          @ sys_exit
    svc     0

.align 2
.data
showb16out:
    .byte 48,120,1
showb10out:
    .byte 1
minussign:
    .byte 45
const:
    .word 101
