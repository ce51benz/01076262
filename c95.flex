D			[0-9]
L			[a-zA-Z_]
H			[a-fA-F0-9]
E			[Ee][+-]?{D}+
FS			(f|F|l|L)
IS			(u|U|l|L)*

%option noyywrap

%{
#include <stdio.h>

enum {IDENTIFIER=300, CONSTANT, STRING_LITERAL, SIZEOF};
enum {PTR_OP=400, INC_OP, DEC_OP, LEFT_OP, RIGHT_OP, LE_OP, GE_OP, EQ_OP, NE_OP};
enum {AND_OP=500, OR_OP, MUL_ASSIGN, DIV_ASSIGN, MOD_ASSIGN, ADD_ASSIGN};
enum {SUB_ASSIGN=600, LEFT_ASSIGN, RIGHT_ASSIGN, AND_ASSIGN, XOR_ASSIGN, OR_ASSIGN,TYPE_NAME};
enum {TYPEDEF=700, EXTERN, STATIC, AUTO, REGISTER};
enum {CHAR=800, SHORT, INT, LONG, SIGNED, UNSIGNED, FLOAT, DOUBLE, CONST, VOLATILE, VOID,STRUCT, UNION, ENUM, ELLIPSIS};
enum {CASE=900, DEFAULT, IF, ELSE, SWITCH, WHILE, DO, FOR, GOTO, CONTINUE, BREAK, RETURN};

void comment(void);
void dopreproc();
%}

%%
"/*"			{ comment(); }
[#]                     { dopreproc();}  
"auto"			{ printf("[%d]\n",AUTO); }
"break"			{ printf("[%d]\n",BREAK); }
"case"			{ printf("[%d]\n",CASE); }
"char"			{ printf("[%d]\n",CHAR); }
"const"			{ printf("[%d]\n",CONST); }
"continue"		{ printf("[%d]\n",CONTINUE); }
"default"		{ printf("[%d]\n",DEFAULT); }
"do"			{ printf("[%d]\n",DO); }
"double"		{ printf("[%d]\n",DOUBLE); }
"else"			{ printf("[%d]\n",ELSE); }
"enum"			{ printf("[%d]\n",ENUM); }
"extern"		{ printf("[%d]\n",EXTERN); }
"float"			{ printf("[%d]\n",FLOAT); }
"for"			{ printf("[%d]\n",FOR); }
"goto"			{ printf("[%d]\n",GOTO); }
"if"			{ printf("[%d]\n",IF); }
"int"			{ printf("[%d]\n",INT); }
"long"			{ printf("[%d]\n",LONG); }
"register"		{ printf("[%d]\n",REGISTER); }
"return"		{ printf("[%d]\n",RETURN); }
"short"			{ printf("[%d]\n",SHORT); }
"signed"		{ printf("[%d]\n",SIGNED); }
"sizeof"		{ printf("[%d]\n",SIZEOF); }
"static"		{ printf("[%d]\n",STATIC); }
"struct"		{ printf("[%d]\n",STRUCT); }
"switch"		{ printf("[%d]\n",SWITCH); }
"typedef"		{ printf("[%d]\n",TYPEDEF); }
"union"			{ printf("[%d]\n",UNION); }
"unsigned"		{ printf("[%d]\n",UNSIGNED); }
"void"			{ printf("[%d]\n",VOID); }
"volatile"		{ printf("[%d]\n",VOLATILE); }
"while"			{ printf("[%d]\n",WHILE); }

{L}({L}|{D})*		{ return(check_type()); }

0[xX]{H}+{IS}?		{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }
0{D}+{IS}?		{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }
{D}+{IS}?		{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }
L?'(\\.|[^\\'])+'	{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }

{D}+{E}{FS}?		{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }
{D}*"."{D}+({E})?{FS}?	{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }
{D}+"."{D}*({E})?{FS}?	{ printf("[%d, %d]\n",CONSTANT,atoi(yytext)); }

L?\"(\\.|[^\\"])*\"	{ printf("[%d]\n",STRING_LITERAL); }

"..."			{ printf("[%d]\n",ELLIPSIS); }
">>="			{ printf("[%d]\n",RIGHT_ASSIGN); }
"<<="			{ printf("[%d]\n",LEFT_ASSIGN); }
"+="			{ printf("[%d]\n",ADD_ASSIGN); }
"-="			{ printf("[%d]\n",SUB_ASSIGN); }
"*="			{ printf("[%d]\n",MUL_ASSIGN); }
"/="			{ printf("[%d]\n",DIV_ASSIGN); }
"%="			{ printf("[%d]\n",MOD_ASSIGN); }
"&="			{ printf("[%d]\n",AND_ASSIGN); }
"^="			{ printf("[%d]\n",XOR_ASSIGN); }
"|="			{ printf("[%d]\n",OR_ASSIGN); }
">>"			{ printf("[%d]\n",RIGHT_OP); }
"<<"			{ printf("[%d]\n",LEFT_OP); }
"++"			{ printf("[%d]\n",INC_OP); }
"--"			{ printf("[%d]\n",DEC_OP); }
"->"			{ printf("[%d]\n",PTR_OP); }
"&&"			{ printf("[%d]\n",AND_OP); }
"||"			{ printf("[%d]\n",OR_OP); }
"<="			{ printf("[%d]\n",LE_OP); }
">="			{ printf("[%d]\n",GE_OP); }
"=="			{ printf("[%d]\n",EQ_OP); }
"!="			{ printf("[%d]\n",NE_OP); }
";"			{ printf("[%d]\n",';'); }
("{"|"<%")		{ printf("[%d]\n",'{'); }
("}"|"%>")		{ printf("[%d]\n",'}'); }
","			{ printf("[%d]\n",','); }
":"			{ printf("[%d]\n",':'); }
"="			{ printf("[%d]\n",'='); }
"("			{ printf("[%d]\n",'('); }
")"			{ printf("[%d]\n",')'); }
("["|"<:")		{ printf("[%d]\n",'['); }
("]"|":>")		{ printf("[%d]\n",']'); }
"."			{ printf("[%d]\n",'.'); }
"&"			{ printf("[%d]\n",'&'); }
"!"			{ printf("[%d]\n",'!'); }
"~"			{ printf("[%d]\n",'~'); }
"-"			{ printf("[%d]\n",'-'); }
"+"			{ printf("[%d]\n",'+'); }
"*"			{ printf("[%d]\n",'*'); }
"/"			{ printf("[%d]\n",'/'); }
"%"			{ printf("[%d]\n",'%'); }
"<"			{ printf("[%d]\n",'<'); }
">"			{ printf("[%d]\n",'>'); }
"^"			{ printf("[%d]\n",'^'); }
"|"			{ printf("[%d]\n",'|'); }
"?"			{ printf("[%d]\n",'?'); }

[ \t\v\n\f]		{ }
.			{ /* ignore bad characters */ }

%%

void dopreproc()
{
while(input() != '\n');
}

void comment()
{
	char c,c1;
	while(1){
	if(c = input() != '*')continue;
	if(c1 = input() != '/')unput(c1);
	else break;
	}
}

int check_type()
{
/*
* pseudo code --- this is what it should check
*
*	if (yytext == type_name)
*		printf("[%d]\n",TYPE_NAME);
*
*	printf("[%d, %s]\n",IDENTIFIER,yytext);
*/

/*
*	it actually will only return IDENTIFIER
*/

	printf("[%d, %s]\n",IDENTIFIER,yytext);
}

main(int argc,char **argv){
int tokenNumber;
	while(tokenNumber = yylex());
}
