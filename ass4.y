%{
#include<stdio.h>
#include<glib.h>
#include<math.h>
void yyerror(char *);

// Node structure
typedef struct _node{
 	struct _node *left;
	struct _node *right;
	int ttype;
	char* lexame;
}NODE;

// Variable Structure
typedef struct _varstat{
	int regid;
	int stat;
	int stoffset;
}VARSTAT;
int traversetree(NODE *); 	// Function to traverse Abstract syntax tree
int findconstloc(long);   	// Function to find location of constant value
void changestoffset(int); 	// Function to change offset of stack when pop/push a variable
void generatestdstmt(NODE*);	// Generate general statement assembly
GPtrArray *execseq;		// Array to store all node
GArray *constarr;
FILE *fp;
VARSTAT vst[26];		// Array to show status of a variable $A-$Z
long r0stoffset;		// Offset of R0 use to calculate when using it
int curvar,errflag,globalerrflag; // Current Variable , Error Flag , Global error flag
long iflbcnt,looplbcnt;
%}
%define api.value.type{long}

// List of token
%token START END MAIN NEWLINE
%token NUMDEC NUMHEX
%token SHOWBASE10 SHOWBASE16 
%token IF THEN EQUTO
%token LOOP TO DO
%token VAR UNKNOWN

// Operation with priority order
%left '|'
%left '&'
%left SLL SRL
%left '+' '-'
%left '*' '\\' '/'
%right '~' NEG
%%
input:%empty|START MAIN NEWLINE stmts END MAIN
{goto warppt;}|START MAIN NEWLINE END MAIN|START MAIN NEWLINE END MAIN NEWLINE|START MAIN NEWLINE stmts END MAIN NEWLINE{
	warppt:
	curvar=curvar;
	int vid,destreg;
	long loc,k;
	NODE *ptr;
	fp = fopen("output.s","w");
	fprintf(fp,".text\n");
	fprintf(fp,".align 2\n");
	fprintf(fp,".global _start\n");
	fprintf(fp,"_start:\n");
	fprintf(fp,"\tSUB\tSP,SP,#68\n"); //temp storage for LAIR R0,R10(K-Z)
	for(k=execseq->len-1;k>=0;k--){
		ptr = g_ptr_array_index(execseq,k);
		//=======================================================
		if(ptr->ttype==SHOWBASE10 || ptr->ttype==SHOWBASE16 ||ptr->ttype=='=')
			generatestdstmt(ptr); // If function is SHOWBASE10 or 16 or operation =,then do a generatestdstmt()
		//===============================================================
		else if(ptr->ttype==IF){	// "IF" Statement
			//IF varconst EQUTO varconst THEN NEWLINE stdstmt
			NODE *equ = ptr->left;
			NODE *equleft = equ->left;
			NODE *equright = equ->right;
			fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
			if(equleft->ttype == NUMDEC || equleft->ttype == NUMHEX){ // IF "Constant" EQUTO XX << is number base 10 or 16 
				long n = strtol(equleft->lexame,NULL,10);
				if(!(loc=findconstloc(n)*4)){
					g_array_append_val(constarr,n);
					loc = (constarr->len-1)*4;
				}
				fprintf(fp,"\tLDR\tR11,=const%d\n",(loc/256));
				fprintf(fp,"\tLDR\tR11,[R11,#%d]\n",(loc%256));
			}
			else{ //equleft is VAR
				vid = strtol(equleft->lexame,NULL,10)-1;
				if(vid<10){	// Variable $A-$J
					fprintf(fp,"\tMOV\tR11,R%d\n",vid);
				}
				else{ // Variable $K-$Z
					if(curvar==vid){
						fprintf(fp,"\tMOV\tR11,R10\n");
					}
					else{ // Get $K-$Z from Stack
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
						fprintf(fp,"\tMOV\tR11,R10\n");
						curvar=vid;					
					}
				}
				if(!vst[vid].stat){
				printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
				globalerrflag=1;
				}
			}
			//===============================================
			if(equright->ttype == NUMDEC || equright->ttype == NUMHEX){ // IF XX EQUTO "Constant" << is number base 10 or 16 
				long n = strtol(equright->lexame,NULL,10);
				if(!(loc=findconstloc(n)*4)){
					g_array_append_val(constarr,n);
					loc = (constarr->len-1)*4;
				}
				fprintf(fp,"\tLDR\tR12,=const%d\n",(loc/256));
				fprintf(fp,"\tLDR\tR12,[R12,#%d]\n",(loc%256));
			}
			else{ //equright is VAR
				vid = strtol(equright->lexame,NULL,10)-1;
				if(vid<10){ // Variable $A-$J
					fprintf(fp,"\tMOV\tR12,R%d\n",vid);
				}
				else{
					if(curvar==vid){ // Variable $K-$Z
						fprintf(fp,"\tMOV\tR12,R10\n");
					}
					else{ // Get $K-$Z from Stack
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
						fprintf(fp,"\tMOV\tR12,R10\n");
						curvar=vid;					
					}
				}
				if(!vst[vid].stat){
					printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
					globalerrflag=1;
				}
			}
			// Compare XX EQUTO XX
			fprintf(fp,"\tCMP\tR11,R12\n");
			fprintf(fp,"\tBNE\twarpif%d\n",iflbcnt); // Branch if not equal to label warpif
			generatestdstmt(ptr->right); // Generate Statement
			fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
			curvar=0;
			fprintf(fp,"warpif%d:\n",iflbcnt); // Label for BNE to branch to
			iflbcnt++; // Counter for loop
		}
		// Loop statement
		else{
			int cmpflag = 0;
			//LOOP const TO const DO NEWLINE stdstmt
			NODE *equ = ptr->left;
			NODE *equleft = equ->left;
			NODE *equright = equ->right;
			fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
			if(equleft->ttype == NUMDEC || equleft->ttype == NUMHEX){ // IF "Constant" EQUTO XX << is number base 10 or 16 
				long n = strtol(equleft->lexame,NULL,10);
				if(!(loc=findconstloc(n)*4)){
					g_array_append_val(constarr,n);
					loc = (constarr->len-1)*4;
				}
				fprintf(fp,"\tLDR\tR11,=const%d\n",(loc/256));
				fprintf(fp,"\tLDR\tR11,[R11,#%d]\n",(loc%256));
			}
			else{ //equleft is VAR
				vid = strtol(equleft->lexame,NULL,10)-1;
				if(vid<10){	// Variable $A-$J
					//fprintf(fp,"\tMOV\tR11,R%d\n",vid);
				}
				else{ // Variable $K-$Z
					if(curvar==vid){
						//fprintf(fp,"\tMOV\tR11,R10\n");
					}
					else{ // Get $K-$Z from Stack
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
						//fprintf(fp,"\tMOV\tR11,R10\n");
						curvar=vid;					
					}
				}
				if(!vst[vid].stat){
				printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
				globalerrflag=1;
				}
				cmpflag=1;
			}
			//===============================================
			if(equright->ttype == NUMDEC || equright->ttype == NUMHEX){ // IF XX EQUTO "Constant" << is number base 10 or 16 
				long n = strtol(equright->lexame,NULL,10);
				if(!(loc=findconstloc(n)*4)){
					g_array_append_val(constarr,n);
					loc = (constarr->len-1)*4;
				}
				fprintf(fp,"\tLDR\tR12,=const%d\n",(loc/256));
				fprintf(fp,"\tLDR\tR12,[R12,#%d]\n",(loc%256));
			}
			else{ //equright is VAR
				vid = strtol(equright->lexame,NULL,10)-1;
				if(vid<10){ // Variable $A-$J
					fprintf(fp,"\tMOV\tR12,R%d\n",vid);
				}
				else{
					if(curvar==vid){ // Variable $K-$Z
						fprintf(fp,"\tMOV\tR12,R10\n");
					}
					else{ // Get $K-$Z from Stack
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
						fprintf(fp,"\tMOV\tR12,R10\n");
						curvar=vid;					
					}
				}
				if(!vst[vid].stat){
					printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
					globalerrflag=1;
				}
			}
			//=========================================
			fprintf(fp,"loop%d:\n",looplbcnt);
			if(cmpflag){
				int m=strtol(equleft->lexame,NULL,10)-1;
				if(m<10){
					fprintf(fp,"\tCMP\tR%d,R12\n",m);
				}
				else{
					fprintf(fp,"\tCMP\tR10,R12\n");
				}
			}
			else
				fprintf(fp,"\tCMP\tR11,R12\n"); // Compare CONST is CONST
			fprintf(fp,"\tBGT\texitloop%d\n",looplbcnt); // Branch to exitloop if x > y
			generatestdstmt(ptr->right); // Generate Statement
			
			if(cmpflag){
				int m = strtol(equleft->lexame,NULL,10)-1;
				if(m<10){
					fprintf(fp,"\tADD\tR%d,R%d,#1\n",m,m);
				}
				else{
					fprintf(fp,"\tADD\tR10,R10,#1\n");
				}
			}
			else
				fprintf(fp,"\tADD\tR11,R11,#1\n");
			fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);  //*******
			fprintf(fp,"\tB\tloop%d\n",looplbcnt);
			fprintf(fp,"exitloop%d:\n",looplbcnt);
			looplbcnt++;curvar=0;
			//==========================================
		}
	}
	fprintf(fp,"\tMOV\tR0,#0\n");
    	fprintf(fp,"\tMOV\tR7,#1\n");
    	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\n\n");
	// Show Base10 Function
	fprintf(fp,"showbase10:\n");
	fprintf(fp,"\tPUSH\t{R11}\n");
	fprintf(fp,"\tPUSH\t{R10}\n");
	fprintf(fp,"\tPUSH\t{R9}\n");
	fprintf(fp,"\tPUSH\t{R8}\n");
	fprintf(fp,"\tPUSH\t{R7}\n");
	fprintf(fp,"\tPUSH\t{R2}\n");
	fprintf(fp,"\tPUSH\t{R1}\n");
	fprintf(fp,"\tPUSH\t{R0}\n");
	fprintf(fp,"\tMOV\tR0,#1\n");
    	fprintf(fp,"\tMOV\tR2,#1\n");
	fprintf(fp,"\tMOV\tR11,R12\n");
	fprintf(fp,"\n\n");
	fprintf(fp,"\tCMP\tR11,#0\n");
	fprintf(fp,"\tBGE\tsb10skipminus\n");
	fprintf(fp,"\tLDR\tR1,=minussign\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tLDR\tR1,=showout\n");
	fprintf(fp,"\tCMP\tR11,#-10\n");
	fprintf(fp,"\tBGT\tsb10exit3\n");
	fprintf(fp,"\tB\tsb10chkpt\n");
	fputc('\n',fp);
	fprintf(fp,"sb10skipminus:\n");
	fprintf(fp,"\tLDR\tR1,=showout\n");	
	fprintf(fp,"\tCMP\tR11,#10\n");
	fprintf(fp,"\tBLT\tsb10exit3\n");
	fputc('\n',fp);
	fprintf(fp,"sb10chkpt:\n");
	fprintf(fp,"\tMOV\tR12,#10\n");
	fprintf(fp,"\tMOV\tR9,#0\n");
	fprintf(fp,"\tMOV\tR10,R11\n");
	fprintf(fp,"\tCMP\tR11,#0\n");
	fprintf(fp,"\tBGE\tsb10divplus\n");
	fprintf(fp,"sb10divminus:\n");
	fprintf(fp,"\tCMP\tR10,#-10\n");
	fprintf(fp,"\tBGT\tsb10endpt\n");
	fprintf(fp,"\tSDIV\tR10,R10,R12\n");
	fprintf(fp,"\tADD\tR9,R9,#1\n");
	fprintf(fp,"\tB\tsb10divminus\n");
	fprintf(fp,"sb10divplus:\n");
	fprintf(fp,"\tCMP\tR10,#10\n");
	fprintf(fp,"\tBLT\tsb10endpt\n");
	fprintf(fp,"\tSDIV\tR10,R10,R12\n");
	fprintf(fp,"\tADD\tR9,R9,#1\n");
	fprintf(fp,"\tB\tsb10divplus\n");
	fprintf(fp,"sb10endpt:\n");
	fprintf(fp,"\tMOV\tR12,#0\n");
	fprintf(fp,"\tMOV\tR8,#10\n");
	fprintf(fp,"\tMOV\tR7,#1\n");
	fprintf(fp,"sb10chkpt1:\n");
	fprintf(fp,"\tCMP\tR12,R9\n");
	fprintf(fp,"\tBGE\tsb10exit2\n");
	fprintf(fp,"\tMUL\tR10,R7,R8\n");
	fprintf(fp,"\tMOV\tR7,R10\n");
	fprintf(fp,"\tADD\tR12,R12,#1\n");
	fprintf(fp,"\tB\tsb10chkpt1\n");
	fprintf(fp,"sb10exit2:\n");
	fprintf(fp,"\tSUB\tR9,R9,#1\n");
	fprintf(fp,"\tPUSH\t{R9}\n");
	fprintf(fp,"\tSDIV\tR12,R11,R10\n");
	fprintf(fp,"\tMOV\tR9,R12\n");
	fprintf(fp,"\tCMP\tR9,#0\n");
	fprintf(fp,"\tBGE\tsb10skipinv\n");
	fprintf(fp,"\tMOV\tR7,#-1\n");
	fprintf(fp,"\tMUL\tR9,R7,R9\n");
	fprintf(fp,"sb10skipinv:\n");
	fprintf(fp,"\tMOV\tR7,#4\n"); 
	fprintf(fp,"\tADD\tR9,R9,#0x30\n");
	fprintf(fp,"\tSTRB\tR9,[R1]\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tADD\tR1,R1,#1\n");
	fprintf(fp,"\tMUL\tR7,R10,R12\n");
	fputc('\n',fp);
	fprintf(fp,"\tCMP\tR7,#0\n");
	fprintf(fp,"\tBGE\tsb10skipaddnum\n");
	fprintf(fp,"\tMOV\tR12,#-1\n");
	fprintf(fp,"\tMUL\tR7,R12,R7\n");
	fprintf(fp,"\tADD\tR11,R11,R7\n");
	fprintf(fp,"\tB\tsb10chkpt2\n");
	fprintf(fp,"sb10skipaddnum:\n");
	fprintf(fp,"\tSUB\tR11,R11,R7\n");
	fputc('\n',fp);
	fprintf(fp,"sb10chkpt2:\n");
	fprintf(fp,"\tCMP\tR11,#0\n");
	fprintf(fp,"\tBGT\tsb10chknumplus\n");
	fprintf(fp,"\tBLT\tsb10chknumminus\n");
	fprintf(fp,"\tPOP\t{R9}\n");
	fprintf(fp,"\tMOV\tR10,#0x30\n");
	fprintf(fp,"\tSTRB\tR10,[R1]\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"\tMOV\tR12,#0\n");
	fprintf(fp,"sb10printlead0:\n");
	fprintf(fp,"\tCMP\tR12,R9\n");
	fprintf(fp,"\tBEQ\tsb10exit3\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tADD\tR12,R12,#0x1\n");
	fprintf(fp,"\tB\tsb10printlead0\n");
	fputc('\n',fp);
	fprintf(fp,"sb10chknumminus:\n");
	fprintf(fp,"\tPOP\t{R9}\n");
	fprintf(fp,"\tMOV\tR12,#0\n");
	fprintf(fp,"\tMOV\tR9,#-1\n");
	fprintf(fp,"\tMUL\tR10,R9,R10\n");
	fprintf(fp,"\tMOV\tR9,#10\n");
	fprintf(fp,"sb10betwzero2:\n");
	fprintf(fp,"\tCMP\tR11,R10\n");
	fprintf(fp,"\tBLE\tsb10exbetwzero2\n");
	fprintf(fp,"\tSDIV\tR10,R10,R9\n");
	fprintf(fp,"\tADD\tR12,R12,#1\n");
	fprintf(fp,"\tB\tsb10betwzero2\n");
	fprintf(fp,"sb10exbetwzero2:\n");
	fprintf(fp,"\tMOV\tR9,#1\n");
	fprintf(fp,"\tMOV\tR10,#0x30\n");
	fprintf(fp,"\tSTRB\tR10,[R1]\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"sb10printbetz2:\n");
	fprintf(fp,"\tCMP\tR9,R12\n");
	fprintf(fp,"\tBEQ\tsb10chknummnchkpt\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tADD\tR9,R9,#0x1\n");
	fprintf(fp,"\tB\tsb10printbetz2\n");
	fprintf(fp,"sb10chknummnchkpt:\n");
	fprintf(fp,"\tCMP\tR11,#-10\n");
	fprintf(fp,"\tBGT\tsb10exit3\n");
	fprintf(fp,"\tB\tsb10chkpt\n");
	fprintf(fp,"\n\n");
	fprintf(fp,"sb10chknumplus:\n");
	fprintf(fp,"\tPOP\t{R9}\n");
	fprintf(fp,"\tMOV\tR12,#0\n");
	fprintf(fp,"\tMOV\tR9,#10\n");
	fprintf(fp,"sb10betwzero1:\n");
	fprintf(fp,"\tCMP\tR11,R10\n");
	fprintf(fp,"\tBGE\tsb10exbetwzero1\n");
	fprintf(fp,"\tSDIV\tR10,R10,R9\n");
	fprintf(fp,"\tADD\tR12,R12,#1\n");
	fprintf(fp,"\tB\tsb10betwzero1\n");
	fprintf(fp,"sb10exbetwzero1:\n");
	fprintf(fp,"\tMOV\tR9,#1\n");
	fprintf(fp,"\tMOV\tR10,#0x30\n");
	fprintf(fp,"\tSTRB\tR10,[R1]\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"sb10printbetz1:\n");
	fprintf(fp,"\tCMP\tR9,R12\n");
	fprintf(fp,"\tBEQ\tsb10chknumplchkpt\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tADD\tR9,R9,#0x1\n");
	fprintf(fp,"\tB\tsb10printbetz1\n");
	fprintf(fp,"sb10chknumplchkpt:\n");
	fprintf(fp,"\tCMP\tR11,#10\n");
	fprintf(fp,"\tBLT\tsb10exit3\n");
	fprintf(fp,"\tB\tsb10chkpt\n");
	fprintf(fp,"\n\n");
	fprintf(fp,"sb10exit3:\n");
	fprintf(fp,"\tCMP\tR11,#0\n");
	fprintf(fp,"\tBGE\tsb10skipinv2\n");
	fprintf(fp,"\tMOV\tR7,#-1\n");
	fprintf(fp,"\tMUL\tR11,R7,R11\n");
	fprintf(fp,"sb10skipinv2:\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"\tADD\tR11,R11,#0x30\n");
	fprintf(fp,"\tSTRB\tR11,[R1]\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tLDR\tR1,=newline\n");
	fprintf(fp,"\tMOV\tR2,#2\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tPOP\t{R0}\n");
	fprintf(fp,"\tPOP\t{R1}\n");
	fprintf(fp,"\tPOP\t{R2}\n");
	fprintf(fp,"\tPOP\t{R7}\n");
	fprintf(fp,"\tPOP\t{R8}\n");
	fprintf(fp,"\tPOP\t{R9}\n");
	fprintf(fp,"\tPOP\t{R10}\n");
	fprintf(fp,"\tPOP\t{R11}\n");
	fprintf(fp,"\tPOP\t{R12}\n");
	fprintf(fp,"\tMOV\tPC,LR\n");	
	fprintf(fp,"\n\n");
	// Show Base16 Function
	fprintf(fp,"showbase16:\n");
	fprintf(fp,"\tPUSH\t{LR}\n");
	fprintf(fp,"\tPUSH\t{R11}\n");
	fprintf(fp,"\tPUSH\t{R10}\n");
	fprintf(fp,"\tPUSH\t{R7}\n");
	fprintf(fp,"\tPUSH\t{R2}\n");
	fprintf(fp,"\tPUSH\t{R1}\n");
	fprintf(fp,"\tPUSH\t{R0}\n");

	fprintf(fp,"\tLDR\tR1,=showprefix\n");
	fprintf(fp,"\tMOV\tR0,#1\n");
    	fprintf(fp,"\tMOV\tR2,#2\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tLDR\tR1,=showout\n");
	fprintf(fp,"\tMOV\tR2,#1\n");
	
	fprintf(fp,"\n\tMOV\tR11,R12\n");
	fprintf(fp,"\tMOV\tR12,#0xF\n");
	fprintf(fp,"\tLSL\tR12,R12,#28\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#28\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#24\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#20\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#16\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#12\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#8\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tLSR\tR10,R10,#4\n");
	fprintf(fp,"\tBL\tnumout\n");
	fprintf(fp,"\tLSR\tR12,R12,#4\n");
	fprintf(fp,"\tAND\tR10,R11,R12\n");
	fprintf(fp,"\tBL\tnumout\n");

	fprintf(fp,"\tLDR\tR1,=newline\n");
	fprintf(fp,"\tMOV\tR2,#2\n");
	fprintf(fp,"\tSWI\t0\n");

	fprintf(fp,"\tPOP\t{R0}\n");
	fprintf(fp,"\tPOP\t{R1}\n");
	fprintf(fp,"\tPOP\t{R2}\n");
	fprintf(fp,"\tPOP\t{R7}\n");
	fprintf(fp,"\tPOP\t{R10}\n");
	fprintf(fp,"\tPOP\t{R11}\n");
	fprintf(fp,"\tPOP\t{LR}\n");
	fprintf(fp,"\tPOP\t{R12}\n");
	fprintf(fp,"\tMOV\tPC,LR\n");

	// Output a num
	fprintf(fp,"numout:\n");
	fprintf(fp,"\tCMP\tR10,#9\n");
	fprintf(fp,"\tBGT\talphaput\n");
	fprintf(fp,"\tADD\tR10,R10,#0x30\n");
	fprintf(fp,"\tB\tputchkpt\n");
	fprintf(fp,"alphaput:\n");
	fprintf(fp,"\tADD\tR10,R10,#55\n");	
	fprintf(fp,"putchkpt:\n");
	fprintf(fp,"\tSTRB\tr10,[r1]\n");
	fprintf(fp,"\tSWI\t0\n");	
	fprintf(fp,"\tMOV\tPC,LR\n");
	fprintf(fp,".align 2\n");
	fprintf(fp,".data\n");
	fprintf(fp,"showprefix:\n");
    	fprintf(fp,"\t.byte\t48,120\n");
	fprintf(fp,"showout:\n");
    	fprintf(fp,"\t.byte\t1\n");
	if(constarr->len>0){
		long ind=0;
		long linecnt=0,maxline;
		maxline = ceil((double)constarr->len/64);
		while(linecnt < maxline){
			fprintf(fp,"const%d:\n",linecnt);
			fprintf(fp,"\t.word\t");
			
			if(linecnt+1 < maxline){
				for(k=0;k<64;k++){
					fprintf(fp,"%d",g_array_index(constarr,long,ind));
					if(k+1 < 64)
						fputc(',',fp);
					ind++;
				}
			}
			else{
				int remainder = constarr->len%64;
				for(k=0;k<remainder;k++){
					fprintf(fp,"%d",g_array_index(constarr,long,ind));
					if(k+1 < remainder)
						fputc(',',fp);
					ind++;
				}
			}
			fputc('\n',fp);
			linecnt++;
		}
	}
	fprintf(fp,"newline:\n");
	fprintf(fp,"\t.byte\t13,10\n");
	fprintf(fp,"minussign:\n");
    	fprintf(fp,"\t.byte\t45\n");
	fclose(fp);
	//TRY to traverse AST? to make a AST
}|START MAIN NEWLINE stmts error{printf("ERROR->Missing END MAIN\n");}
|error stmts END MAIN{printf("ERROR->Missing START MAIN\n");};
stmts:stdstmt stmts{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));}|
	condstmt stmts{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));}|
	loopstmt stmts{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));}|
	stdstmt{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));}|
	condstmt{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));}|
	loopstmt{g_ptr_array_add(execseq,GUINT_TO_POINTER($1));};
