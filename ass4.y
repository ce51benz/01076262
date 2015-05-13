%{
#include<stdio.h>
#include<glib.h>
void yyerror(char *);

typedef struct _node{
 	struct _node *left;
	struct _node *right;
	int ttype;
	char* lexame;
}NODE;
void traversetree(NODE *);
int isinconstarr(long);
GPtrArray *execseq;
GArray *constarr;
FILE *fp;
%}
%define api.value.type{long}

%token START END MAIN NEWLINE
%token NUMDEC NUMHEX
%token SHOWBASE10 SHOWBASE16 
%token IF THEN EQUTO
%token LOOP TO DO
%token VAR UNKNOWN

%left '|'
%left '&'
%left SLL SRL
%left '+' '-'
%left '*' '\\' '/'
%right '~'
%%
input:START MAIN NEWLINE stmts END MAIN
|START MAIN NEWLINE stmts END MAIN NEWLINE{
	int k;
	NODE *ptr;
	fp = fopen("output.s","w");
	fprintf(fp,".text\n");
	fprintf(fp,".align 2\n");
	fprintf(fp,".global _start\n");
	fprintf(fp,"_start:\n");

	for(k=execseq->len-1;k>=0;k--){
		ptr = g_ptr_array_index(execseq,k);
		g_printf("%s\n",ptr->lexame);
		if(ptr->ttype==SHOWBASE10){
			g_printf("%s\n",(ptr->left)->lexame);
		}
		else if(ptr->ttype==SHOWBASE16){
			g_printf("%s\n",(ptr->left)->lexame);
		}
		else if(ptr->ttype=='='){
			g_printf("%s\n",(ptr->left)->lexame);
			traversetree(ptr->right);
		}
		else if(ptr->ttype==IF);
		else;
	}
	fprintf(fp,"\tMOV\tR0,#0\n");
    	fprintf(fp,"\tMOV\tR7,#1\n");
    	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\n\n");
	fprintf(fp,"showbase10:\n");
	fprintf(fp,"\tMOV\tR0,#1\n");
    	fprintf(fp,"\tMOV\tR2,#1\n");
	fprintf(fp,"\tLDR\tR11,=const\n");
	fprintf(fp,"\tLDR\tR11,[R11,#0]\n");
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
	fprintf(fp,"\tBGE\tsb10exit3\n");
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
	fprintf(fp,"\tBLE\tsb10exit3\n");
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

	fprintf(fp,"showbase16:\n");
	fprintf(fp,"\tLDR\tR1,=showprefix\n");
	fprintf(fp,"\tMOV\tR0,#1\n");
    	fprintf(fp,"\tMOV\tR2,#2\n");
	fprintf(fp,"\tMOV\tR7,#4\n");
	fprintf(fp,"\tSWI\t0\n");
	fprintf(fp,"\tLDR\tR1,=showout\n");
	fprintf(fp,"\tMOV\tR2,#1\n");
	
	fprintf(fp,"\n\tLDR\tR11,=const\n");
	fprintf(fp,"\tLDR\tR11,[R11,#0]\n");
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
	fprintf(fp,"\tPOP\t{R0}\n");
	fprintf(fp,"\tPOP\t{R1}\n");
	fprintf(fp,"\tPOP\t{R2}\n");
	fprintf(fp,"\tPOP\t{R7}\n");
	fprintf(fp,"\tPOP\t{R10}\n");
	fprintf(fp,"\tPOP\t{R11}\n");
	fprintf(fp,"\tPOP\t{R12}\n");
	fprintf(fp,"\tMOV\tPC,LR\n");


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
	fprintf(fp,"minussign:\n");
    	fprintf(fp,"\t.byte\t45\n");
	if(constarr->len>0){
		fprintf(fp,"const:\n");
		fprintf(fp,"\t.word\t");
		for(k=0;k<constarr->len;k++){
			fprintf(fp,"%d",g_array_index(constarr,long,k));
			if(k+1 < constarr->len)
				fputc(',',fp);
		}
		fputc('\n',fp);
	}
	fclose(fp);
	//TRY to traverse AST?
};
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
	str = g_new(gchar,digitcol($2));
	sprintf(str,"%d",$2);
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
loopstmt:LOOP const TO const DO NEWLINE stdstmt{
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
	n->ttype = '-';
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

void traversetree(NODE *node){
	if(node!=NULL){
		if(node->ttype==NUMDEC){
			long n = strtol(node->lexame,NULL,10);
			if(!isinconstarr(n))
				g_array_append_val(constarr,n);
		}
		else if(node->ttype==NUMHEX){
			long n = strtol(node->lexame,NULL,10);
			if(!isinconstarr(n))
				g_array_append_val(constarr,n);
		}
		else{
		traversetree(node->left);
		traversetree(node->right);
		}
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
int isinconstarr(long n){
	int k;
	for(k=0;k<constarr->len;k++){
		if(n == g_array_index(constarr,long,k))return 1;
	}
	return 0;
}
void yyerror(char * str){
printf("%s\n",str);
}

void main(){
execseq = g_ptr_array_new();
constarr = g_array_new(FALSE,TRUE,sizeof(long));
yyparse();
g_ptr_array_free(execseq,TRUE);
}
