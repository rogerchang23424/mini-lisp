%{
#include <string.h>
#include <stdlib.h>
#include <string.h>
#include "test.h"
#include "minilisp.tab.h"
int col = 0;
int len;
extern void yyerror(const char *message);
%}
%%
\t|\r|" "|\n	{}
<<EOF>>		{return(0);}
[+\*\/\%][a-z0-9\-]+|\-[a-zA-Z\-]	{len = strlen(yytext); yylval.name = (char*)malloc((len+10)*sizeof(char)); strcpy(yylval.name, yytext); return(ID);}
"+"		{yylval.op = '+'; return(PLUS);}
"-"		{yylval.op = '-'; return(MINUS);}
"*"		{yylval.op = '*'; return(MULTIPLY);}
"/"		{yylval.op = '/'; return(DIVIDE);}
"mod"	{yylval.op = '%'; return(MODULUS);}
">"		{yylval.op = '>'; return(GREATER);}
"<"		{yylval.op = '<'; return(SMALLER);}
"="		{yylval.op = '='; return(EQUAL);}
"and"	{yylval.op = '&'; return(AND);}
"or"	{yylval.op = '|'; return(OR);}
"not"	{yylval.op = '!'; return(NOT);}
"("		{yylval.op = '('; return(LPAREN);}
")"		{yylval.op = ')'; return(RPAREN);}
"print-num"	{return(PRINTNUM);}
"print-bool"	{return(PRINTBOOL);}
"define"	{return(DEFINE);}
"fun"	{return(FUNC);}
"if"	{return(IF);}
"#t"|"#f"	{if(!strcmp(yytext, "#t")) yylval.boolvalue = 1; else yylval.boolvalue = 0; return(BOOLVAL);}
0|[1-9][0-9]*|\-[1-9][0-9]*	{yylval.value = atoi(yytext); return(NUMBER);}
[a-z]([a-z0-9\-])*	{len = strlen(yytext); yylval.name = (char*)malloc((len+10)*sizeof(char)); strcpy(yylval.name, yytext); return(ID);}
.		{yyerror("Error: Expect ID.");exit(0);}
%%