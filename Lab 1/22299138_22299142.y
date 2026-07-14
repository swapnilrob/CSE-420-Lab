%{
	
#include <iostream>
#include <fstream>
#include <string>
#include "symbol_info.h"

#define YYSTYPE symbol_info*

using namespace std;

int yyparse(void);
int yylex(void);

extern FILE *yyin;
ofstream outlog;


string line_num = "1"; 

void yyerror(const char *s) {
    cout << "Error at line no: " << line_num << " " << s << endl;
}

%}

/* Token Declarations */
%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE GOTO PRINTLN
%token CONST_INT CONST_FLOAT ID 
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA COLON SEMICOLON

/* Precedence rules to resolve the dangling-else ambiguity (0 conflicts) */
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
    {
        outlog << "At line no: " << line_num << " start : program " << endl << endl;
    }
    ;

program : program unit
    {
        outlog << "At line no: " << line_num << " program : program unit " << endl << endl;
        string s = $1->getnameofsymbol() + "\n" + $2->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "program");
    }
    | unit
    {
        outlog << "At line no: " << line_num << " program : unit " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "program");
    }
    ;

unit : variable_decl
    {
        outlog << "At line no: " << line_num << " unit : variable_decl " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "unit");
    }
    | func_definition
    {
        outlog << "At line no: " << line_num << " unit : func_definition " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "unit");
    }
    ;

func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement
    {
        outlog << "At line no: " << line_num << " func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement " << endl << endl;
        string s = $1->getnameofsymbol() + " " + $2->getnameofsymbol() + "(" + $4->getnameofsymbol() + ")\n" + $6->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "func_def");
    }
    | type_specifier ID LPAREN RPAREN compound_statement
    {
        outlog << "At line no: " << line_num << " func_definition : type_specifier ID LPAREN RPAREN compound_statement " << endl << endl;
        string s = $1->getnameofsymbol() + " " + $2->getnameofsymbol() + "()\n" + $5->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "func_def");
    }
    ;

param_list : param_list COMMA type_specifier ID
    {
        outlog << "At line no: " << line_num << " param_list : param_list COMMA type_specifier ID " << endl << endl;
        string s = $1->getnameofsymbol() + "," + $3->getnameofsymbol() + " " + $4->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "param_list");
    }
    | param_list COMMA type_specifier
    {
        outlog << "At line no: " << line_num << " param_list : param_list COMMA type_specifier " << endl << endl;
        string s = $1->getnameofsymbol() + "," + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "param_list");
    }
    | type_specifier ID
    {
        outlog << "At line no: " << line_num << " param_list : type_specifier ID " << endl << endl;
        string s = $1->getnameofsymbol() + " " + $2->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "param_list");
    }
    | type_specifier
    {
        outlog << "At line no: " << line_num << " param_list : type_specifier " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "param_list");
    }
    ;

compound_statement : LCURL statements RCURL
    {
        outlog << "At line no: " << line_num << " compound_statement : LCURL statements RCURL " << endl << endl;
        string s = "{\n" + $2->getnameofsymbol() + "\n}";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "compound_statement");
    }
    | LCURL RCURL
    {
        outlog << "At line no: " << line_num << " compound_statement : LCURL RCURL " << endl << endl;
        string s = "{}";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "compound_statement");
    }
    ;

variable_decl : type_specifier declaration_list SEMICOLON
    {
        outlog << "At line no: " << line_num << " variable_decl : type_specifier declaration_list SEMICOLON " << endl << endl;
        string s = $1->getnameofsymbol() + " " + $2->getnameofsymbol() + ";";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "variable_decl");
    }
    ;

type_specifier : INT
    {
        outlog << "At line no: " << line_num << " type_specifier : INT " << endl << endl;
        string s = "int";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "type_specifier");
    }
    | FLOAT
    {
        outlog << "At line no: " << line_num << " type_specifier : FLOAT " << endl << endl;
        string s = "float";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "type_specifier");
    }
    | VOID
    {
        outlog << "At line no: " << line_num << " type_specifier : VOID " << endl << endl;
        string s = "void";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "type_specifier");
    }
    | CHAR
    {
        outlog << "At line no: " << line_num << " type_specifier : CHAR " << endl << endl;
        string s = "char";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "type_specifier");
    }
    ;

