.text
.align 2
.global _start

@ ssize_t sys_write(unsigned int fd, const char * buf, size_t count)
@         r7                 r0      r1                r2

_start:
    LDR r1,=showb10out

showbase10:
	mov     r0, #1         @ STDOUT
    	mov     r2, #1       @ Length
	LDR r11,=const
	LDR r11,[r11,#0]
	CMP r11,#10
	BLT exit3
chkpt:
	MOV r12,#10
	MOV r9,#0
	MOV R10,R11
warp:
	CMP r10,#10
	BLT endpt
	SDIV r10,r10,r12
	ADD r9,r9,#1
	B warp
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
	BLE	exit3
	B	chkpt
exit3:
	mov     r7, #4         @ sys_write
	add	r11,r11,#0x30
	STRB	r11,[r1]
	swi 	0
	
@ int sys_exit(int status)
@     r7       r0
    mov     r0, #0          @ Return code
    mov     r7, #1          @ sys_exit
    svc     0


	
	
showbase16:
.align 2
.data
showb16out:
    .byte 48,120,1,1,1,1,1,1,1,1
showb10out:
    .byte 1
const:
    .word 44584528

