%{
  #include <stdio.h>
  void yyerror (char const *);
  double powlong(long,long);
%}

/* Bison declarations.  */
/*%define api.value.type{double}*/
%union{
long intval;
double val;
}
%token NOT 102
%token NUMBIN 200
%token <intval> NUMDEC 201
%token NUMHEX 202
%token PUSH 300
%token POP 301
%token SHOW 302
%token COPY 303
%token TO 400
%left OR 101
%left AND 100
%left '-' '+'
%left '*' '/' '\\'
%precedence NEG NOT   /* negation--unary minus */
%right '^'        /* exponentiation */

%type <val> exp

%% /* The grammar follows.  */

input:
  %empty
| input line
;

line:
  '\n'
| exp '\n'  { printf ("\t%.10g\n", $1); }
;

exp:
  NUMDEC             { $$ = $1;	        }
| exp AND exp	     { $$ = (long long)$1 & (long long)$3;    }
| exp OR exp	     { $$ = (long long)$1 | (long long)$3;    }
| NOT exp            { $$ = ~(long long)$2;}
| exp '+' exp        { $$ = $1 + $3;      }
| exp '-' exp        { $$ = $1 - $3;      }
| exp '*' exp        { $$ = $1 * $3;      }
| exp '/' exp        { $$ = $1 / $3;      }
| exp '\\' exp	     { $$ = (long)$1 % (long)$3;	  }
| '-' exp  %prec NEG { $$ = -$2;          }
| exp '^' exp        { $$ = powlong($1,$3);}
| '(' exp ')'        { $$ = $2;           }
| '[' exp ']'	     { $$ = $2;		  }
| '{' exp '}'	     { $$ = $2;		  }
;

%%
double powlong(long base,long pownum){
long i;
double sum = 1;
for(i = 1;i<=pownum;i++)
	sum = sum * base;
return sum;
}

void yyerror(char const *str){
printf("BENZ ERROR:%s\n",str);
}

void main(){
yyparse();
}