declaration_list : declaration_list COMMA ID
    {
        outlog << "At line no: " << line_num << " declaration_list : declaration_list COMMA ID " << endl << endl;
        string s = $1->getnameofsymbol() + "," + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "declaration_list");
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        outlog << "At line no: " << line_num << " declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        string s = $1->getnameofsymbol() + "," + $3->getnameofsymbol() + "[" + $5->getnameofsymbol() + "]";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "declaration_list");
    }
    | ID
    {
        outlog << "At line no: " << line_num << " declaration_list : ID " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "declaration_list");
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        outlog << "At line no: " << line_num << " declaration_list : ID LTHIRD CONST_INT RTHIRD " << endl << endl;
        string s = $1->getnameofsymbol() + "[" + $3->getnameofsymbol() + "]";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "declaration_list");
    }
    ;

statements : statement
    {
        outlog << "At line no: " << line_num << " statements : statement " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statements");
    }
    | statements statement
    {
        outlog << "At line no: " << line_num << " statements : statements statement " << endl << endl;
        string s = $1->getnameofsymbol() + "\n" + $2->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statements");
    }
    ;

statement : variable_decl
    {
        outlog << "At line no: " << line_num << " statement : variable_decl " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | expression_statement
    {
        outlog << "At line no: " << line_num << " statement : expression_statement " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | compound_statement
    {
        outlog << "At line no: " << line_num << " statement : compound_statement " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        outlog << "At line no: " << line_num << " statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement " << endl << endl;
        string s = "for(" + $3->getnameofsymbol() + $4->getnameofsymbol() + $5->getnameofsymbol() + ")\n" + $7->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
    {
        outlog << "At line no: " << line_num << " statement : IF LPAREN expression RPAREN statement " << endl << endl;
        string s = "if(" + $3->getnameofsymbol() + ")\n" + $5->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        outlog << "At line no: " << line_num << " statement : IF LPAREN expression RPAREN statement ELSE statement " << endl << endl;
        string s = "if(" + $3->getnameofsymbol() + ")\n" + $5->getnameofsymbol() + "\nelse\n" + $7->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | WHILE LPAREN expression RPAREN statement
    {
        outlog << "At line no: " << line_num << " statement : WHILE LPAREN expression RPAREN statement " << endl << endl;
        string s = "while(" + $3->getnameofsymbol() + ")\n" + $5->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | PRINTLN LPAREN ID RPAREN SEMICOLON
    {
        outlog << "At line no: " << line_num << " statement : PRINTLN LPAREN ID RPAREN SEMICOLON " << endl << endl;
        string s = "printf(" + $3->getnameofsymbol() + ");";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    | RETURN expression SEMICOLON
    {
        outlog << "At line no: " << line_num << " statement : RETURN expression SEMICOLON " << endl << endl;
        string s = "return " + $2->getnameofsymbol() + ";";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "statement");
    }
    ;

expression_statement : SEMICOLON
    {
        outlog << "At line no: " << line_num << " expression_statement : SEMICOLON " << endl << endl;
        string s = ";";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "expression_statement");
    }
    | expression SEMICOLON
    {
        outlog << "At line no: " << line_num << " expression_statement : expression SEMICOLON " << endl << endl;
        string s = $1->getnameofsymbol() + ";";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "expression_statement");
    }
    ;

variable : ID
    {
        outlog << "At line no: " << line_num << " variable : ID " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "variable");
    }
    | ID LTHIRD expression RTHIRD
    {
        outlog << "At line no: " << line_num << " variable : ID LTHIRD expression RTHIRD " << endl << endl;
        string s = $1->getnameofsymbol() + "[" + $3->getnameofsymbol() + "]";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "variable");
    }
    ;

expression : logic_expression
    {
        outlog << "At line no: " << line_num << " expression : logic_expression " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "expression");
    }
    | variable ASSIGNOP logic_expression
    {
        outlog << "At line no: " << line_num << " expression : variable ASSIGNOP logic_expression " << endl << endl;
        string s = $1->getnameofsymbol() + "=" + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "expression");
    }
    ;

logic_expression : rel_expression
    {
        outlog << "At line no: " << line_num << " logic_expression : rel_expression " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "logic_expression");
    }
    | rel_expression LOGICOP rel_expression
    {
        outlog << "At line no: " << line_num << " logic_expression : rel_expression LOGICOP rel_expression " << endl << endl;
        string s = $1->getnameofsymbol() + $2->getnameofsymbol() + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "logic_expression");
    }
    ;

