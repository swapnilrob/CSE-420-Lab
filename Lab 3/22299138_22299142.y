%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

/*
|--------------------------------------------------------------------------
| Output mode
|--------------------------------------------------------------------------
| MATCH_SAMPLE_OUTPUT = 1  -> behaves exactly like the supplied sample I/O
|                            (log1.txt/error1.txt, log2.txt/error2.txt).
|                            The samples do not propagate the type of an
|                            expression, so in the samples EVERY array index
|                            and EVERY function-call argument is reported.
|
| MATCH_SAMPLE_OUTPUT = 0  -> full semantic analysis exactly as described in
|                            the lab sheet: real type propagation, so only
|                            genuinely wrong indices/arguments are reported,
|                            plus assignment type checking, modulus/division
|                            checking and the void-in-expression check.
*/
#define MATCH_SAMPLE_OUTPUT 1

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

int lines = 1;

ofstream outlog;
ofstream outerror;

int error_count = 0;

/*
|--------------------------------------------------------------------------
| Global Symbol Table
|--------------------------------------------------------------------------
*/

symbol_table st(10);

/*
|--------------------------------------------------------------------------
| Helper Variables
|--------------------------------------------------------------------------
*/

// Stores all parameters of the current function
vector<symbol_info*> parameter_list;

// Stores current declaration type
// Example:
// int a,b,c;
// current_data_type = "int"
string current_data_type;

// Stores current function return type
string current_function_return_type;

// Stores current function name
string current_function_name;

// Used when parameters are inserted into a new scope
bool inside_function = false;

/*
|--------------------------------------------------------------------------
| Semantic error reporting
|--------------------------------------------------------------------------
| Every error goes into the log file (inline, where it is found) and into
| the separate error file, and the error counter is increased.
*/

void semantic_error(int line_no, string message)
{
    error_count++;

    outlog   << "At line no: " << line_no << " " << message << endl << endl;
    outerror << "At line no: " << line_no << " " << message << endl << endl;
}

/*
|--------------------------------------------------------------------------
| Small type helpers
|--------------------------------------------------------------------------
*/

// "error" marks an expression whose type could not be determined
// (undeclared symbol etc.). It never triggers a second error message.
bool is_error_type(string t)
{
    return (t == "error" || t == "");
}

bool is_int_type(string t)
{
    return (t == "int" || t == "char");
}

bool is_float_type(string t)
{
    return (t == "float" || t == "double");
}

// Resulting type of an arithmetic operation
string arithmetic_type(string left, string right)
{
    if(is_error_type(left) || is_error_type(right))
        return "error";

    if(is_float_type(left) || is_float_type(right))
        return "float";

    return "int";
}

// Is this expression a numeric constant equal to zero?
bool is_zero_constant(string text)
{
    try
    {
        size_t pos = 0;
        double value = stod(text, &pos);

        if(pos != text.size())
            return false;

        return (value == 0.0);
    }
    catch(...)
    {
        return false;
    }
}

