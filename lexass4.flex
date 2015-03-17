%option noyywrap
%{
#include "testass4.tab.h"
#include <stdio.h>
%}

%%
START 		{return START;}
MAIN 		{return MAIN;}
END 		{return END;}
SHOWBASE10	{return SHOWBASE10;}
SHOWBASE16	{return SHOWBASE16;}
[0-9]+ 		{return NUMDEC;}
0x[0-9A-Fa-f]+ 	{return NUMHEX;}
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
"SLL"		{return SLL;}
"SRL"		{return SRL;}
"AND"		{return AND;}
"OR"		{return OR;}
"NOT"		{return NOT;}
[=]		{return '=';}
"IF"		{return IF;}
"THEN"		{return THEN;}
"=="		{return EQUTO;}
"LOOP"		{return LOOP;}
"TO"		{return TO;}
"DO"		{return DO;}
[\r\n]+ 	{return NEWLINE;}
"VAR0"		{return VAR0;}
"VAR1"		{return VAR1;}
"VAR2"		{return VAR2;}
"VAR3"		{return VAR3;}
"VAR4"		{return VAR4;}
"VAR5"		{return VAR5;}
"VAR6"		{return VAR6;}
"VAR7"		{return VAR7;}
"VAR8"		{return VAR8;}
"VAR9"		{return VAR9;}
"VAR10"		{return VAR10;}
"VAR11"		{return VAR11;}
"VAR12"		{return VAR12;}
"VAR13"		{return VAR13;}
"VAR14"		{return VAR14;}
"VAR15"		{return VAR15;}
"VAR16"		{return VAR16;}
"VAR17"		{return VAR17;}
"VAR18"		{return VAR18;}
"VAR19"		{return VAR19;}
"VAR20"		{return VAR20;}
"VAR21"		{return VAR21;}
"VAR22"		{return VAR22;}
"VAR23"		{return VAR23;}
"VAR24"		{return VAR24;}
"VAR25"		{return VAR25;}
[A-Za-z]+ 	{return UNKNOWN; }
[ \t] 		{ }
.    		{ return UNKNOWN;} 
%%