rel_expression : simple_expression
    {
        outlog << "At line no: " << line_num << " rel_expression : simple_expression " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "rel_expression");
    }
    | simple_expression RELOP simple_expression
    {
        outlog << "At line no: " << line_num << " rel_expression : simple_expression RELOP simple_expression " << endl << endl;
        string s = $1->getnameofsymbol() + $2->getnameofsymbol() + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "rel_expression");
    }
    ;

simple_expression : term
    {
        outlog << "At line no: " << line_num << " simple_expression : term " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "simple_expression");
    }
    | simple_expression ADDOP term
    {
        outlog << "At line no: " << line_num << " simple_expression : simple_expression ADDOP term " << endl << endl;
        string s = $1->getnameofsymbol() + $2->getnameofsymbol() + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "simple_expression");
    }
    ;

term : unary_expression
    {
        outlog << "At line no: " << line_num << " term : unary_expression " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "term");
    }
    | term MULOP unary_expression
    {
        outlog << "At line no: " << line_num << " term : term MULOP unary_expression " << endl << endl;
        string s = $1->getnameofsymbol() + $2->getnameofsymbol() + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "term");
    }
    ;

unary_expression : ADDOP unary_expression
    {
        outlog << "At line no: " << line_num << " unary_expression : ADDOP unary_expression " << endl << endl;
        string s = $1->getnameofsymbol() + $2->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "unary_expression");
    }
    | NOT unary_expression
    {
        outlog << "At line no: " << line_num << " unary_expression : NOT unary_expression " << endl << endl;
        string s = "!" + $2->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "unary_expression");
    }
    | factor_info
    {
        outlog << "At line no: " << line_num << " unary_expression : factor_info " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "unary_expression");
    }
    ;

factor_info : factor
    {
        outlog << "At line no: " << line_num << " factor_info : factor " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor_info");
    }
    ;

factor : variable
    {
        outlog << "At line no: " << line_num << " factor : variable " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | ID LPAREN argument_list RPAREN
    {
        outlog << "At line no: " << line_num << " factor : ID LPAREN argument_list RPAREN " << endl << endl;
        string s = $1->getnameofsymbol() + "(" + $3->getnameofsymbol() + ")";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | LPAREN expression RPAREN
    {
        outlog << "At line no: " << line_num << " factor : LPAREN expression RPAREN " << endl << endl;
        string s = "(" + $2->getnameofsymbol() + ")";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | CONST_INT
    {
        outlog << "At line no: " << line_num << " factor : CONST_INT " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | CONST_FLOAT
    {
        outlog << "At line no: " << line_num << " factor : CONST_FLOAT " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | variable INCOP
    {
        outlog << "At line no: " << line_num << " factor : variable INCOP " << endl << endl;
        string s = $1->getnameofsymbol() + "++";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    | variable DECOP
    {
        outlog << "At line no: " << line_num << " factor : variable DECOP " << endl << endl;
        string s = $1->getnameofsymbol() + "--";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "factor");
    }
    ;

argument_list : arguments
    {
        outlog << "At line no: " << line_num << " argument_list : arguments " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "argument_list");
    }
    | 
    {
        outlog << "At line no: " << line_num << " argument_list : " << endl << endl;
        string s = "";
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "argument_list");
    }
    ;

arguments : arguments COMMA logic_expression
    {
        outlog << "At line no: " << line_num << " arguments : arguments COMMA logic_expression " << endl << endl;
        string s = $1->getnameofsymbol() + "," + $3->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "arguments");
    }
    | logic_expression
    {
        outlog << "At line no: " << line_num << " arguments : logic_expression " << endl << endl;
        string s = $1->getnameofsymbol();
        outlog << s << endl << endl;
        $$ = new symbol_info(s, "arguments");
    }
    ;

%%

int main(int argc, char *argv[])
{
    if (argc != 2) {
        cout << "Provide  the input file name." << endl;
        return 1;
    }
    
    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        cout << "Couldn't open file: " << argv[1] << endl;
        return 1;
    }

    outlog.open("my_log.txt", ios::trunc);
    
    yyparse();
    
    outlog << "Total lines: " << line_num << endl;
    
    outlog.close();
	
    fclose(yyin);
    
    return 0;
}