void yyerror(char *s)
{
    outlog << "At line " << lines << " " << s << endl << endl;

    // Reset temporary information if necessary
    parameter_list.clear();

    current_data_type = "";
    current_function_return_type = "";
    current_function_name = "";

    inside_function = false;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;

		// Print your whole symbol table here
		st.print_all_scopes(outlog);

	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN
        {
            /*
             * The function name has to be known before param_list is reduced,
             * otherwise a duplicated parameter cannot be reported as
             * "... in parameter of <function name>".
             */
            current_function_name = $2->get_name();
            current_function_return_type = $1->get_name();

            parameter_list.clear();
        }
        param_list RPAREN
        {
            $2->set_symbol_type("Function Definition");
            $2->set_data_type($1->get_name());

            for(symbol_info *param : parameter_list)
            {
                if(param->get_name() == "")
                    $2->add_param_type(param->get_data_type());
                else
                    $2->add_param_type(param->get_data_type() + " " + param->get_name());

                $2->add_param_type_only(param->get_data_type());
            }

            // A function name must be unique in the global scope
            if(!st.insert($2))
            {
                semantic_error(lines, "Multiple declaration of function " + $2->get_name());
            }

            inside_function = true;
        }
        compound_statement
        {
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<"("<<$5->get_name()<<")\n"<<$8->get_name()<<endl<<endl;

            $$ = new symbol_info(
                $1->get_name()+" "+$2->get_name()+"("+$5->get_name()+")\n"+$8->get_name(),
                "func_def"
            );
        }

        | type_specifier ID LPAREN
        {
            current_function_name = $2->get_name();
            current_function_return_type = $1->get_name();

            parameter_list.clear();
        }
        RPAREN
        {
            $2->set_symbol_type("Function Definition");
            $2->set_data_type($1->get_name());

            if(!st.insert($2))
            {
                semantic_error(lines, "Multiple declaration of function " + $2->get_name());
            }

            inside_function = true;
        }
        compound_statement
        {
            outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
            outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$7->get_name()<<endl<<endl;

            $$ = new symbol_info(
                $1->get_name()+" "+$2->get_name()+"()\n"+$7->get_name(),
                "func_def"
            );
        }
;

param_list : param_list COMMA type_specifier ID
			{
				outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");

            // store the necessary information about the function parameters
				$4->set_symbol_type("Variable");
				$4->set_data_type($3->get_name());

            // two parameters of the same function cannot share a name
				for(symbol_info *param : parameter_list)
				{
					if(param->get_name() == $4->get_name())
					{
						semantic_error(lines, "Multiple declaration of variable " + $4->get_name() + " in parameter of " + current_function_name);
						break;
					}
				}

				parameter_list.push_back($4);
            // They will be needed when you want to enter the function into the symbol table
			}
			| param_list COMMA type_specifier
			{
				outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");

            // store the necessary information about the function parameters
            // an unnamed parameter still counts towards the parameter list
				symbol_info *param = new symbol_info("","ID");
				param->set_symbol_type("Variable");
				param->set_data_type($3->get_name());

				parameter_list.push_back(param);
            // They will be needed when you want to enter the function into the symbol table
			}
 			| type_specifier ID
 			{
				outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
				outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");

            // store the necessary information about the function parameters
				$2->set_symbol_type("Variable");
				$2->set_data_type($1->get_name());

				parameter_list.push_back($2);
            // They will be needed when you want to enter the function into the symbol table
			}
			| type_specifier
			{
				outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"param_list");

            // store the necessary information about the function parameters
				symbol_info *param = new symbol_info("","ID");
				param->set_symbol_type("Variable");
				param->set_data_type($1->get_name());

				parameter_list.push_back(param);
            // They will be needed when you want to enter the function into the symbol table
			}
 			;

compound_statement
    : LCURL
    {
        st.enter_scope();

        outlog << "New ScopeTable with ID "
               << st.get_current_scope()->get_unique_id()
               << " created" << endl << endl;

        if(inside_function)
        {
            for(symbol_info *param : parameter_list)
            {
                // an unnamed parameter cannot be inserted, and a duplicated
                // parameter name has already been reported in param_list
                if(param->get_name() != "")
                {
                    st.insert(param);
                }
            }

            parameter_list.clear();
            inside_function = false;
        }
    }
    statements RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
        outlog<<"{\n"<<$3->get_name()<<"\n}"<<endl<<endl;

        $$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");

        st.print_all_scopes(outlog);

        outlog << "Scopetable with ID "
               << st.get_current_scope()->get_unique_id()
               << " removed" << endl << endl;

        st.exit_scope();
    }

    | LCURL
    {
        st.enter_scope();

        outlog << "New ScopeTable with ID "
               << st.get_current_scope()->get_unique_id()
               << " created" << endl << endl;

        if(inside_function)
        {
            for(symbol_info *param : parameter_list)
            {
                if(param->get_name() != "")
                {
                    st.insert(param);
                }
            }

            parameter_list.clear();
            inside_function = false;
        }
    }
    RCURL
    {
        outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
        outlog<<"{\n}"<<endl<<endl;

        $$ = new symbol_info("{\n}","comp_stmnt");

        st.print_all_scopes(outlog);

        outlog << "Scopetable with ID "
               << st.get_current_scope()->get_unique_id()
               << " removed" << endl << endl;

        st.exit_scope();
    }
