%{
#include<stdio.h>
void yyerror(char *);
%}
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

varconst:VAR|const;
const:NUMDEC|NUMHEX;

exp:varconst
|exp SLL exp
|exp SRL exp
|exp '&' exp
|exp '|' exp
|'~' exp
|exp '+' exp
|exp '-' exp
|exp '*' exp
|exp '/' exp
|exp '\\' exp
|'-' exp %prec '~'
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
