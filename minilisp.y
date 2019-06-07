%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>
#include "test.h"
void yyerror(const char *message);
extern struct symbol_map* symbol_table;
extern struct ast_node* NONE;
char error_msg[500];

#define ERROR \
if($$->type == EXCEPTION) \
	yyerrror((struct ast_exception_node*));
%}
%union{
struct ast_node* ast;
int value;
int boolvalue;
char* name;
char op;
}
%token <op> PLUS
%token <op> MINUS
%token <op> MULTIPLY
%token <op> DIVIDE
%token <op> MODULUS
%token <op> GREATER
%token <op> SMALLER
%token <op> EQUAL
%token <op> AND
%token <op> OR
%token <op> NOT
%token <op> LPAREN
%token <op> RPAREN
%token <name> PRINTNUM
%token <name> PRINTBOOL
%token <name> DEFINE
%token <name> FUNC
%token <name> IF
%token <name> ID
%token <value> NUMBER
%token <boolvalue> BOOLVAL
%type <ast> program stmts stmt print_stmt exp num_op logical_op number boolval exps if_exp define_stmt var fun_exp fun_call vars params
%start program
%%
program : stmts		{$$=NONE;}
		;
stmts : stmt stmts		{$$=NONE;}
		|stmt		{$$=NONE;}
		;
stmt : print_stmt				{print_data($1);$$=NONE;}
		| exp					{print_data($1);$$=NONE;}
		| define_stmt			{print_data($1);$$=NONE;}
		;
print_stmt : LPAREN PRINTNUM exp RPAREN	{$$ = print_int($3);}
		| LPAREN PRINTBOOL exp RPAREN	{$$ = print_bool($3);}
		;
define_stmt : LPAREN DEFINE ID exp RPAREN	{add_global_symbol_data($3, $4); $$=NONE;}
		;
exp : boolval		{$$ = $1;}
		| number	{$$ = $1;}
		| num_op	{$$ = $1;}
		| logical_op	{$$ = $1;}
		| if_exp	{$$ = $1;}
		| var		{$$ = $1;}
		| fun_exp	{$$=$1;}
		| fun_call	{$$=$1;}
		;
num_op : LPAREN PLUS exp exps RPAREN		{$$ = add_or_mul_number($2, $3, $4);}
		| LPAREN MULTIPLY exp exps RPAREN	{$$ = add_or_mul_number($2, $3, $4);}
		| LPAREN MINUS exp exp RPAREN		{$$ = sub_or_div_number($2, $3, $4);}
		| LPAREN DIVIDE exp exp RPAREN		{$$ = sub_or_div_number($2, $3, $4);}
		| LPAREN MODULUS exp exp RPAREN		{$$ = sub_or_div_number($2, $3, $4);}
		| LPAREN GREATER exp exp RPAREN		{$$ = ast_node_digit_cmp($2, $3, $4);}
		| LPAREN SMALLER exp exp RPAREN		{$$ = ast_node_digit_cmp($2, $3, $4);}
		| LPAREN EQUAL exp exps RPAREN		{$$ = ast_node_digit_cmpeq($3, $4);}
		;
logical_op : LPAREN AND exp exps RPAREN		{$$ = ast_and_or_operation($2, $3, $4);}
		| LPAREN OR exp exps RPAREN			{$$ = ast_and_or_operation($2, $3, $4);}
		| LPAREN NOT exp RPAREN				{$$ = ast_not_operation($3);}
		;
boolval : BOOLVAL	{$$ = new_ast_bool_node($1);}
		;
number : NUMBER		{$$ = new_ast_int_node($1);}
		;
var : ID		{$$ = make_symbol($1);}
		;
if_exp : LPAREN IF exp exp exp RPAREN		{$$ = new_if_else_node($3, $4, $5);}
		;
fun_exp : LPAREN FUNC LPAREN vars RPAREN exp RPAREN		{$$=make_function($4, $6);}
		| LPAREN FUNC LPAREN RPAREN exp RPAREN			{$$=make_function(NONE, $5);}
		;