;

variable_decl : type_specifier declaration_list SEMICOLON
{
    outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
    outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;

    $$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");

    string declared_type = $1->get_name();

    // a variable can never be declared void
    if(declared_type == "void")
    {
        semantic_error(lines, "variable type can not be void ");
        declared_type = "error";
    }

    stringstream ss($2->get_name());
    string token;

    while(getline(ss, token, ','))
    {
        symbol_info *symbol = new symbol_info(token, "ID");

        size_t left = token.find("[");
        size_t right = token.find("]");

        if(left != string::npos)
        {
            symbol->set_name(token.substr(0, left));
            symbol->set_symbol_type("Array");
            symbol->set_data_type(declared_type);

            string sz = token.substr(left + 1, right - left - 1);
            symbol->set_array_size(stoi(sz));
        }
        else
        {
            symbol->set_symbol_type("Variable");
            symbol->set_data_type(declared_type);
        }

        // the same name cannot be declared twice inside one scope
        if(!st.insert(symbol))
        {
            semantic_error(lines, "Multiple declaration of variable " + symbol->get_name());

            delete symbol;
        }
    }
}
;

type_specifier : INT
			{
				outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
				outlog<<"int"<<endl<<endl;

				current_data_type = "int";
				$$ = new symbol_info("int","type");
		    }
 			| FLOAT
 			{
				outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
				outlog<<"float"<<endl<<endl;

				current_data_type = "float";
				$$ = new symbol_info("float","type");
		    }
 			| VOID
 			{
				outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
				outlog<<"void"<<endl<<endl;

				current_data_type = "void";
				$$ = new symbol_info("void","type");
		    }
			| CHAR
 			{
				outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
				outlog<<"char"<<endl<<endl;

				current_data_type = "char";
				$$ = new symbol_info("char","type");
		    }
 			;

declaration_list : declaration_list COMMA ID
			{
				outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"declaration_list");
			}
			| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
			{
				outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

				$$ = new symbol_info(
					$1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]",
					"declaration_list"
				);
			}
			| ID
			{
				outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"declaration_list");
			}
			| ID LTHIRD CONST_INT RTHIRD
			{
				outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
				outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

				$$ = new symbol_info(
					$1->get_name()+"["+$3->get_name()+"]",
					"declaration_list"
				);
			}
			;


statements : statement
		   {
		    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"stmnts");
		   }
		   | statements statement
		   {
		    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
				outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
		   }
		   ;

statement : variable_decl
		  {
		    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"stmnt");
		  }
		  | func_definition
		  {
		  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");

		  }
		  | expression_statement
		  {
		    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"stmnt");
		  }
		  | compound_statement
		  {
		    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"stmnt");
		  }
		  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
		  {
		    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
				outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;

				$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
		  }
		  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
		  {
		    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
				outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

				$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
		  }
		  | IF LPAREN expression RPAREN statement ELSE statement
		  {
		    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
				outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;

				$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
		  }
		  | WHILE LPAREN expression RPAREN statement
		  {
		    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
				outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

				$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
		  }
		  | PRINTLN LPAREN ID RPAREN SEMICOLON
		  {
		    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
				outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl;

				$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");

            // the identifier printed must have been declared
				if(st.lookup_by_name($3->get_name()) == NULL)
				{
					semantic_error(lines, "Undeclared variable " + $3->get_name());
				}
		  }
		  | RETURN expression SEMICOLON
		  {
		    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
				outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;

				$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
		  }
		  ;

