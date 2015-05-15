%option noyywrap
%{
#include "ass4.tab.h"
#include <stdio.h>
#include <ctype.h>
%}

%%
^[#].+[\n]+	{ }
[#].+[\n]+	{ return NEWLINE;}
[#].		{ }
START 		{return START;}
MAIN 		{return MAIN;}
END 		{return END;}
SHOWBASE10	{return SHOWBASE10;}
SHOWBASE16	{return SHOWBASE16;}
[0-9]+ 		{yylval = strtol(yytext,NULL,10);return NUMDEC;}
0x[0-9A-Fa-f]+ 	{yylval = strtol(yytext,NULL,16);return NUMHEX;}
[+]		{return '+';}
[-]		{return '-';}
[*]		{return '*';}
[/]		{return '/';}
[\\]		{return '\\';}
[(]		{return '(';}
[)]		{return ')';}
[{]		{return '{';}
[}]		{return '}';}
"["		{return '[';}
"]"		{return ']';}
"<<"		{return SLL;}
">>"		{return SRL;}
[&]		{return '&';}
[|]		{return '|';}
[~]		{return '~';}
[=]		{return '=';}
"IF"		{return IF;}
"THEN"		{return THEN;}
"=="		{return EQUTO;}
"LOOP"		{return LOOP;}
"TO"		{return TO;}
"DO"		{return DO;}
[\r\n]+ 	{return NEWLINE;}
$[A-Za-z]	{
			if(isupper(yytext[1]))
				yylval = yytext[1] -('A'-1);
			else
				yylval = yytext[1] -('a'-1);
			return VAR;
		}
[$A-Za-z0-9]+ 	{return UNKNOWN; }
[ \t] 		{ }
.    		{ return UNKNOWN;} 
%%