stdstmt:VAR '=' exp NEWLINE{
	NODE *n = g_new(NODE,1);
	n->ttype = '=';
	gchar *str = g_strdup("=");
	n->lexame = str;
	n->right = GUINT_TO_POINTER($3);
	
	n->left = g_new(NODE,1);
	(n->left)->left = NULL;
	(n->left)->right = NULL;
	(n->left)->ttype = VAR;
	str = g_new(gchar,digitcol($1));
	sprintf(str,"%d",$1);
	(n->left)->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|SHOWBASE10 VAR NEWLINE{
	NODE *n = g_new(NODE,1);
	n->right = NULL;
	n->ttype = SHOWBASE10;
	gchar *str = g_strdup("SHOWBASE10");
	n->lexame = str;
	//Create subnode for VAR
	n->left = g_new(NODE,1);
	(n->left)->left = NULL;
	(n->left)->right = NULL;
	(n->left)->ttype = VAR;
	str = g_new(gchar,digitcol($2));
	sprintf(str,"%d",$2);
	(n->left)->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|SHOWBASE16 VAR NEWLINE{
	NODE *n = g_new(NODE,1);
	n->right = NULL;
	n->ttype = SHOWBASE16;
	gchar *str = g_strdup("SHOWBASE16");
	n->lexame = str;
	//Create subnode for VAR
	n->left = g_new(NODE,1);
	(n->left)->left = NULL;
	(n->left)->right = NULL;
	(n->left)->ttype = VAR;
	str = g_new(gchar,digitcol($2));
	sprintf(str,"%d",$2);
	(n->left)->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
;
condstmt:IF varconst EQUTO varconst THEN NEWLINE stdstmt{
	NODE *n = g_new(NODE,1);
	n->ttype = IF;
	gchar *str = g_strdup("IF");
	n->lexame = str;
	
	n->left = g_new(NODE,1);
	(n->left)->ttype = EQUTO;
	(n->left)->lexame = g_strdup("EQUTO");
	(n->left)->left = GUINT_TO_POINTER($2);
	(n->left)->right = GUINT_TO_POINTER($4);

	n->right = GUINT_TO_POINTER($7);
	$$ = GPOINTER_TO_UINT(n);
};
loopstmt:LOOP varconst TO varconst DO NEWLINE stdstmt{
	NODE *n = g_new(NODE,1);
	n->ttype = LOOP;
	gchar *str = g_strdup("LOOP");
	n->lexame = str;
	
	n->left = g_new(NODE,1);
	(n->left)->ttype = TO;
	(n->left)->lexame = g_strdup("TO");
	(n->left)->left = GUINT_TO_POINTER($2);
	(n->left)->right = GUINT_TO_POINTER($4);

	n->right = GUINT_TO_POINTER($7);
	$$ = GPOINTER_TO_UINT(n);
};

varconst:VAR{
	NODE *n = g_new(NODE,1);
	n->left = NULL;
	n->right = NULL;
	n->ttype = VAR;
	gchar *str = g_new(gchar,digitcol($1));
	sprintf(str,"%d",$1);
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
	}|const{$$ = $1;};
const:NUMDEC{
	NODE *n = g_new(NODE,1);
	n->left = NULL;
	n->right = NULL;
	n->ttype = NUMDEC;
	gchar *str = g_new(gchar,digitcol($1));
	sprintf(str,"%d",$1);
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|NUMHEX{
	NODE *n = g_new(NODE,1);
	n->left = NULL;
	n->right = NULL;
	n->ttype = NUMHEX;
	gchar *str = g_new(gchar,digitcol($1));
	sprintf(str,"%d",$1);
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
};

exp:varconst{$$=$1;}
|exp SLL exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = SLL;
	gchar *str = g_strdup("<<");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp SRL exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = SRL;
	gchar *str = g_strdup(">>");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '&' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '&';
	gchar *str = g_strdup("&");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '|' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '|';
	gchar *str = g_strdup("|");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|'~' exp{
	NODE *n = g_new(NODE,1);
	n->left = NULL;
	n->ttype = '~';
	gchar *str = g_strdup("~");
	n->lexame = str;
	n->right = GUINT_TO_POINTER($2);
	$$ = GPOINTER_TO_UINT(n);
}
|exp '+' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '+';
	gchar *str = g_strdup("+");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '-' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '-';
	gchar *str = g_strdup("-");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '*' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '*';
	gchar *str = g_strdup("*");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '/' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '/';
	gchar *str = g_strdup("/");
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '\\' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '\\';
	gchar *str = g_new(gchar,1);
	str[0] = '\\';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|'-' exp %prec '~' {
	NODE *n = g_new(NODE,1);
	n->left = NULL;
	n->ttype = NEG;
	gchar *str = g_strdup("-");
	n->lexame = str;
	n->right = GUINT_TO_POINTER($2);
	$$ = GPOINTER_TO_UINT(n);
}
|'(' exp ')'{$$ = $2;}
|'[' exp ']'{$$ = $2;}
|'{' exp '}'{$$ = $2;}
;
%%
// Traverse AST Function
int traversetree(NODE *node){
	if(node!=NULL){
		int destreg1,destreg2;
		long loc,freereg;
		if(node->ttype==NUMDEC || node->ttype==NUMHEX){ // if node is const
			long n = strtol(node->lexame,NULL,10);
			if(!(loc=findconstloc(n)*4)){ // Find a location
				g_array_append_val(constarr,n);
				loc = (constarr->len-1)*4;
			}
				fprintf(fp,"\tPUSH\t{R0}\n");
				changestoffset(4);
				fprintf(fp,"\tLDR\tR0,=const%d\n",(loc/256)); // load address of block
				fprintf(fp,"\tLDR\tR0,[R0,#%d]\n",(loc%256)); // use block+offset address to get
			return -1;
		}
		else if(node->ttype==VAR){
			//Imply that there's already some value in that variable
			//Determine the register which return to expression for continuing calculation
			int vid = strtol(node->lexame,NULL,10)-1;
			if(!vst[vid].stat){
				printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
				globalerrflag = errflag = 1;
			}
			if(vst[vid].regid < 10)
				return vst[vid].regid;
			else
				return vid;
		}
		else if(node->ttype==NEG){
			destreg1=traversetree(node->right);
			//Check if cannot alloc?
			if(destreg1==-1){
				fprintf(fp,"\tMVN\tR0,R0\n");
				fprintf(fp,"\tADD\tR0,R0,#1\n");
				return -1;
			}
			if(destreg1>=10){
				if(curvar==destreg1){
					fprintf(fp,"\tMVN\tR10,R10\n");
					fprintf(fp,"\tADD\tR10,R10,#1\n");
				}
				else{
					fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
					fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
					fprintf(fp,"\tMVN\tR10,R10\n");
					fprintf(fp,"\tADD\tR10,R10,#1\n");
					curvar=destreg1;						
				}
				return destreg1;
			}
			else{
				fprintf(fp,"\tMVN\tR%d,R%d\n",destreg1,destreg1);
				fprintf(fp,"\tADD\tR%d,R%d,#1\n",destreg1,destreg1);
				return destreg1;
			}
		}
		else if(node->ttype=='+'){
			//The addition of both is
			//ADD R1,R1,R2 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){ // Left and Right is const
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tADD\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){ // Left is const and Right is Variable
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tADD\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){ //$K-$Z
					if(curvar==destreg2){
						fprintf(fp,"\tADD\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tADD\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tADD\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){ // Right is const and Left is Variable
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tADD\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tADD\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tADD\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tADD\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of addition has valid reg to add
				//we cannot add by accumulate directly(if $B + $C ???)
				if(destreg1==0 && destreg2==0){ // Both is variable
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tADD\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tADD\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tADD\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					//==============================================
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tADD\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tADD\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='-'){
			//The subtraction of both is
			//SUB R1,R1,R2 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tSUB\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tSUB\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tSUB\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tSUB\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tSUB\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tSUB\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tSUB\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tSUB\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of addition has valid reg to add
				//we cannot subtract by accumulate directly(if $B - $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSUB\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSUB\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSUB\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSUB\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='*'){
			//The multiplication of both is
			//MUL R1,R2,R1 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tMUL\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tMUL\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tMUL\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tMUL\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tMUL\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of addition has valid reg to add
				//we cannot multiply by accumulate directly(if $B * $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tMUL\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tMUL\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tMUL\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tMUL\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tMUL\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='/'){
			//The division of both is
			//SDIV R1,R1,R2 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tSDIV\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tSDIV\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tSDIV\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tSDIV\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tSDIV\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tSDIV\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tSDIV\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of addition has valid reg to div
				//we cannot div by accumulate directly(if $B / $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='\\'){
			//The modulation of both is
			//SDIV R10,R12,R11
    			//MUL  R11,R10,R11
    			//SUB  R12,R12,R11
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tPUSH\t{LR}\n");
				changestoffset(4);
				fprintf(fp,"\tSDIV\tLR,LR,R0\n");
				fprintf(fp,"\tMUL\tLR,LR,R0\n");
				fprintf(fp,"\tMOV\tR0,LR\n");
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tSUB\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);   //destreg1 is R0(free),destreg2 is LR(which is load from st)
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R0,LR\n");
					fprintf(fp,"\tMUL\tR0,R0,LR\n");
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R0}\n");
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R0}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R0,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R0}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R0,LR\n");
						curvar=destreg2;
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR0,R0,R%d\n",destreg2);
					fprintf(fp,"\tMUL\tR0,R0,R%d\n",destreg2);
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R0}\n");
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tPUSH\t{LR}\n");
					changestoffset(4);
					fprintf(fp,"\tSDIV\tLR,LR,R0\n");
					fprintf(fp,"\tMUL\tR0,LR,R0\n");
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R0}\n");
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){    //destreg2 is R0(Free),desreg1 is R10
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR10,R10,R0\n");
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(4);
						fprintf(fp,"\tSDIV\tR10,R10,R0\n");
						fprintf(fp,"\tMUL\tR0,R10,R0\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
						curvar=destreg1;
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R%d}\n",destreg1);
					changestoffset(4);
					fprintf(fp,"\tSDIV\tR%d,R%d,R0\n",destreg1,destreg1);
					fprintf(fp,"\tMUL\tR0,R%d,R0\n",destreg1);
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R%d}\n",destreg1);
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R%d,LR\n",destreg1);
				}
				return destreg2;
			}
			else{
				//since the both side of addition has valid reg to mod
				//we cannot mod by accumulate directly(if $B \ $C ???)
				if(destreg1==0 && destreg2==0){	//$A \ $A = 0
					fprintf(fp,"\tPUSH\t{R0}\n");  
					changestoffset(4);
					fprintf(fp,"\tMOV\tR0,#0\n");
				}
				else if(destreg1==0 && destreg2 < 10){  //destreg1 is R0,destreg2 is R1-R9
					fprintf(fp,"\tPUSH\t{R0}\n");
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(8);
					fprintf(fp,"\tSDIV\tR0,R0,R%d\n",destreg2);
					fprintf(fp,"\tMUL\tR0,R0,R%d\n",destreg2);
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R0}\n");
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){   //destreg1 is R0,destreg2 is R10
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R0}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R0,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR0,R0,R10\n");
						fprintf(fp,"\tMUL\tR0,R0,R10\n");
						fprintf(fp,"\tMOV\tLR,R0\n");
						fprintf(fp,"\tPOP\t{R0}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R0,LR\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					fprintf(fp,"\tPUSH\t{R%d}\n",destreg1);
					changestoffset(8);
					fprintf(fp,"\tSDIV\tR%d,R%d,R0\n",destreg1,destreg1);
					fprintf(fp,"\tMUL\tR%d,R%d,R0\n",destreg1,destreg1);
					fprintf(fp,"\tMOV\tLR,R%d\n",destreg1);
					fprintf(fp,"\tPOP\t{R%d}\n",destreg1);
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R%d,LR\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){   //destreg1 is R10,destreg2 is R0
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR10,R10,R0\n");
						fprintf(fp,"\tMUL\tR10,R10,R0\n");
						fprintf(fp,"\tMOV\tLR,R10\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR10,R10,R0\n");
						fprintf(fp,"\tMUL\tR10,R10,R0\n");
						fprintf(fp,"\tMOV\tLR,R10\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){  //destreg 1 is R10,destreg2 is LR
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR10,R10,LR\n");
						fprintf(fp,"\tMUL\tR10,R10,LR\n");
						fprintf(fp,"\tMOV\tLR,R10\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						fprintf(fp,"\tPUSH\t{R10}\n");
						changestoffset(8);
						fprintf(fp,"\tSDIV\tR10,R10,LR\n");
						fprintf(fp,"\tMUL\tR10,R10,LR\n");
						fprintf(fp,"\tMOV\tLR,R10\n");
						fprintf(fp,"\tPOP\t{R10}\n");
						changestoffset(-4);
						fprintf(fp,"\tSUB\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					fprintf(fp,"\tPUSH\t{R%d}\n",destreg1);
					changestoffset(8);
					fprintf(fp,"\tSDIV\tR0,R%d,R%d\n",destreg1,destreg2);
					fprintf(fp,"\tMUL\tR0,R0,R%d\n",destreg2);
					fprintf(fp,"\tMOV\tLR,R0\n");
					fprintf(fp,"\tPOP\t{R0}\n");
					changestoffset(-4);
					fprintf(fp,"\tSUB\tR0,R0,LR\n");
				}
				return -1;
			}

		}
		else if(node->ttype=='&'){
			//The logical and of both is
			//AND R1,R2,R1 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tAND\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tAND\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tAND\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tAND\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tAND\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tAND\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tAND\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tAND\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tAND\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of logical and has valid reg to add
				//we cannot and by accumulate directly(if $B * $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tAND\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tAND\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tAND\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tAND\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tAND\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='|'){
			//The logical OR of both is
			//ORR R1,R2,R1 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tORR\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tORR\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tORR\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tORR\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tORR\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tORR\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tORR\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tORR\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tORR\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of logical OR has valid reg to add
				//we cannot OR by accumulate directly(if $B * $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tORR\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tORR\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tORR\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tORR\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tORR\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype=='~'){ // Not Example ==> ~$A ==> use "Move Not"
			destreg1=traversetree(node->right); // Right node
			if(destreg1==-1){
				fprintf(fp,"\tMVN\tR0,R0\n"); // Const
				return -1;
			}
			if(destreg1>=10){
				if(curvar==destreg1){
					fprintf(fp,"\tMVN\tR10,R10\n");
				}
				else{
					fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
					fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
					fprintf(fp,"\tMVN\tR10,R10\n");
					curvar=destreg1;						
				}
				return destreg1;
			}
			else{
				fprintf(fp,"\tMVN\tR%d,R%d\n",destreg1,destreg1);
				return destreg1;
			}
		}
		else if(node->ttype==SLL){
			//The shift left of both is
			//LSL R1,R2,R1 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tLSL\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tLSL\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tLSL\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tLSL\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tLSL\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tLSL\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tLSL\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tLSL\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tLSL\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of shift left has valid reg to add
				//we cannot shift left by accumulate directly(if $B << $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSL\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSL\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSL\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSL\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSL\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		else if(node->ttype==SRL){
			//The logical shift right of both is
			//LSR R1,R2,R1 => OK
			destreg1 = traversetree(node->left);
			destreg2 = traversetree(node->right);
			if(destreg1==-1 && destreg2==-1){
				fprintf(fp,"\tPOP\t{LR}\n");
				changestoffset(-4);
				fprintf(fp,"\tLSR\tR0,LR,R0\n");
				return destreg1;
			}
			else if(destreg1 == -1){
				if(destreg2 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tLSR\tR0,R0,LR\n");
				}
				else if(destreg2 >= 10){
					if(curvar==destreg2){
						fprintf(fp,"\tLSR\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tLSR\tR0,R0,R10\n");
						curvar=destreg2;
					}
				}
				else
					fprintf(fp,"\tLSR\tR0,R0,R%d\n",destreg2);
				return destreg1;
			}
			else if(destreg2 == -1){
				if(destreg1 == 0){
					fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",r0stoffset);
					fprintf(fp,"\tLSR\tR0,LR,R0\n");
				}
				else if(destreg1 >= 10){
					if(curvar==destreg1){
						fprintf(fp,"\tLSR\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tLSR\tR0,R10,R0\n");
						curvar=destreg1;
					}
				}
				else
					fprintf(fp,"\tLSR\tR0,R%d,R0\n",destreg1);
				return destreg2;
			}
			else{
				//since the both side of shift right has valid reg to add
				//we cannot shift right by accumulate directly(if $B >> $C ???)
				if(destreg1==0 && destreg2==0){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSR\tR0,R0,R0\n");
				}
				else if(destreg1==0 && destreg2 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSR\tR0,R0,R%d\n",destreg2);
				}
				else if(destreg1==0){ //destreg2 >= 10
					if(curvar==destreg2){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R0,R10\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg2].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R0,R10\n");
						curvar=destreg2;					
					}
				}
				else if(destreg2==0 && destreg1 < 10){
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSR\tR0,R%d,R0\n",destreg1);
				}
				else if(destreg2==0){ //destreg1 >= 10
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R10,R0\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R10,R0\n");
						curvar=destreg1;						
					}
				}
				else if(destreg1 >= 10 && destreg2 >= 10){
					if(curvar==destreg2)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg2].stoffset);
					if(curvar==destreg1){
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R10,LR\n");
					}
					else{
						fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
						fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[destreg1].stoffset);
						fprintf(fp,"\tPUSH\t{R0}\n");
						changestoffset(4);
						fprintf(fp,"\tLSR\tR0,R10,LR\n");
						curvar=destreg1;						
					}
				}
				else{
					fprintf(fp,"\tPUSH\t{R0}\n");
					changestoffset(4);
					fprintf(fp,"\tLSR\tR0,R%d,R%d\n",destreg1,destreg2);
				}
				return -1;
			}
		}
		//=====================
		else{
		traversetree(node->left);
		traversetree(node->right);
		}
		
	}
	return 0;
}

