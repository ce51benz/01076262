
%{
  #include <stdio.h>
  #include <math.h>
  #include <stdlib.h>

  /*Define CONSTANT value to use for register referencing.*/
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
  
  /*Define type stack data structure to keep in-calculation data.*/ 
  typedef struct {
  long long **top; /*top keep pointer to top register which keep
			pointer to top of stack.*/

  long long *size; /*Pointer to long long variable.*/

  long long *arr;  /*Pointer of array.*/

  long long maxsize; /*Maxsize properties use to check whether to expand stack size.*/

  }stack;
  stack infixst; /*Stack for this calculator program.*/

  /*Error flag use to indicate that whether to show 
    calculation result or not(It went right or went wrong).
  */
  int errflag;

  void push(stack *,long long);
  long long pop(stack *);

  /*yyerror is function that yyparse will use automatically.*/
  void yyerror (char const *);

  /*r[12] which is array of long long (64 bit in size)
    stand for register $r0-$r9,$acc,$size.
    r[0] to r[9] is $r0 to $r9
    r[10] is $acc,r[11] is $size
    
    These items in array can be indexing to by use CONSTANT that define above
    example r[R5] , r[RACC] but indexing is do indirect by use semantic value instead.
    Later,you will see the C language syntax which use semantic value of some 
    nonterminal symbol to indexing in this array.
  */     
  long long r[12]; 


  /*Special variable which separate from typical array of long long variable (r[12])
    this variable keep address to top of stack.(Which is $top register)
  */
  long long *rtop;
%}

/* Bison declarations.*/

/*Semantic value data type is long long(64 bit in size).*/
%define api.value.type{long long}

/*General defined token.*/
%token REG0 REG1 REG2 REG3 REG4 REG5 REG6 REG7 REG8 REG9 REGACC REGSIZE REGTOP
%token NUMBIN 200
%token NUMDEC 201
%token NUMHEX 202
%token PUSH 300
%token POP 301
%token SHOW 302
%token COPY 303
%token TO 400
%token UNKNOWN 1000

/*OR operation has precedence less than AND operation,
assosication is do from left to right.
*/
%left OR 101
%left AND 100

/* +,- operation has precedence higher than OR,AND operation,
assosication is do from left to right.
*/
%left '-' '+'

/* * (multiply),/,\ operation has precedence higher than +,- operation,
assosication is do from left to right.
*/
%left '*' '/' '\\'

/* Negation--unary minus and NOT bitwise operation
which has higher precedence than OR,AND,+,-,*,/,\ 

The %precedence use to tell that both token have no association
but the defined-grammar will force calculator to do both operation from
right to left.
*/
%precedence NEG NOT   

/* Exponentiation,which has highest precedence
(but less than parentheses).*/
%right '^'        

%% 

/* The grammar follows. */

/*The input grammar:First rule which match any input line until user input CTRL + D*/
input:
  %empty
| input line
;

/*The line grammar:Rule that derive from nonterminal symbol line is handle 
  'line by line'.*/ 
line:
  '\n'
| exp '\n'  

/*The action for this rule to check that if expression that 
  user enter not cause an error,show caculation result
  otherwise reset errflag to 0.
*/
	    { if(!errflag){
		printf ("\t%lld\n", $1);r[RACC]=$1;
		}
	      else errflag = 0;
	    }

/*Action in SHOW reg is described follows
	check semantic value which is reg(Keep register reference constant)
	if register reference is RTOP check that $top(rtop variable,
	note that RTOP and rtop is not SAME) register keep something which 
	is not NULL? If yes display it,otherwise show error
	if register reference is others,display it normally.
*/
| SHOW reg '\n'{ if($2 != RTOP)printf("\t%lld\n",r[$2]);
		 else {if(rtop!=NULL)printf("\t%lld\n",*rtop);
			else yyerror("$top is NULL");
		 }
		}


