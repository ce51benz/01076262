%option noyywrap
%{
#include<stdio.h>
#include "infix.tab.h"
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
[0-9]+	{yylval.intval = atoi(yytext);return NUMDEC;}
[0-9A-Fa-f]+h {return NUMHEX;}
"\n"	{return '\n';}
.	{ /*Do nothing*/}
%%