// Generate a simple statment
void generatestdstmt(NODE* ptr){
	int vid,destreg;
	if(ptr->ttype==SHOWBASE10){
			vid = strtol((ptr->left)->lexame,NULL,10)-1;
			//Imply that the var is already assign some value.
			//IF value of var is not in reg?? find from stack!?
			if(vid>=10){
				if(curvar==vid){
					fprintf(fp,"\tPUSH\t{R12}\n");
					fprintf(fp,"\tMOV\tR12,R10\n");
					fprintf(fp,"\tBL\tshowbase10\n");
				}
				else{
					fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
					fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
					fprintf(fp,"\tPUSH\t{R12}\n");
					fprintf(fp,"\tMOV\tR12,R10\n");
					fprintf(fp,"\tBL\tshowbase10\n");
					curvar=vid;
				}
			}
			else{
				fprintf(fp,"\tPUSH\t{R12}\n");
				fprintf(fp,"\tMOV\tR12,R%d\n",vst[vid].regid);
				fprintf(fp,"\tBL\tshowbase10\n");
			}
			if(!vst[vid].stat){
				printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
				globalerrflag=1;
			}
		}
		else if(ptr->ttype==SHOWBASE16){
			vid = strtol((ptr->left)->lexame,NULL,10)-1;
			//Imply that the var is already assign some value.
			//IF value of var is not in reg?? find from stack!?
			if(vid>=10){
				if(curvar==vid){
					fprintf(fp,"\tPUSH\t{R12}\n");
					fprintf(fp,"\tMOV\tR12,R10\n");
					fprintf(fp,"\tBL\tshowbase16\n");
				}
				else{
					fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
					fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
					fprintf(fp,"\tPUSH\t{R12}\n");
					fprintf(fp,"\tMOV\tR12,R10\n");
					fprintf(fp,"\tBL\tshowbase16\n");
					curvar=vid;
				}
			}
			else{
				fprintf(fp,"\tPUSH\t{R12}\n");
				fprintf(fp,"\tMOV\tR12,R%d\n",vst[vid].regid);
				fprintf(fp,"\tBL\tshowbase16\n");
			}
			if(!vst[vid].stat){
				printf("ERROR->Variable $%c is used without assign value.\n",(vid+65));
				globalerrflag=1;
			}
		}
		else if(ptr->ttype=='='){
			vid = strtol((ptr->left)->lexame,NULL,10)-1;
				destreg = traversetree(ptr->right);
				if(destreg==-1){
					if(vid<10){
						fprintf(fp,"\tMOV\tR%d,R0\n",vst[vid].regid);
						if(vst[vid].regid==0){
							fprintf(fp,"\tPOP\t{LR}\n");
						}
						else{
							fprintf(fp,"\tPOP\t{R0}\n");
						}
					}
					else{
						if(curvar==vid){
							fprintf(fp,"\tMOV\tR10,R0\n");
							fprintf(fp,"\tPOP\t{R0}\n");
						}
						else{
							fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
							fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
							fprintf(fp,"\tMOV\tR10,R0\n");
							fprintf(fp,"\tPOP\t{R0}\n");
							curvar=vid;					
						}
					}
					changestoffset(-4);
				}
				else if(destreg>=10){
					//check for curvar
					if(curvar==destreg)
						fprintf(fp,"\tMOV\tLR,R10\n");
					else
						fprintf(fp,"\tLDR\tLR,[SP,#%d]\n",vst[destreg].stoffset); //LDR value of RXX to LR
					if(vid<10){
						fprintf(fp,"\tMOV\tR%d,LR\n",vst[vid].regid);
					}
					else{
						if(curvar==vid){
							fprintf(fp,"\tMOV\tR10,LR\n");
						}
						else{
							fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
							fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
							fprintf(fp,"\tMOV\tR10,LR\n");
							curvar=vid;					
						}
					}
				}
				else{ 	//======== destreg < 10
					if(vid<10){
						fprintf(fp,"\tMOV\tR%d,R%d\n",vst[vid].regid,destreg);
					}
					else{
						if(curvar==vid){
							fprintf(fp,"\tMOV\tR10,R%d\n",destreg);
						}
						else{
							fprintf(fp,"\tSTR\tR10,[SP,#%d]\n",vst[curvar].stoffset);
							fprintf(fp,"\tLDR\tR10,[SP,#%d]\n",vst[vid].stoffset);
							fprintf(fp,"\tMOV\tR10,R%d\n",destreg);
							curvar=vid;					
						}
					}
				}
			if(errflag)
				errflag=0;
			else
				vst[vid].stat = 1;
		}
}




