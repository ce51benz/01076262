%option noyywrap
%{
#include<stdio.h>
#include "infix.tab.h" /*Reference infix.tab.h because this flex file use token type code base on declaration in bison file.*/ 
#include<ctype.h>
long long strbittolong(char *);
long long strhextolong(char *);
%}

/*Regular expression with related action*/
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
" "	{ /*Read whitespace but do nothing.*/}
.	{ return UNKNOWN; /*Return this token to mark that the input is invalid.*/}
%%

/*This function use to read string and convert it to bit representation
by read each character and substract each character by 0x30
to get real bit (either 0 or 1) keep that value in new variable
and shift that variable 1 bit for everytime which each character is read.*/
long long strbittolong(char *str){
	long long x = 0;
	int i,leng=strlen(str)-1;
	for(i=0;i<leng;i++)
		x = (x << 1)|(str[i]-0x30);
	return x;
}

/*This function use to read string and convert it to hexadecimal representation
by read each character and substract character either by 0x30 or 0x37
base on type of character(digit or alphabet)
to get real nibble (0000 to 1111) keep that value in new variable
convert alphabet to uppercase if necessary.
The last thing is shift that variable 4 bit for everytime which each character is read.*/
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
