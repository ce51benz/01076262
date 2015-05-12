.text
.align 2
.global _start

_start:
   
    mov     r0, #0          @ Return code
    mov     r7, #1          @ sys_exit
    svc     0

showbase10:
	LDR r1,=showout
	mov     r0, #1         @ STDOUT
    	mov     r2, #1       @ Length
	LDR r11,=const
	LDR r11,[r11,#0]
	CMP r11,#10
	BLT sb10exit3
sb10chkpt:
	MOV r12,#10
	MOV r9,#0
	MOV R10,R11
sb10warp:
	CMP r10,#10
	BLT sb10endpt
	SDIV r10,r10,r12
	ADD r9,r9,#1
	B sb10warp
sb10endpt:
	MOV r12,#0
	MOV r8,#10
	MOV r7,#1
sb10chkpt1:
	CMP r12,r9
	BGE sb10exit2
	MUL r10,r7,r8
	MOV r7,r10
	ADD r12,r12,#1
	B sb10chkpt1
sb10exit2:
	SDIV r12,r11,r10
	@let this print to screen
	mov     r7, #4         @ sys_write
	MOV 	r9,r12
	add	r9,r9,#0x30
	STRB	r9,[r1]
	swi 	0
	ADD	r1,r1,#1
	MUL	r7,r10,r12
	SUB	r11,r11,r7
	CMP	r11,#10
	BLE	sb10exit3
	B	sb10chkpt
sb10exit3:
	mov     r7, #4         @ sys_write
	add	r11,r11,#0x30
	STRB	r11,[r1]
	swi 	0
	POP	{R0}
	POP	{R1}
	POP	{R2}
	POP	{R7}
	POP	{R8}
	POP	{R9}
	POP	{R10}
	POP	{R11}
	POP	{R12}
	MOV 	PC,LR
showbase16:
	LDR r1,=showprefix
	mov     r0, #1         @ STDOUT
    	mov     r2, #2         @ Length
	mov     r7, #4         @ sys_write
	SWI	0
	LDR r1,=showout
	MOV	R2,#1
	
	LDR r11,=const
	LDR r11,[r11,#0]
	MOV r12,#0xF
	LSL r12,r12,#28
	AND R10,R11,R12
	LSR R10,R10,#28
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#24
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#20
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#16
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#12
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#8
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	LSR R10,R10,#4
	BL numout
	LSR R12,R12,#4
	AND R10,R11,R12
	BL numout
	POP	{R0}
	POP	{R1}
	POP	{R2}
	POP	{R7}
	POP	{R10}
	POP	{R11}
	POP	{R12}
	MOV PC,LR


numout:
	CMP R10,#9
	BGT alphaput
	ADD R10,R10,#0x30
	B   putchkpt
alphaput:
	ADD R10,R10,#55	
putchkpt:
	STRB	r10,[r1]
	swi 	0	
	MOV PC,LR

.align 2
.data
showprefix:
    .byte 48,120
showout:
    .byte 1
const:
    .word 1768