vars	: var vars							{$$=append_ast_list_node($2, $1);}
		|var								{$$=new_ast_list_node($1);}
		; 
fun_call : LPAREN var params RPAREN				{$$=new_callback_node($2, $3);}
		| LPAREN fun_exp params RPAREN			{$$=new_callback_node($2, $3);}
params : exp params							{if($2->type==LISP_NONE){$$=new_ast_list_node($1);}else{$$ = append_ast_list_node($2, $1);}}
		|									{$$=NONE;}
exps : exp exps		{$$ = append_ast_list_node($2, $1);}
		| exp		{$$ = new_ast_list_node($1);}
		;
%%

void yyerror(const char* message){
	printf("%s\n", message);
}

void print_data(struct ast_node* r1){
	if(ffdebug){
		switch(r1->type){
		case LISP_BOOL:
		printf("Type: LISP_BOOL value: %s\n", ((struct ast_bool_node*)r1)->boolvalue? "#t": "#f");
		return;
		case LISP_INT:
		printf("Type: LISP_INT value: %d\n", ((struct ast_int_node*)r1)->value);
		return;
		case LISP_NONE:
		printf("LISP_NONE\n");
		return;
		case LISP_RATIONAL:
		printf("LISP_RATIONAL\n");
		return;
		case LISP_FUNC:
		printf("LISP_FUNC\n");
		return;
		case LISP_IFELSE:
		printf("LISP_IFELSE\n");
		return;
		case LISP_SYMBOL:
		printf("Type: LISP_SYMBOL name: %s\n", ((struct ast_symbol_node*)r1)->name);
		return;
		case LISP_LIST:
		printf("Type: LISP_LIST data=[");
		while(r1){
			print_data(((struct ast_list_node*)r1)->data);
			r1 = ((struct ast_list_node*)r1)->next;
		}
		printf("]\n");
		return;
		case LISP_CALL:
		printf("Type: LISP_CALLBACK\n");
		return;
		}
	}
}

void get_type_str(struct ast_node* r1, char* msg, int max_len){
	switch(r1->type){
		case LISP_BOOL:
		strncpy(msg, "boolean", max_len);
		return;
		case LISP_INT:
		strncpy(msg, "number", max_len);
		return;
		case LISP_NONE:
		strncpy(msg, "none", max_len);
		return;
		case LISP_RATIONAL:
		strncpy(msg, "rational", max_len);
		return;
		case LISP_FUNC:
		strncpy(msg, "function", max_len);
		return;
		case LISP_IFELSE:
		strncpy(msg, "if_else", max_len);
		return;
		case LISP_SYMBOL:
		get_type_str(find(r1, NULL), msg, max_len);
		return;
		case LISP_LIST:
		strncpy(msg, "list", max_len);
		return;
		}
}

struct ast_node* find(struct ast_node* $1, struct symbol_map* s){
	struct ast_symbol_node* src = (struct ast_symbol_node*)$1;
	struct symbol_map* items = symbol_table;
	struct symbol_map* locals = s;
	
	while(locals){
		if(!strcmp(locals->name, src->name)){
			return locals->data;
		}
		locals = locals->next;
	}
	
	while(items){
		if(!strcmp(items->name, src->name)){
			return items->data;
		}
		items = items->next;
	}
	printf("Symbol not defined: %s\n", src->name);
	exit(1);
}

