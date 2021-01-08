%{
void yyerror (char *s);
int yylex();
#include <stdio.h>     /* C declarations used in actions */
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

extern char* yytext;
extern FILE* yyin;
extern int yylineno;
int lineError = 0;

#define MAX_VAR 100

char symbols[MAX_VAR][20];
double symbols_values[MAX_VAR];
int totalVar = 0;

char symbols_str[MAX_VAR][20];
char symbols_values_str[100][1000];
int totalVarStr = 0;

int symbolVal(char*);
void updateSymbolVal(char*, double);
void FloatingPointException(int);
void push(char*, double);
void printValue(int, double);
void pushStr(char*, char*);
int computeSymbolIndexStr(char*);
void printValueStr(char*);
char* symbolValStr(char*);
%}

%union {double num; char id[20]; int type_id; char string[1000]; char ch;}         /* Yacc definitions */
%start lines
%token print

%type <type_id> data_type
%token <type_id> Integer
%token <type_id> Float
%token <type_id> Double
%token <type_id> Character 
%token <type_id> Bool
%token <type_id> String

%token GEQ
%token LEQ
%token AND
%token OR
%token EQ

%type<num> stat

%token IF
%type<num> smtm smtm_type smtm_types smtm_fun ELSE_ ELIF_ ELIF_S
%token ELSE
%token ELIF

%token FUN RETURN
%type<num> FUNCTION

%token <num> Character_Value
%token <string> String_Value

%token exit_command
%token <num> number
%token <id> identifier
%type <num> line lines exp term 
%type <string> str_exp str_term
%type <id> assignment

%nonassoc IF ELSE ELIF

%right '='

%left '-' '+'
%left '/' '*'

%left EQ
%left GEQ LEQ '<' '>'

%left OR
%left AND


%%

/* descriptions of expected inputs     corresponding actions (in C) */



lines   : line			 			{;}
		| lines line				{;}
		;

line 	: assignment ';'				{;}
		| exit_command ';'				{exit(EXIT_SUCCESS);}
		| print data_type exp ';'		{printValue($2, $3);}
		| print String str_exp ';'		{printValueStr($3);}
		| stat 							{;}
		| FUNCTION 				   		{;}
		;


data_type   : Integer   	 {$$ = $1;}
			| Float			 {$$ = $1;}
			| Double		 {$$ = $1;}
			| Character 	 {$$ = $1;}
			| Bool 	 		 {$$ = $1;}
			;

assignment  : identifier '=' exp  { updateSymbolVal($1,$3); }
			| data_type identifier '=' exp { push($2, $4); }
			| String identifier '=' String_Value {pushStr($2, $4);}
			;
exp    	: term                     {$$ = $1;}
     	| '(' exp ')'			   {$$ = $2;}
       	| exp '+' exp              {$$ = $1 + $3;}
       	| exp '-' exp              {$$ = $1 - $3;}
       	| exp '*' exp              {$$ = $1 * $3;}
        | exp '/' exp          	   {FloatingPointException($3);$$ = $1 / $3;}
		| Character_Value		   {$$ = $1;}

		| exp AND exp              {$$ = $1 && $3;}
		| exp OR exp               {$$ = $1 || $3;}
		| exp '<' exp 				{$$ = $1 < $3;}
		| exp '>' exp 				{$$ = $1 > $3;}
		| exp LEQ exp 				{$$ = $1 <= $3;}
		| exp GEQ exp 				{$$ = $1 >= $3;}
		| exp EQ exp 				{$$ = $1 == $3;}
		;



str_exp : str_term			{strcpy($$, $1);}
		;

str_term : String_Value 			{strcpy($$, $1);}
		 | identifier				{strcpy($$, symbolValStr($1));}
		 ;

term   	: number                {$$ = $1;}
		| identifier			{$$ = symbolVal($1);} 
        ;

stat	: IF '(' exp ')' smtm				{;}
		| IF '(' exp ')' smtm ELIF_S ELSE_ 	{;}
		| IF '(' exp ')' smtm ELSE_ 		{;}
		| IF '(' exp ')' smtm ELIF_S	 	{;}
		;

ELSE_   : ELSE smtm 						{;}
		;

ELIF_S  : ELIF_
		| ELIF_S ELIF_
		;

ELIF_   : ELIF '(' exp ')' smtm				{;}
		;

smtm 	: '{' smtm_types '}'				{;}
		| '{' '}'						{;}
		;

smtm_types  : smtm_type 					{;}
			| smtm_types smtm_type
			;

smtm_type 	: assignment ';'			{;}
			| exp        ';'			{;}
			| print data_type exp ';'	{printValue($2, $3);}
			| stat 						{;}
			;


FUNCTION 	: data_type FUN '(' ')' smtm_fun 		{;}
			;

smtm_fun	: '{' smtm_types RETURN exp ';' '}' 		{;}
			| '{' RETURN exp ';' '}'				{;}
			;

%%

int computeSymbolIndex(char* varName) {
	for (int i = 0; i < totalVar; i++) {
		if (strcmp(varName, symbols[i]) == 0) {
			return i;
		}
	}
	
	return -1;
} 



int symbolVal(char* symbol) {
	int i = computeSymbolIndex(symbol);
	return symbols_values[i];
}

char* symbolValStr(char* symbol) {
	int i = computeSymbolIndexStr(symbol);
	return symbols_values_str[i];
}

void updateSymbolVal(char* symbol, double val) {
	int i = computeSymbolIndex(symbol);

	if (i == -1) {
		printf("Variable %s was not declared in this scope %d\n", symbol, print);
		exit(0);
	} 

	symbols_values[i] = val;
}

void FloatingPointException(int val)
{
	if(!val)
    	{
			printf("Nu se poate imparti la 0\n");
		    exit(0);
		}
}

void push(char* symbol, double val) {
	int i = computeSymbolIndex(symbol);

	if (i != -1) {
		printf("The variable %s was already declared here\n", symbol);
		exit(0);
	}

	sprintf(symbols[totalVar], "%s", symbol);
	symbols_values[totalVar] = val;
	totalVar++;

}

int computeSymbolIndexStr(char* varName) {
	for (int i = 0; i < totalVarStr; i++) {
		if (strcmp(varName, symbols_str[i]) == 0) {
			return i;
		}
	}
	
	return -1;
}

void pushStr(char* symbol, char* val) {
	int i = computeSymbolIndexStr(symbol);

	if (i != -1) {
		printf("The variable %s was already declared here\n", symbol);
		exit(0);
	}

	sprintf(symbols_str[totalVarStr], "%s", symbol);
	sprintf(symbols_values_str[totalVarStr], "%s", val);

	totalVarStr++;
}

void printValue(int type_id, double value) {
	switch (type_id) {
		case Integer:
			printf("%d\n", (int)value); 
			break;
		case Float:
			printf("%f\n", (float)value);
			break;
		case Double:
			printf("%f", (double)value);
			break;
		case Bool:
			printf("%d\n", value != 0);
		case Character: 
			printf("%c\n", (char)value);
			break;
		default:
			break;
	}
}

void printValueStr(char* value) {
	printf("%s\n", value);
}

int main (void) {

	for (int i = 0; i < MAX_VAR; i++) {
		strcpy(symbols[i], "");
		symbols_values[i] = 0;
	}

    yyin = fopen("input", "r");

	return yyparse();
}

void yyerror (char *s) {fprintf (stderr, "%s\n", s);} // TODO