int digitcol(long num){
	int returnval = 1;
	while(num > 10){
		num = num / 10;
		returnval++;
	}
	return returnval;
}

int findconstloc(long n){
	int k;
	for(k=0;k<constarr->len;k++){
		if(n == g_array_index(constarr,long,k))return k;
	}
	return 0;
}

void changestoffset(int off){
int i;
	for(i=10;i<26;i++){
	vst[i].stoffset+=off;
}
r0stoffset+=off;
vst[0].stoffset+=off;
}


void yyerror(char * str){
printf("%s\n",str);
}

//The main program
void main(){
iflbcnt=looplbcnt=0;
globalerrflag=0;
errflag=0;
r0stoffset =-4;
curvar = 10;
execseq = g_ptr_array_new();
constarr = g_array_new(FALSE,TRUE,sizeof(long));
int i;
for(i=0;i<10;i++){
	vst[i].regid=i;
	vst[i].stat=0;
	vst[i].stoffset=0;
}
for(i=10;i<26;i++){
	vst[i].regid=10;
	vst[i].stat=0;
	vst[i].stoffset=((i-10)*4)+4;
}
	
yyparse();
if(globalerrflag){
	fp = fopen("output.s","w");
	fclose(fp);
}
g_ptr_array_free(execseq,TRUE);
}
