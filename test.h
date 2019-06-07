#include <stdio.h>
#include <stdlib.h>

int ffdebug;
typedef enum{LISP_INT, LISP_BOOL, LISP_FUNC, LISP_IFELSE, LISP_NONE, LISP_RATIONAL, LISP_LIST, LISP_SYMBOL, LISP_CALL, EXCEPTION} LispType;
struct ast_node* NONE;
struct symbol_map* symbol_table;

struct ast_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
};

struct ast_int_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	int value;
};

struct ast_rational_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	int op;
};

struct ast_symbol_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	char *name;
};

struct ast_bool_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	int boolvalue;
};

struct ast_exception_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
};

struct ast_list_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	struct ast_node* data;
	struct ast_node* next;
};

struct ast_ifelse_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	struct ast_node* condition;
	struct ast_node* if_branch;
	struct ast_node* else_branch;
};

struct symbol_map{
	char* name;
	struct ast_node* data;
	struct symbol_map* next;
};

struct ast_function_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	struct ast_node* params;
	int size_of_params;
	struct ast_node* body;
};

struct ast_callback_node{
	LispType type;
	struct ast_node* left;
	struct ast_node* right;
	
	struct ast_node* args;
	struct symbol_map* local_symbol_table;
	struct ast_node* func;
	
};

void print_data(struct ast_node* r1);

void add_global_symbol_data(char* name, struct ast_node* $1);
void add_local_symbol_data(char* name, struct ast_node* $1, struct symbol_map** local, struct symbol_map* s);
struct ast_node* eval(struct ast_node* root, struct symbol_map* local);
struct ast_node* find(struct ast_node* $1, struct symbol_map* s);
void append(struct ast_node* names, struct ast_node* arggs, struct symbol_map** local, struct symbol_map* s);
void rremove(struct symbol_map** local);

struct ast_node* new_ast_none();
struct ast_node* new_ast_int_node(int value);
struct ast_node* new_ast_bool_node(int boolvalue);
struct ast_node* new_ast_rational_node(int op, struct ast_node* $1, struct ast_node* $2);
struct ast_node* print_int(struct ast_node* $1);
struct ast_node* print_bool(struct ast_node* $1);
struct ast_node* new_ast_list_node(struct ast_node* $1);
struct ast_node* append_ast_list_node(struct ast_node* $1, struct ast_node* $2);
struct ast_node* add_or_mul_number(int op, struct ast_node* $1, struct ast_node* $2);
struct ast_node* sub_or_div_number(int op, struct ast_node* $1, struct ast_node* $2);
struct ast_node* ast_node_digit_cmp(int op, struct ast_node* $1, struct ast_node* $2);
struct ast_node* ast_node_digit_cmpeq(struct ast_node* $1, struct ast_node* $2);
struct ast_node* ast_and_or_operation(int op, struct ast_node* $1, struct ast_node* $2);
struct ast_node* ast_not_operation(struct ast_node* $1);
struct ast_node* new_if_else_node(struct ast_node* con, struct ast_node* if_node, struct ast_node* else_node);
struct ast_node* make_symbol(char *name);
struct ast_node* new_ast_exception(const char* msg);
struct ast_node* make_function(struct ast_node* args, struct ast_node* exp);
struct ast_node* new_callback_node(struct ast_node* ids, struct ast_node* args);