void try_calc(struct ast_node** dst, struct ast_node* src1, struct ast_node* src2, int op, bool freenode){
	if(src1->type == LISP_INT && src2->type == LISP_INT){
		switch(op){
		case '+':
		*dst = new_ast_int_node(((struct ast_int_node*)src1)->value + ((struct ast_int_node*)src2)->value);
		break;
		case '-':
		*dst = new_ast_int_node(((struct ast_int_node*)src1)->value - ((struct ast_int_node*)src2)->value);
		break;
		case '*':
		*dst = new_ast_int_node(((struct ast_int_node*)src1)->value * ((struct ast_int_node*)src2)->value);
		break;
		case '/':
		*dst = new_ast_int_node(((struct ast_int_node*)src1)->value / ((struct ast_int_node*)src2)->value);
		break;
		case '%':
		*dst = new_ast_int_node(((struct ast_int_node*)src1)->value % ((struct ast_int_node*)src2)->value);
		break;
		case '>':
		*dst = new_ast_bool_node(((struct ast_int_node*)src1)->value > ((struct ast_int_node*)src2)->value);
		break;
		case '<':
		*dst = new_ast_bool_node(((struct ast_int_node*)src1)->value < ((struct ast_int_node*)src2)->value);
		break;
		case '=':
		*dst = new_ast_bool_node(((struct ast_int_node*)src1)->value == ((struct ast_int_node*)src2)->value);
		break;
		}
		if(freenode){free(src1);free(src2);}
	}else if(src1->type == LISP_BOOL && (src2->type == LISP_BOOL || src2->type == LISP_NONE)){
			switch(op){
			case '&':
			if(src2->type == LISP_BOOL)
				*dst = new_ast_bool_node(((struct ast_bool_node*)src1)->boolvalue & ((struct ast_bool_node*)src2)->boolvalue);
			else{
				get_type_str(src2, error_msg, 490);
				printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
				exit(1);
			}
			break;
			case '|':
			if(src2->type == LISP_BOOL)
				*dst = new_ast_bool_node(((struct ast_bool_node*)src1)->boolvalue | ((struct ast_bool_node*)src2)->boolvalue);
			else{
				get_type_str(src2, error_msg, 490);
				printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
				exit(1);
			}
			break;
			case '!':
			*dst = new_ast_bool_node(!((struct ast_bool_node*)src1)->boolvalue);
			break;
			}
			if(freenode){free(src1);if(src2->type == LISP_BOOL)free(src2);}
	}else if((src1->type == LISP_SYMBOL || src1->type == LISP_RATIONAL || src1->type == LISP_CALL) || (src2->type == LISP_SYMBOL || src2->type == LISP_RATIONAL || src2->type == LISP_CALL)){
		if(ffdebug)printf("try_calc_lisp_symbol entered!");
		*dst = new_ast_rational_node(op, src1, src2);
		print_data(*dst);
	}else{
		if(op == '+' || op == '-' || op == '*' || op == '/' || op == '%' || op == '>' || op == '<' || op == '='){
			if(src1->type != LISP_INT){
				get_type_str(src1, error_msg, 490);
				printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
				exit(1);
			}
			if(src2->type != LISP_INT){
				get_type_str(src2, error_msg, 490);
				printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
				exit(1);
			}
		}else if(op == '&' || op == '|' || op == '!'){
			if(src1->type != LISP_BOOL){
				get_type_str(src1, error_msg, 490);
				printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
				exit(1);
			}
			if(src2->type != LISP_BOOL){
				get_type_str(src2, error_msg, 490);
				printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
				exit(1);
			}
		}
	}
}

struct ast_node* eval(struct ast_node* root, struct symbol_map* s){
	struct ast_node* left;
	struct ast_node* right;
	struct ast_node *calc_res;
	struct ast_function_node* real_funobj;
	switch(root->type){
	case LISP_INT:
		return root;
	case LISP_BOOL:
		return root;
	case LISP_SYMBOL:
		return find(root, s);
	case LISP_RATIONAL:
		left = eval(root->left, s);
		right = eval(root->right, s);
		try_calc(&calc_res, left, right, ((struct ast_rational_node*)root)->op, false);
		return calc_res;
	case LISP_IFELSE:
		calc_res = eval(((struct ast_ifelse_node*)root)->condition, s);
		if(calc_res->type == LISP_BOOL){
			if(((struct ast_bool_node*)calc_res)->boolvalue){
				return eval(((struct ast_ifelse_node*)root)->if_branch, s);
			}else{
				return eval(((struct ast_ifelse_node*)root)->else_branch, s);
			}
		}else{
			get_type_str(calc_res, error_msg, 490);
			printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
			exit(1);
		}
	case LISP_CALL:
		real_funobj = (struct ast_function_node*)eval(((struct ast_callback_node*)root)->func, NULL);
		if(real_funobj->type != LISP_FUNC){
			get_type_str((struct ast_node*)real_funobj, error_msg, 490);
			printf("Type Error: Expect 'function' but got '%s'.\n", error_msg);
			exit(1);
		}
		
		if(ffdebug){printf("function call entered! %p;", s); print_data(root);}
		append(real_funobj->params, ((struct ast_callback_node*)root)->args, &(((struct ast_callback_node*)root)->local_symbol_table), s);if(ffdebug){printf("%p, ", s);printf("%p\n", ((struct ast_callback_node*)root)->local_symbol_table);}
		calc_res = eval(real_funobj->body, ((struct ast_callback_node*)root)->local_symbol_table);
		if(ffdebug){printf("function call exited!\n");}
		rremove(&((struct ast_callback_node*)root)->local_symbol_table);
		return calc_res;
	case LISP_FUNC:
		return root;
	}
}