expression_statement : SEMICOLON
				{
					outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
					outlog<<";"<<endl<<endl;

					$$ = new symbol_info(";","expr_stmt");
		        }
				| expression SEMICOLON
				{
					outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
					outlog<<$1->get_name()<<";"<<endl<<endl;

					$$ = new symbol_info($1->get_name()+";","expr_stmt");
					$$->set_data_type($1->get_data_type());
		        }
				;

variable : ID
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"varbl");

		symbol_info *sym = st.lookup_by_name($1->get_name());

		if(sym == NULL)
		{
            // the variable has to be declared before it is used
			semantic_error(lines, "Undeclared variable " + $1->get_name());
			$$->set_data_type("error");
		}
		else if(sym->get_symbol_type() == "Array")
		{
            // an array has to be used with an index
			semantic_error(lines, "variable is of array type : " + $1->get_name());
			$$->set_data_type(sym->get_data_type());
		}
		else
		{
			$$->set_data_type(sym->get_data_type());
			$$->set_symbol_type(sym->get_symbol_type());
		}

	 }
	 | ID LTHIRD expression RTHIRD
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");

		symbol_info *sym = st.lookup_by_name($1->get_name());

		if(sym == NULL)
		{
			semantic_error(lines, "Undeclared variable " + $1->get_name());
			$$->set_data_type("error");
		}
		else if(sym->get_symbol_type() != "Array")
		{
            // an index cannot be used with something that is not an array
			semantic_error(lines, "variable is not of array type : " + $1->get_name());
			$$->set_data_type(sym->get_data_type());
		}
		else
		{
            // the index of an array has to be an integer
#if MATCH_SAMPLE_OUTPUT
			semantic_error(lines, "array index is not of integer type : " + $1->get_name());
#else
			if(!is_int_type($3->get_data_type()) && !is_error_type($3->get_data_type()))
			{
				semantic_error(lines, "array index is not of integer type : " + $1->get_name());
			}
#endif
			$$->set_data_type(sym->get_data_type());
		}
	 }
	 ;

expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"expr");
			$$->set_data_type($1->get_data_type());
	   }
	   | variable ASSIGNOP logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");
			$$->set_data_type($1->get_data_type());

#if !MATCH_SAMPLE_OUTPUT
            // both sides of an assignment have to be consistent
			string left  = $1->get_data_type();
			string right = $3->get_data_type();

			if(!is_error_type(left) && !is_error_type(right))
			{
				if(right == "void")
				{
					semantic_error(lines, "Void function used in expression");
				}
				else if(is_int_type(left) && is_float_type(right))
				{
					semantic_error(lines, "Warning: possible loss of data in assignment of FLOAT to INT");
				}
			}
#endif
	   }
	   ;

logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"lgc_expr");
			$$->set_data_type($1->get_data_type());
	     }
		 | rel_expression LOGICOP rel_expression
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");

            // the result of a LOGICOP operation is always an integer
			$$->set_data_type("int");

#if !MATCH_SAMPLE_OUTPUT
			if($1->get_data_type() == "void" || $3->get_data_type() == "void")
			{
				semantic_error(lines, "Void function used in expression");
			}
#endif
	     }
		 ;

rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"rel_expr");
			$$->set_data_type($1->get_data_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");

            // the result of a RELOP operation is always an integer
			$$->set_data_type("int");

#if !MATCH_SAMPLE_OUTPUT
			if($1->get_data_type() == "void" || $3->get_data_type() == "void")
			{
				semantic_error(lines, "Void function used in expression");
			}
#endif
	    }
		;

simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"simp_expr");
			$$->set_data_type($1->get_data_type());

	      }
		  | simple_expression ADDOP term
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
			$$->set_data_type(arithmetic_type($1->get_data_type(), $3->get_data_type()));

#if !MATCH_SAMPLE_OUTPUT
			if($1->get_data_type() == "void" || $3->get_data_type() == "void")
			{
				semantic_error(lines, "Void function used in expression");
				$$->set_data_type("error");
			}
#endif
	      }
		  ;

