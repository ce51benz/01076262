%option noyywrap
%{
#include<stdio.h>
#include "infix.tab.h"
#include<ctype.h>
long long strbittolong(char *);
long long strhextolong(char *);
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
[01]+b	{yylval = strbittolong(yytext);return NUMBIN;}
[0-9]+	{yylval = atol(yytext);return NUMDEC;}
[0-9A-Fa-f]+h {yylval = strhextolong(yytext);return NUMHEX;}
"$r0"	{return REG0;}
"$r1"	{return REG1;}
"$r2"	{return REG2;}
"$r3"	{return REG3;}
"$r4"	{return REG4;}
"$r5"	{return REG5;}
"$r6"	{return REG6;}
"$r7"	{return REG7;}
"$r8"	{return REG8;}
"$r9"	{return REG9;}
"$acc"	{return REGACC;}
"$size"	{return REGSIZE;}
"$top"	{return REGTOP;}
"\n"	{return '\n';}
.	{ /*Do nothing*/}
%%

long long strbittolong(char *str){
	long long x = 0;
	int i,leng=strlen(str)-1;
	for(i=0;i<leng;i++)
		x = (x << 1)|(str[i]-0x30);
	return x;
}

long long strhextolong(char *str){
	long long x = 0;
	int i,leng = strlen(str)-1;
	for(i=0;i<leng;i++){
		if(isdigit(str[i]))
			x = (x << 4) | (str[i]-0x30);
		else{
			str[i] = toupper(str[i]);
			x = (x << 4) | (str[i]-0x37);
		}
	}
	return x;
}