void append(struct ast_node* names, struct ast_node* arggs, struct symbol_map** local, struct symbol_map* s){
	struct ast_list_node* p_names;
	struct ast_list_node* args;
	if(names->type == LISP_LIST){
		print_data(arggs);
		p_names = (struct ast_list_node*)names;
		args = (struct ast_list_node*)arggs;
		while(p_names && args){
			add_local_symbol_data(((struct ast_symbol_node *)p_names->data)->name, ((struct ast_list_node*)args)->data, local, s);
			p_names = (struct ast_list_node*)p_names->next;
			args = (struct ast_list_node*)args->next;
		}
		
		if(p_names || args){
			printf("Error: Wrong args.");
			exit(1);
		}
	}else if(names->type == LISP_NONE){
		print_data(arggs);
	}
}

void rremove(struct symbol_map** local){
	*local = NULL;
}

void add_global_symbol_data(char* name, struct ast_node* $1){
	struct symbol_map* new_map = (struct symbol_map*)malloc(sizeof(struct symbol_map));
	new_map->data = eval($1, NULL);
	int len = strlen(name);
	char* nname = (char*)malloc((len+10)*sizeof(char));
	strcpy(nname, name);
	new_map->name = nname;
	new_map->next = symbol_table;
	symbol_table = new_map;
}

void add_local_symbol_data(char* name, struct ast_node* $1, struct symbol_map** local, struct symbol_map* s){
	struct symbol_map* new_map = (struct symbol_map*)malloc(sizeof(struct symbol_map));
	new_map->data = eval($1, s);
	int len = strlen(name);
	char* nname = (char*)malloc((len+10)*sizeof(char));
	strcpy(nname, name);
	new_map->name = nname;
	new_map->next = *local;
	*local = new_map;
}

struct ast_node* new_ast_none(){
	struct ast_node *$$ = (struct ast_node*)malloc(sizeof(struct ast_node));
	if(ffdebug){
		printf("%p\n", $$);
	}
	$$->type = LISP_NONE;
	$$->left = $$->right = NULL;
	return $$;
}

struct ast_node* new_ast_int_node(int value){
	struct ast_int_node *$$ = (struct ast_int_node*)malloc(sizeof(struct ast_int_node));
	assert($$ != NULL);
	
	$$->value = value;
	
	$$->left = $$->right = NULL;
	$$->type = LISP_INT;
	return (struct ast_node*)$$;
}

struct ast_node* new_ast_bool_node(int boolvalue){
	struct ast_bool_node *$$ = (struct ast_bool_node*)malloc(sizeof(struct ast_bool_node));
	assert($$ != NULL);
	
	$$->boolvalue = boolvalue;
	
	$$->left = $$->right = NULL;
	$$->type = LISP_BOOL;
	return (struct ast_node*)$$;
}

struct ast_node* new_ast_rational_node(int op, struct ast_node* $1, struct ast_node* $2){
	struct ast_rational_node *$$ = (struct ast_rational_node*)malloc(sizeof(struct ast_rational_node));
	assert($$ != NULL);
	
	$$->op = op;
	
	$$->left = $1; $$->right = $2;
	$$->type = LISP_RATIONAL;
	return (struct ast_node*)$$;
}

