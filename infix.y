%{
  #include <stdio.h>
  #include <math.h>
  void yyerror (char const *);
%}

/* Bison declarations.  */
%define api.value.type{long long}
%token NOT 102
%token NUMBIN 200
%token NUMDEC 201
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

%% /* The grammar follows.  */

input:
  %empty
| input line
;

line:
  '\n'
| exp '\n'  { printf ("\t%lld\n", $1); }
;

exp:
  NUMDEC             { $$ = $1;   }
| exp AND exp	     { $$ = $1 & $3;    }
| exp OR exp	     { $$ = $1 | $3;    }
| NOT exp            { $$ = ~$2;}
| exp '+' exp        { $$ = $1 + $3;      }
| exp '-' exp        { $$ = $1 - $3;      }
| exp '*' exp        { $$ = $1 * $3;      }
| exp '/' exp        { $$ = $1 / $3;      }
| exp '\\' exp	     { $$ = $1 % $3;  }
| '-' exp  %prec NEG { $$ = -$2;          }
| exp '^' exp        { $$ = pow($1,$3);   }
| '(' exp ')'        { $$ = $2;           }
| '[' exp ']'	     { $$ = $2;		  }
| '{' exp '}'	     { $$ = $2;		  }
;

%%

void yyerror(char const *str){
printf("BENZ ERROR:%s\n",str);
}

void main(){
yyparse();
}

