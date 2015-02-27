%{
  #include <stdio.h>
  void yyerror (char const *);
  double powint(int,int); 
  double inttodouble(int);
%}

/* Bison declarations.  */
/*%define api.value.type{double}*/
%union{
int intval;
double val;
}
%token AND 100
%token OR 101
%token NOT 102
%token NUMBIN 200
%token <intval> NUMDEC 201
%token NUMHEX 202
%token PUSH 300
%token POP 301
%token SHOW 302
%token COPY 303
%token TO 400
%left '-' '+'
%left '*' '/' '\\'
%precedence NEG   /* negation--unary minus */
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
  NUMDEC             { $$ = $1;printf("%d $1 = %d $$ = %f\n",NUMDEC,$1,$$);	        }
| exp '+' exp        { $$ = $1 + $3;      }
| exp '-' exp        { $$ = $1 - $3;      }
| exp '*' exp        { $$ = $1 * $3;      }
| exp '/' exp        { $$ = $1 / $3;      }
| exp '\\' exp	     { $$ = (int)$1 % (int)$3;	  }
| '-' exp  %prec NEG { $$ = -$2;          }
| exp '^' exp        { $$ = powint ($1, $3); }
| '(' exp ')'        { $$ = $2;           }
;

%%
double powint(int base,int pownum){
int i;
double sum = 1;
for(i = 1;i<=pownum;i++)
	sum = sum * base;
}

double inttodouble(int x){
	return (double)x;
}
void yyerror(char const *str){
printf("BENZ ERROR:%s\n",str);
}

void main(){
yyparse();
}