struct ast_node* print_int(struct ast_node* $1){
	if(ffdebug) printf("print_int entered!\n");
	print_data($1);
	struct ast_node* real_result = eval($1, NULL);
	print_data(real_result);
	if(real_result->type == LISP_INT){
		printf("%d\n", ((struct ast_int_node *)real_result)->value);
	}else{
		get_type_str(real_result, error_msg, 490);
		printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
		exit(1);
	}
	if($1->type == LISP_INT){free($1);}
	return NONE;
}

struct ast_node* append_ast_list_node(struct ast_node* $1, struct ast_node* $2){
	if($1->type != LISP_LIST) return new_ast_list_node($1);
	else{
		struct ast_list_node* $$ = (struct ast_list_node* )malloc(sizeof(struct ast_list_node));
		$$->type = LISP_LIST;
		$$->left = $$->right = NULL;
		
		$$->data = $2;
		$$->next = $1;
		return (struct ast_node*)$$;
	}
}

struct ast_node* new_ast_list_node(struct ast_node* $1){
	struct ast_list_node* $$ = (struct ast_list_node* )malloc(sizeof(struct ast_list_node));
	$$->type = LISP_LIST;
	$$->left = $$->right = NULL;
	
	$$->data = $1;
	$$->next = NULL;
	return (struct ast_node*)$$;
}

struct ast_node* print_bool(struct ast_node* $1){
	struct ast_node* real_result = eval($1, NULL);
	if(real_result->type == LISP_BOOL){
		printf("%s\n", ((struct ast_bool_node *)real_result)->boolvalue? "#t": "#f");
	}else{
		get_type_str(real_result, error_msg, 490);
		printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
		exit(1);
	}
	return NONE;
}

struct ast_node* add_or_mul_number(int op, struct ast_node* $1, struct ast_node* $2){
	struct ast_list_node* $$ = (struct ast_list_node*)$2;
	struct ast_node* result = NULL;
	
	if($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL){
		result = $1;
	}else{
		get_type_str($1, error_msg, 490);
		printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
		exit(1);
	}
	if(ffdebug)printf("add_or_mul entered!\n");
	print_data($2);
	while($$){
		if($$->data->type == LISP_INT || $$->data->type == LISP_SYMBOL || $$->data->type == LISP_RATIONAL || $$->data->type == LISP_CALL){
			try_calc(&result, result, (struct ast_node*)$$->data, op, true);
			$$ = (struct ast_list_node*)$$->next;
		}else{
			get_type_str($$->data, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}
	}
	return result;
}

struct ast_node* sub_or_div_number(int op, struct ast_node* $1, struct ast_node* $2){
	struct ast_node* result = NULL;
	