/*Action in COPY reg TO reg is described follows
	check semantic value of 4th component in match tokens
	if register reference is RTOP or RSIZE 
	display error READONLY! suddenly.
	If register refenence is others
	check that is semantic value of 2nd component in match tokens 
	is RTOP?(which referencing to $top)
	If yes,check that whether $top keep something which 
	is not NULL? 
	If yes COPY it from $top to register that 4th component 
	in match tokens is referencing to,otherwise show error, 
	if register reference of 2nd component in match tokens 
	is others, COPY from it to register that 4th component in match tokens
	is referencing to normally.
*/
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

/*Action in PUSH reg is described follows
	check semantic value of reg that whether it is RTOP or not?
	if yes,check that $top register keep something which is not NULL
	if $top keep something which is NOT NULL,use push function to
	push value that $top (via dereferencing) hold to stack
	else show error,
	if no,use push function to push value suddenly via array referencing.
*/
| PUSH reg '\n'{ if($2 != RTOP)
			push(&infixst,r[$2]);
		 else if(rtop!=NULL)
			push(&infixst,*rtop);
		 else
			yyerror("$top is NULL");
		}

/*Action in POP reg is described follows
	check semantic value of reg that is it RTOP or RSIZE?
	if yes,show READONLY! error
	if no,check that stack size is not 0 via check value that $size register keep
	if value is not zero, use push function to write value from top of stack
	to target register,otherwise show 'empty stack' error.
*/
| POP reg  '\n'{ if($2 == RTOP)
		yyerror("$top is READONLY!");
	     else if($2 == RSIZE)
		yyerror("$size is READONLY!");
	     else if(r[RSIZE] == 0)
		yyerror("Stack is empty.");
	     else
		r[$2] = pop(&infixst);
	   }

/*The rest of 'line' grammar is error handling actions which are display
  error message for any case that invalid expression/command is submitted.
*/
| PUSH error '\n'{yyerror("Missing register operand");yyerrok;}
| POP error '\n'{yyerror("Missing register operand");yyerrok;}
| SHOW error '\n'{yyerror("Missing register operand");yyerrok;}
| COPY reg TO error '\n' {yyerror("Missing register operand 2");yyerrok;}
| COPY error TO reg '\n' {yyerror("Missing register operand 1");yyerrok;}
| COPY reg error reg '\n'{yyerror("Missing TO ");yyerrok;}
| reg TO reg '\n'{yyerror("Missing COPY ");}
| reg TO reg error '\n'{yyerror("Unknown register and token operation");yyerrok;}
| COPY reg TO reg error '\n'{yyerror("Unknown token after register operand 2");yyerrok;}

/*The last rule handle error which is not match above.*/
| error '\n' {yyerror("Invalid expression input");yyerrok;} 
;


/*The exp grammar:Handle expression calculation base on precedence and rule 
  that ours provides.
*/
exp:
/*The first three rules is constant token,the action is assign semantic value of exp by
  use value of $1(or 1st component of match token.)*/
  NUMDEC             { $$ = $1;   }
| NUMBIN	     { $$ = $1;   }
| NUMHEX	     { $$ = $1;   }

/*This rule handle register reference by check that
  is value in reg (or $1) is not RTOP?If yes,assign semantic value of exp by use
  array of long long and indexing to by use semantic value of reg as an index number.
  If no,check that is $top is not NULL.If it is not NULL,assign semantic value of exp
  by use value that rtop reference to normally,
  otherwise show error and set errflag to 1.
*/
| reg		     {
			if($1 != RTOP)
				$$ = r[$1];
			else if(rtop != NULL)
				$$ = *rtop;
			else {
				yyerror("$top is NULL");errflag = 1;
			} 
		     }

/*6 rule below has action which calculate value base on input pattern*/
| exp AND exp	     { $$ = $1 & $3;    }
| exp OR exp	     { $$ = $1 | $3;    }
| NOT exp            { $$ = ~$2;}
| exp '+' exp        { $$ = $1 + $3;}
| exp '-' exp        { $$ = $1 - $3;}
| exp '*' exp        { $$ = $1 * $3;}

