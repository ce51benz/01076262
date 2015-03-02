
%{
  #include <stdio.h>
  #include <math.h>
  #define R0 0
  #define R1 1
  #define R2 2
  #define R3 3
  #define R4 4
  #define R5 5
  #define R6 6
  #define R7 7
  #define R8 8
  #define R9 9
  #define RACC 10
  #define RSIZE 11
  #define RTOP 12
  void yyerror (char const *);
  long long r[13];
%}

/* Bison declarations.  */
%define api.value.type{long long}
%token REG0 REG1 REG2 REG3 REG4 REG5 REG6 REG7 REG8 REG9 REGACC REGSIZE REGTOP
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
| exp '\n'  { printf ("\t%lld\n", $1);r[RACC]=$1;}
| SHOW reg '\n'{ printf("\t%lld\n",r[$2]); }
| COPY reg TO reg '\n' { if($4 == RTOP)
				printf("$top is READONLY!\n");
			 else if($4 == RSIZE)
				printf("$size is READONLY!\n");
			 else
				r[$4] = r[$2];
			}
| PUSH reg { /*To be continued*/}
| POP reg  { /*To be continued*/}
;

exp:
  NUMDEC             { $$ = $1;   }
| NUMBIN	     { $$ = $1;   }
| NUMHEX	     { $$ = $1;   }
| reg		     { $$ = r[$1]; }
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

reg:REG0{$$ = R0;}
|REG1{$$ = R1;}
|REG2{$$ = R2;}
|REG3{$$ = R3;}
|REG4{$$ = R4;}
|REG5{$$ = R5;}
|REG6{$$ = R6;}
|REG7{$$ = R7;}
|REG8{$$ = R8;}
|REG9{$$ = R9;}
|REGACC{$$ = RACC;}
|REGTOP{$$ = RTOP;}
|REGSIZE{$$ = RSIZE;}
;


%%

void yyerror(char const *str){
printf("ERROR:%s\n",str);
}

void main(){
yyparse();
}

