.text
.align 2
.global _start

_start:

@R10-12 as param
@Premise, there is already keeping value for each instruction
modulus: 
    SDIV R10,R12,R11
    MUL  R11,R10,R11
    SUB	 R12,R12,R11

minus:
	MVN R0,R0
	ADD R0,R0,#1

addn:
	ADD R0,R1,R2

subn:
	SUB R0,R1,R2

muln:
	MUL R0,R1,R2

divn:
	SDIV R0,R1,R2

Assignment:
	MOV R0,R1

.align 2
