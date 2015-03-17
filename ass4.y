%{
#include<stdio.h>
void yyerror(char *);
%}
%token START END MAIN UNKNOWN NEWLINE
%token NUMDEC NUMHEX
%token SHOWBASE10 SHOWBASE16 
%token SLL SRL AND OR NOT
%token IF THEN EQUTO
%token LOOP TO DO
%token VAR0 VAR1 VAR2 VAR3 VAR4 VAR5 VAR6 VAR7 VAR8 VAR9 VAR10 VAR11 VAR12 VAR13 VAR14 VAR15 VAR16 VAR17 VAR18 VAR19 VAR20 VAR21 VAR22 VAR23 VAR24 VAR25

%left OR
%left AND
%left SLL SRL
%left '+' '-'
%left '*' '\\' '/'
%right NOT
%%
input:START MAIN NEWLINE stmts END MAIN {printf("PASS!");};
input:START MAIN NEWLINE stmts END MAIN NEWLINE{printf("PASS!");};
stmts:stdstmt stmts|condstmt stmts|stdstmt|condstmt|loopstmt stmts|loopstmt;
stdstmts:stdstmt stdstmts|stdstmt;
stdstmt:var '=' exp NEWLINE 
|SHOWBASE10 var NEWLINE
|SHOWBASE16 var NEWLINE
;
condstmt:IF exp EQUTO exp THEN NEWLINE stdstmts END IF NEWLINE;
loopstmt:LOOP var '=' exp TO exp DO NEWLINE stdstmts END LOOP NEWLINE;

var:VAR0|VAR1|VAR2|VAR3|VAR4|VAR5|VAR6|VAR7|VAR8|VAR9|VAR10|VAR11|VAR12|VAR13|VAR14|VAR15|VAR16|VAR17|VAR18|VAR19|VAR20|VAR21|VAR22|VAR23|VAR24|VAR25;

exp:NUMDEC
|NUMHEX
|var
|exp SLL exp
|exp SRL exp
|exp AND exp
|exp OR exp
|NOT exp
|exp '+' exp
|exp '-' exp
|exp '*' exp
|exp '/' exp
|exp '\\' exp
|'-' exp %prec NOT
|'(' exp ')'
|'[' exp ']'
|'{' exp '}'
;
%%

void yyerror(char * str){
printf("%s\n",str);
}

void main(){
yyparse();
}