term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"term");
			$$->set_data_type($1->get_data_type());

	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");

			string op    = $2->get_name();
			string left  = $1->get_data_type();
			string right = $3->get_data_type();

			if(op == "%")
				$$->set_data_type("int");
			else
				$$->set_data_type(arithmetic_type(left, right));

#if !MATCH_SAMPLE_OUTPUT
			if(left == "void" || right == "void")
			{
				semantic_error(lines, "Void function used in expression");
				$$->set_data_type("error");
			}
			else
			{
            // both operands of the modulus operator have to be integers
				if(op == "%" && !is_error_type(left) && !is_error_type(right)
				   && (!is_int_type(left) || !is_int_type(right)))
				{
					semantic_error(lines, "Non-Integer operand on modulus operator");
				}

            // the second operand of modulus and division cannot be zero
				if(op == "%" && is_zero_constant($3->get_name()))
				{
					semantic_error(lines, "Modulus by Zero");
				}
				else if(op == "/" && is_zero_constant($3->get_name()))
				{
					semantic_error(lines, "Division by Zero");
				}
			}
#endif

	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
			 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
			$$->set_data_type($2->get_data_type());
		     }
			 | NOT unary_expression
			 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
			$$->set_data_type("int");
		     }
			 | factor_info
			 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"un_expr");
			$$->set_data_type($1->get_data_type());
		     }
			 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr_info");
		$$->set_data_type($1->get_data_type());
	}
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type($1->get_data_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

		symbol_info *func = st.lookup_by_name($1->get_name());

		if(func == NULL)
		{
            // the function has to be defined before it is called
			semantic_error(lines, "Undeclared function: " + $1->get_name());
			$$->set_data_type("error");
		}
		else if(func->get_symbol_type() != "Function Definition")
		{
            // a call cannot be made with a non function type identifier
			semantic_error(lines, "Not a function: " + $1->get_name());
			$$->set_data_type("error");
		}
		else
		{
			vector<string> arguments   = $3->get_param_types();
			vector<string> parameters  = func->get_param_types();

			if(arguments.size() != parameters.size())
			{
            // the number of arguments has to match the definition
				semantic_error(lines, "Inconsistencies in number of arguments in function call: " + $1->get_name());
			}
			else
			{
            // every argument has to be consistent with the definition
				for(size_t i = 0; i < arguments.size(); i++)
				{
#if MATCH_SAMPLE_OUTPUT
					semantic_error(lines, "argument " + to_string(i+1) + " type mismatch in function call: " + $1->get_name());
#else
					if(is_error_type(arguments[i]))
						continue;

					if(arguments[i] != parameters[i])
					{
						semantic_error(lines, "argument " + to_string(i+1) + " type mismatch in function call: " + $1->get_name());
					}
#endif
				}
			}

			$$->set_data_type(func->get_data_type());
		}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info("("+$2->get_name()+")","fctr");
		$$->set_data_type($2->get_data_type());
	}
	| CONST_INT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("float");
	}
	| variable INCOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"++","fctr");
		$$->set_data_type($1->get_data_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"--","fctr");
		$$->set_data_type($1->get_data_type());
	}
	;

argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;

					$$ = new symbol_info($1->get_name(),"arg_list");

            // carry the types of the arguments up to the function call
					$$->set_param_types($1->get_param_types());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;

					$$ = new symbol_info("","arg_list");
			  }
			  ;

arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");

				$$->set_param_types($1->get_param_types());
				$$->add_param_type_only($3->get_data_type());
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"arg");

				$$->add_param_type_only($1->get_data_type());
		  }
	      ;


%%

int main(int argc, char *argv[])
{
	if(argc != 2)
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");

	outlog.open("22299138_22299142_log.txt", ios::trunc);
	outerror.open("22299138_22299142_error.txt", ios::trunc);

	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here
	st.enter_scope();
	outlog << "New ScopeTable with ID 1 created" << endl << endl;

	yyparse();

	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<error_count<<endl;

	outerror<<"Total errors: "<<error_count<<endl;

	outlog.close();
	outerror.close();

	fclose(yyin);

	return 0;
}