/*Action of 2 MATH-Divide rules must check that is divisor is 0 if yes show error
  and set errflag to 1 which ignore calculation result from that invalid input line
  if no do calculation normally.
*/ 
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

/*Unary operation rules.
  Use %prec to tell parser that this rule has precedence equal 
  to precedence of NEG token.
*/
| '-' exp  %prec NEG{ $$ = -$2; }

/*Action of exponentation rules use pow function of math library and
  assign result to $$(Semantic value of exp).
*/
| exp '^' exp        { $$ = pow($1,$3);   }

/*The last three rules in exp grammar use for do calculation in highest priority
  via match parentheses.
*/
| '(' exp ')' 	     { $$ = $2;           }
| '[' exp ']'	     { $$ = $2;		  }
| '{' exp '}'	     { $$ = $2;		  }

;

/*The reg grammar:Handle register reference constant which is assigned to
  semantic value of reg.
*/
reg:
 REG0		{$$ = R0;}
|REG1		{$$ = R1;}
|REG2		{$$ = R2;}
|REG3		{$$ = R3;}
|REG4		{$$ = R4;}
|REG5		{$$ = R5;}
|REG6		{$$ = R6;}
|REG7		{$$ = R7;}
|REG8		{$$ = R8;}
|REG9		{$$ = R9;}
|REGACC		{$$ = RACC;}
|REGTOP		{$$ = RTOP;}
|REGSIZE	{$$ = RSIZE;}
;


%%

/*This function use to display error message*/
void yyerror(char const *str){
if(strcmp(str,"syntax error")) 
printf("ERROR:%s\n",str);
}

/*void push(stack *st,long long value)
	parameter:st as pointer to stack ,value as long long.
	The functional of this function is push value to stack
	if stack is full,expand stack's maxsize by double
	(Remember to use malloc for 8*n where n is maxsize value and 
	8 is size for 1 item that keep in stack.)
	copy old data in arr properties to newly allocated.
	Free old arr and add value to array.
	If stack is not full,add value to array suddenly.
	Finally,update $top register value by use address of arr[size-1]
*/
void push(stack *st,long long value){
	if(*(st->size) == st->maxsize){
		st->maxsize = log10(st->maxsize)/log10(2);
		st->maxsize = pow(2,++st->maxsize);
		long long *arrnew = malloc(8*(st->maxsize));
		int j;
		for(j=0;j < *(st->size) ;j++){
		*(arrnew+j*8) = *((st->arr)+j*8);
		}	
		free(st->arr);
		st->arr = arrnew;
	}
	*( (st->arr) + ((*(st->size))++)*8 ) =  value;
	*(st->top) = (st->arr) + (*(st->size)-1)*8; 
}


/*long long pop(stack *st)
	parameter: st as pointer to stack.
	return value:long long type which is old value that is in top of stack.
	The functional of this function is pop value out stack and return the
	value which is value that popped out from stack.
	If stack is not empty,check next that is stack size is more that one
	If yes,update $top register value by use address of arr[size-2]
	else set $top register to NULL.Then decrease stack size and return from function
	by use arr[size] value.If stack is empty,do nothing.
*/
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

/*The main program is initialized stack variable,set $top register to NULL and 
  set errflag to 0.For size and top properties in stack(infixst.top,infixst.size),both   
  keep address of $top and $size register(NOT real value).
  Finally use yyparse to start parsing.
*/
void main(){
errflag = 0;
rtop = NULL;
infixst.top = &rtop;
infixst.size = &r[RSIZE];
infixst.maxsize = 1;
infixst.arr = malloc(8); /*Create new array size 1 item(8 bytes).*/
yyparse(); /*Parsing function use by bison parser.*/
}

