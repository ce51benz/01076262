
%{
  #include <stdio.h>
  #include <math.h>
  #include <stdlib.h>
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
  typedef struct {
  long long **top; /*top keep pointer to top register which keep
			pointer to top of stack*/
  long long *size;
  long long *arr;
  long long maxsize;
  }stack;
  stack infixst;
  int errflag;
  void push(stack *,long long);
  long long pop(stack *);
  void yyerror (char const *);
  long long r[12];
  long long *rtop;
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
| exp '\n'  { if(!errflag){
		printf ("\t%lld\n", $1);r[RACC]=$1;
		}
	      else errflag = 0;
	    }
| SHOW reg '\n'{ if($2 != RTOP)printf("\t%lld\n",r[$2]);
		 else {if(rtop!=NULL)printf("\t%lld\n",*rtop);
			else yyerror("$top is NULL");
		 }
		}


| COPY reg TO reg '\n' { if($4 == RTOP)
				yyerror("$top is READONLY!");
			 else if($4 == RSIZE)
				yyerror("$size is READONLY!");
			 else{
				if($2 != RTOP)
					r[$4] = r[$2];
				else if(rtop!=NULL)
					r[$4] = *rtop;
				else
					yyerror("$top is NULL");			
			     }
			}

| PUSH reg '\n'{ if($2 != RTOP)
			push(&infixst,r[$2]);
		 else if(rtop!=NULL)
			push(&infixst,*rtop);
		 else
			yyerror("$top is NULL");
		}

| POP reg  '\n'{ if($2 == RTOP)
		yyerror("$top is READONLY!");
	     else if($2 == RSIZE)
		yyerror("$size is READONLY!");
	     else if(r[RSIZE] == 0)
		yyerror("Stack is empty.");
	     else
		r[$2] = pop(&infixst);
	   }
| PUSH error '\n'{yyerror("Missing register operand");yyerrok;}
| POP error '\n'{yyerror("Missing register operand");yyerrok;}
| SHOW error '\n'{yyerror("Missing register operand");yyerrok;}
| COPY reg TO error '\n' {yyerror("Missing register operand 2");yyerrok;}
| COPY error TO reg '\n' {yyerror("Missing register operand 1");yyerrok;}
| COPY reg error reg '\n'{yyerror("Missing TO ");yyerrok;}
| reg TO reg '\n'{yyerror("Missing COPY ");}
| reg TO reg error '\n'{yyerror("Unknown register and token operation");yyerrok;}
| COPY reg TO reg error '\n'{yyerror("Unknown token after register operand 2");yyerrok;}
| error '\n' {yyerror("Invalid expression input");yyerrok;}
;

exp:
  NUMDEC             { $$ = $1;   }
| NUMBIN	     { $$ = $1;   }
| NUMHEX	     { $$ = $1;   }
| reg		     {
			if($1 != RTOP)
				$$ = r[$1];
			else if(rtop != NULL)
				$$ = *rtop;
			else {
				yyerror("$top is NULL");errflag = 1;
			} 
		     }
| exp AND exp	     { $$ = $1 & $3;    }
| exp OR exp	     { $$ = $1 | $3;    }
| NOT exp            { $$ = ~$2;}
| exp '+' exp        { $$ = $1 + $3;}
| exp '-' exp        { $$ = $1 - $3;}
| exp '*' exp        { $$ = $1 * $3;}
| exp '/' exp        { if($3 == 0)
			{yyerror("Divisor cannot be 0");errflag=1;
			}
			else $$ = $1 / $3;
		     }

| exp '\\' exp	     { if($3 == 0)
			{yyerror("Divisor cannot be 0");errflag=1;
			}
			else $$ = $1 % $3;
		     }
| '-' exp  %prec NEG{ $$ = -$2; }
| exp '^' exp        { $$ = pow($1,$3);   }
| '(' exp ')' { $$ = $2;           }
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
if(strcmp(str,"syntax error")) 
printf("ERROR:%s\n",str);
}

void push(stack *st,long long value){
	if(*(st->size) == st->maxsize){
		st->maxsize = log10(st->maxsize)/log10(2);
		st->maxsize = pow(2,++st->maxsize);
		long long *arrnew = malloc(8*(st->maxsize));
		int j;
		for(j=0;j < *(st->size) ;j++){
		*(arrnew+j*8) = *((st->arr)+j*8);
		}
		/*Free unnescessary old arr*/	
		free(st->arr);
		st->arr = arrnew;
	}
	*( (st->arr) + ((*(st->size))++)*8 ) =  value;
	*(st->top) = (st->arr) + (*(st->size)-1)*8; 
}

long long pop(stack *st){
	if(*(st->size) > 0){
		if(*(st->size) > 1)
			*(st->top) = (st->arr) + (*(st->size)-2)*8;
		else
			*(st->top) = NULL;
	(*(st->size))--;
	return *(st->arr+(*(st->size))*8);
	}
}

void main(){
errflag = 0;
rtop = NULL;
infixst.top = &rtop;
infixst.size = &r[RSIZE];
infixst.maxsize = 1;
infixst.arr = malloc(8);
yyparse();
}

