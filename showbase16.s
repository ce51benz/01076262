.text
.align 2
.global _start

@ ssize_t sys_write(unsigned int fd, const char * buf, size_t count)
@         r7                 r0      r1                r2
@==================================================
_start:
    LDR r1,=showprefix

showbase16:
	mov     r0, #1         @ STDOUT
    	mov     r2, #2         @ Length
	mov     r7, #4         @ sys_write
	SWI	0
	LDR r1,=showb16out
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
@==================================================
@ int sys_exit(int status)
@     r7       r0
    mov     r0, #0          @ Return code
    mov     r7, #1          @ sys_exit
    svc     0

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
showb16out:
    .byte 1
const:
    .word 1768

