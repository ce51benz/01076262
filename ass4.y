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
|START MAIN NEWLINE stmts END MAIN NEWLINE;
stmts:stdstmt stmts|condstmt stmts|loopstmt stmts|stdstmt|condstmt|loopstmt;
stdstmt:VAR '=' exp NEWLINE
|SHOWBASE10 VAR NEWLINE
|SHOWBASE16 VAR NEWLINE
;
condstmt:IF varconst EQUTO varconst THEN NEWLINE stdstmt;
loopstmt:LOOP const TO const DO NEWLINE stdstmt;

varconst:VAR|const{$$ = $1;};
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

exp:varconst
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
	gchar *str = g_new(gchar,1);
	str[0] = '&';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '|' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '|';
	gchar *str = g_new(gchar,1);
	str[0] = '|';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|'~' exp
|exp '+' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '+';
	gchar *str = g_new(gchar,1);
	str[0] = '+';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '-' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '-';
	gchar *str = g_new(gchar,1);
	str[0] = '-';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '*' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '*';
	gchar *str = g_new(gchar,1);
	str[0] = '*';
	n->lexame = str;
	$$ = GPOINTER_TO_UINT(n);
}
|exp '/' exp{
	NODE *n = g_new(NODE,1);
	n->left = GUINT_TO_POINTER($1);
	n->right = GUINT_TO_POINTER($3);
	n->ttype = '/';
	gchar *str = g_new(gchar,1);
	str[0] = '/';
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
|'-' exp %prec '~'
|'(' exp ')'
|'[' exp ']'
|'{' exp '}'
;
%%
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
yyparse();
}
