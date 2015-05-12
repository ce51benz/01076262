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
GPtrArray *execseq;
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
	FILE *fp = fopen("output.s","w");
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
		traversetree(node->left);
		traversetree(node->right);
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

void yyerror(char * str){
printf("%s\n",str);
}

void main(){
execseq = g_ptr_array_new();
yyparse();
g_ptr_array_free(execseq,TRUE);
}