	if(($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL) && ($2->type == LISP_INT || $2->type == LISP_SYMBOL || $2->type == LISP_RATIONAL || $2->type == LISP_CALL)){
		try_calc(&result, $1, $2, op, true);
		return result;
	}else{
		if(!($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL)){
			get_type_str($1, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}if(!($2->type == LISP_INT || $2->type == LISP_SYMBOL || $2->type == LISP_RATIONAL)){
			get_type_str($2, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}
	}
}

struct ast_node* ast_node_digit_cmp(int op, struct ast_node* $1, struct ast_node* $2){
	struct ast_node* result = NULL;
	if(($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL) && ($2->type == LISP_INT || $2->type == LISP_SYMBOL || $2->type == LISP_RATIONAL || $2->type == LISP_CALL)){
		try_calc(&result, $1, $2, op, true);
		return result;
	}else{
		if(!($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL)){
			get_type_str($1, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}if(!($2->type == LISP_INT || $2->type == LISP_SYMBOL || $2->type == LISP_RATIONAL)){
			get_type_str($2, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}
	}
}

struct ast_node* ast_node_digit_cmpeq(struct ast_node* $1, struct ast_node* $2){
	struct ast_list_node* $$ = (struct ast_list_node*)$2;
	struct ast_node* result;
	if($1->type == LISP_INT || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL)
		result = $1;
	else{
		get_type_str($1, error_msg, 490);
		printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
		exit(1);
	}
	while($$){
		if($$->data->type == LISP_INT || $$->data->type == LISP_SYMBOL || $$->data->type == LISP_RATIONAL || $$->data->type == LISP_CALL){
			try_calc(&result, result, $$->data, '=', true);
			$$ = (struct ast_list_node*)$$->next;
		}else{
			get_type_str($$->data, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}
	}
	return result;
}

struct ast_node* ast_and_or_operation(int op, struct ast_node* $1, struct ast_node* $2){
	struct ast_list_node* $$ = (struct ast_list_node*)$2;
	struct ast_node* result;
	if($1->type == LISP_BOOL || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL){
		if(ffdebug)print_data($1);
		result = $1;
	}else{
		get_type_str($1, error_msg, 490);
		printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
		exit(1);
	}
	while($$){
		if($$->data->type == LISP_BOOL || $$->data->type == LISP_SYMBOL || $$->data->type == LISP_RATIONAL || $$->data->type == LISP_CALL){
			try_calc(&result, result, $$->data, op, true);
			$$ = (struct ast_list_node*)$$->next;
		}else{
			get_type_str($$->data, error_msg, 490);
			printf("Type Error: Expect 'number' but got '%s'.\n", error_msg);
			exit(1);
		}
	}
	
	return result;
}

struct ast_node* ast_not_operation(struct ast_node* $1){
	struct ast_node* result;
	if($1->type == LISP_BOOL || $1->type == LISP_SYMBOL || $1->type == LISP_RATIONAL || $1->type == LISP_CALL){
		try_calc(&result, $1, NONE, '!', true);
		return result;
	}
	else{
		get_type_str($1, error_msg, 490);
		printf("Type Error: Expect 'boolean' but got '%s'.\n", error_msg);
		exit(1);
	}
}

struct ast_node* new_if_else_node(struct ast_node* con, struct ast_node* if_node, struct ast_node* else_node){
	struct ast_ifelse_node *$$ = (struct ast_ifelse_node*)malloc(sizeof(struct ast_ifelse_node));
	$$->type = LISP_IFELSE;
	
	$$->left = $$->right = NULL;
	
	$$->condition = con;
	$$->if_branch = if_node;
	$$->else_branch = else_node;
	
	return (struct ast_node*)$$;
}

struct ast_node* make_symbol(char *name){
	int len = strlen(name);
	char* data = (char*)malloc((len+10)*sizeof(char));
	strcpy(data, name);
	
	struct ast_symbol_node *$$ = (struct ast_symbol_node*)malloc(sizeof(struct ast_symbol_node));
	$$->type = LISP_SYMBOL;
	
	$$->left = $$->right = NULL;
	$$->name = data;
	
	return (struct ast_node*)$$;
}

struct ast_node* make_function(struct ast_node* args, struct ast_node* exp){
	struct ast_function_node *$$ = (struct ast_function_node*)malloc(sizeof(struct ast_function_node));
	$$->type = LISP_FUNC;
	
	$$->left = $$->right = NULL;
	$$->body = exp;
	$$->params = args;
	print_data($$->params);
	int i = 0;
	while(args && args->type == LISP_LIST){
		i++;
		args = ((struct ast_list_node*)args)->next;
	}
	$$->size_of_params = i;
	
	return (struct ast_node*)$$;
}

struct ast_node* new_callback_node(struct ast_node* fun_type, struct ast_node* args){
	struct ast_callback_node *$$ = (struct ast_callback_node*)malloc(sizeof(struct ast_callback_node));
	
	$$->type = LISP_CALL;
	$$->left = $$->right = NULL;
	$$->args = args;
	$$->local_symbol_table = NULL;
	$$->func = fun_type;
	
	return (struct ast_node*)$$;
}

int main(int argc, char* argv[]){
	NONE = new_ast_none();
	symbol_table = NULL;
	ffdebug = 0;
	if(argc >= 2 && !strcmp(argv[1], "-d")) ffdebug = 1;
	
	yyparse();
	return(0);
}