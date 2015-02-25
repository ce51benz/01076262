%option noyywrap
%{
#include<stdio.h>
enum {AND = 100,OR,NOT};
enum {NUMBIN = 200,NUMDEC,NUMHEX};
enum {PUSH = 300,POP,SHOW,COPY};
enum {TO = 400};
%}

%%
[+]	{return '+';}
[-]	{return '-';}
[*]	{return '*';}
[/]	{return '/';}
[\\]	{return '\\';}
[\^]	{return '^';}
[(]	{return '(';}
[)]	{return ')';}
[[]	{return '[';}
[]]	{return ']';}
[{]	{return '{';}
[}]	{return '}';}
"AND"   {return AND;}
"OR"    {return OR;}
"NOT"   {return NOT;}
"PUSH"	{return PUSH;}
"POP"	{return POP;}
"SHOW"	{return SHOW;}
"COPY"	{return COPY;}
"TO"	{return TO;}
[01]+b	{return NUMBIN;}
[0-9]+	{return NUMDEC;}
[0-9A-Fa-f]+h {return NUMHEX;}
"\n"	{return '\n';}
.	{ /*Do nothing*/}
%%

void main(){
int tok;
while(tok = yylex())printf("%s %d\n",yytext,tok);
}
