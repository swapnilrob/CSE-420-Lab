%option noyywrap

%{
#include<bits/stdc++.h>

#include"symbol_info.h"

#define YYSTYPE symbol_info*

#include "y.tab.h"

extern YYSTYPE yylval;

using namespace std;

void yyerror(char *);

string loglist;

extern string line_num; 

extern ofstream outlog;

int line_count = 1;     
%}

/* Regular Definitions */

delim    [ \t\v\r]

/* write regular expressions for whitespace   and newline */
ws      {delim}+  

newline  \n

letter_  [A-Za-z_]
digit    [0-9]

/* Regular expressions for id, float and integers */
id       {letter_}({letter_}|{digit})*
integer  {digit}+
float    ({digit}*\.{digit}+([eE][+-]?{digit}+)?)|({digit}+[eE][+-]?{digit}+)

%%    /* action starts */

{ws}        { /* ignore ws */ }
{newline}   { line_count++; line_num = to_string(line_count); }


"if"        { 
                loglist="Line no"+to_string(line_count)+": Token <IF> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return IF; 
}
"else"      {
                 loglist="Line no"+to_string(line_count)+": Token <ELSE> Lexeme "+yytext+" found\n\n";
                 outlog<<loglist; 
                 return ELSE; 
}
"for"       { 
                loglist="Line no"+to_string(line_count)+": Token <FOR> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return FOR; 
}
"do"        {   loglist="Line no"+to_string(line_count)+": Token <DO> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return DO; 
}
"int"       { 
                loglist="Line no"+to_string(line_count)+": Token <INT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return INT; 
}
"float"     { 
                loglist="Line no"+to_string(line_count)+": Token <FLOAT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return FLOAT; 
}
"continue"  { 
                loglist="Line no"+to_string(line_count)+": Token <CONTINUE> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return CONTINUE; 
}
"while"     {   
                loglist="Line no"+to_string(line_count)+": Token <WHILE> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return WHILE; 
}
"break"     { 
                loglist="Line no"+to_string(line_count)+": Token <BREAK> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return BREAK; 
}
"char"      { 
                loglist="Line no"+to_string(line_count)+": Token <CHAR> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return CHAR; 
}
"double"    { 
                loglist="Line no"+to_string(line_count)+": Token <DOUBLE> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return DOUBLE; 
}
"case"      { 
                loglist="Line no"+to_string(line_count)+": Token <CASE> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return CASE; 
}
"void"      { 
                loglist="Line no"+to_string(line_count)+": Token <VOID> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return VOID; 
}
"switch"    { 
                loglist="Line no"+to_string(line_count)+": Token <SWITCH> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return SWITCH;
}
"default"   { 
                loglist="Line no"+to_string(line_count)+": Token <DEFAULT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return DEFAULT; 
}
"goto"      { 
                loglist="Line no"+to_string(line_count)+": Token <GOTO> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return GOTO; 
}
"return"    { 
                loglist="Line no"+to_string(line_count)+": Token <RETURN> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return RETURN; 
}
"printf"    { 
                loglist="Line no"+to_string(line_count)+": Token <PRINTLN> Lexeme "+yytext+" found\n\n";
                outlog<<loglist; 
                return PRINTLN; 
}

 /* Literals */
{integer}   {
                symbol_info *s = new symbol_info((string)yytext, "CONST_INT");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <CONST_INT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return CONST_INT;
            }

{float}     {
                symbol_info *s = new symbol_info((string)yytext, "CONST_FLOAT");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <CONST_FLOAT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return CONST_FLOAT;
            }

 /* Identifiers (Must be placed after keywords) */
{id}        {
                symbol_info *s = new symbol_info((string)yytext, "ID");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <ID> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return ID;
            }

 /* Operators & Punctuators */
"+"|"-"     {
                symbol_info *s = new symbol_info((string)yytext, "ADDOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <ADDOP> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return ADDOP;
            }

"*"|"/"|"%" {
                symbol_info *s = new symbol_info((string)yytext, "MULOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <MULOP> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return MULOP;
            }

"++"        { loglist="Line no "+to_string(line_count)+": Token <INCOP> Lexeme "+yytext+" found\n\n"; outlog<<loglist; return INCOP; }
"--"        { loglist="Line no "+to_string(line_count)+": Token <DECOP> Lexeme "+yytext+" found\n\n"; outlog<<loglist; return DECOP; }

"<"|">"|"<="|">="|"=="|"!=" {
                symbol_info *s = new symbol_info((string)yytext, "RELOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <RELOP> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return RELOP;
            }

"="         { loglist="Line no "+to_string(line_count)+": Token <ASSIGNOP> Lexeme "+yytext+" found\n\n"; outlog<<loglist; return ASSIGNOP; }

"&&"|"||"   {
                symbol_info *s = new symbol_info((string)yytext, "LOGICOP");
                yylval = (YYSTYPE)s;
                loglist="Line no "+to_string(line_count)+": Token <LOGICOP> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return LOGICOP;
            }

"!"         { 
                loglist="Line no "+to_string(line_count)+": Token <NOT> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return NOT; 
}

"("         { 
                loglist="Line no "+to_string(line_count)+": Token <LPAREN> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return LPAREN; 
}
")"         { 
                loglist="Line no "+to_string(line_count)+": Token <RPAREN> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return RPAREN; 
}
"{"         { 
                loglist="Line no "+to_string(line_count)+": Token <LCURL> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return LCURL; 
}
"}"         { 
                loglist="Line no "+to_string(line_count)+": Token <RCURL> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return RCURL; 
}
"["         { 
                loglist="Line no "+to_string(line_count)+": Token <LTHIRD> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return LTHIRD; 
}
"]"         { 
                loglist="Line no "+to_string(line_count)+": Token <RTHIRD> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return RTHIRD; 
}
","         { 
                loglist="Line no "+to_string(line_count)+": Token <COMMA> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return COMMA; 
}
":"         { 
                loglist="Line no "+to_string(line_count)+": Token <COLON> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return COLON; 
}
";"         { 
                loglist="Line no "+to_string(line_count)+": Token <SEMICOLON> Lexeme "+yytext+" found\n\n";
                outlog<<loglist;
                return SEMICOLON; 
}

 /* Catch-all */
.           { /* ignore any other unassigned characters to prevent flex defaults from triggering */ }

%%