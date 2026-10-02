#ifndef AST_H
#define AST_H

#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <map>

using namespace std;

class ASTNode {
public:
    virtual ~ASTNode() {}
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp, int& temp_count, int& label_count) const = 0;
};

// Expression node types

class ExprNode : public ASTNode {
protected:
    string node_type; // Type information (int, float, void, etc.)
public:
    ExprNode(string type) : node_type(type) {}
    virtual string get_type() const { return node_type; }
};

// Forward declaration
class ConstNode;

// Variable node (for ID references)

class VarNode : public ExprNode {
private:
    string name;
    ExprNode* index; // For array access, nullptr for simple variables

public:
    VarNode(string name, string type, ExprNode* idx = nullptr)
        : ExprNode(type), name(name), index(idx) {}
    
    ~VarNode() { if(index) delete index; }
    
    bool has_index() const { return index != nullptr; }
    
    string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                              int& temp_count, int& label_count) const {
        if (index) {
            return index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (has_index()) {
            // Array access: generate index, then load element
            string idx = index->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            string t = "t" + to_string(temp_count++);
            outcode << t << " = " << name << "[" << idx << "]" << "\n";
            return t;
        } else {
            // Scalar variable read
            // Always allocate a new temp number
            string t = "t" + to_string(temp_count++);
            // Check cache
            if (symbol_to_temp.find(name) != symbol_to_temp.end()) {
                // Cached - return cached temp (the new t is wasted/gap)
                return symbol_to_temp[name];
            }
            // Not cached - emit load and cache it
            outcode << t << " = " << name << "\n";
            symbol_to_temp[name] = t;
            return t;
        }
    }
    
    string get_name() const { return name; }
};

// Constant node

class ConstNode : public ExprNode {
private:
    string value;

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << value << "\n";
        return t;
    }
};

// Binary operation node

class BinaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* left;
    ExprNode* right;

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    ~BinaryOpNode() {
        delete left;
        delete right;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string l = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string r = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << l << " " << op << " " << r << "\n";
        return t;
    }
};

// Unary operation node

class UnaryOpNode : public ExprNode {
private:
    string op;
    ExprNode* expr;

public:
    UnaryOpNode(string op, ExprNode* expr, string result_type)
        : ExprNode(result_type), op(op), expr(expr) {}
    
    ~UnaryOpNode() { delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string e = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (op == "+") return e;
        string t = "t" + to_string(temp_count++);
        outcode << t << " = " << op << " " << e << "\n";
        return t;
    }
};

// Assignment node

class AssignNode : public ExprNode {
private:
    VarNode* lhs;
    ExprNode* rhs;

public:
    AssignNode(VarNode* lhs, ExprNode* rhs, string result_type)
        : ExprNode(result_type), lhs(lhs), rhs(rhs) {}
    
    ~AssignNode() {
        delete lhs;
        delete rhs;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string rt = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (lhs->has_index()) {
            string idx = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << lhs->get_name() << "[" << idx << "]" << " = " << rt << "\n";
        } else {
            outcode << lhs->get_name() << " = " << rt << "\n";
            // Cache the temp for this variable, but NOT if rhs is a constant
            if (!dynamic_cast<ConstNode*>(rhs)) {
                symbol_to_temp[lhs->get_name()] = rt;
            }
        }
        return rt;
    }
};

// Statement node types

class StmtNode : public ASTNode {
public:
    virtual string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                                int& temp_count, int& label_count) const = 0;
};

// Expression statement node

class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {
            return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// Block (compound statement) node

class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements;

public:
    ~BlockNode() {
        for (auto stmt : statements) {
            delete stmt;
        }
    }
    
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        string last = "";
        for (auto stmt : statements) {
            last = stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return last;
    }
};

// If statement node

class IfNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* then_block;
    StmtNode* else_block; // nullptr if no else part

public:
    IfNode(ExprNode* cond, StmtNode* then_stmt, StmtNode* else_stmt = nullptr)
        : condition(cond), then_block(then_stmt), else_block(else_stmt) {}
    
    ~IfNode() {
        delete condition;
        delete then_block;
        if (else_block) delete else_block;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Allocate 3 labels up front
        string L_true = "L" + to_string(label_count++);
        string L_false = "L" + to_string(label_count++);
        string L_end = "L" + to_string(label_count++);
        
        string ct = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << ct << " goto " << L_true << "\n";
        outcode << "goto " << L_false << "\n";
        outcode << L_true << ":" << "\n";
        then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << L_end << "\n";
        outcode << L_false << ":" << "\n";
        if (else_block) {
            else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        outcode << L_end << ":" << "\n";
        return "";
    }
};

// While statement node

class WhileNode : public StmtNode {
private:
    ExprNode* condition;
    StmtNode* body;

public:
    WhileNode(ExprNode* cond, StmtNode* body_stmt)
        : condition(cond), body(body_stmt) {}
    
    ~WhileNode() {
        delete condition;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Allocate 3 labels
        string L_start = "L" + to_string(label_count++);
        string L_body = "L" + to_string(label_count++);
        string L_end = "L" + to_string(label_count++);
        
        outcode << L_start << ":" << "\n";
        string ct = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << ct << " goto " << L_body << "\n";
        outcode << "goto " << L_end << "\n";
        outcode << L_body << ":" << "\n";
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "goto " << L_start << "\n";
        outcode << L_end << ":" << "\n";
        return "";
    }
};

// For statement node

class ForNode : public StmtNode {
private:
    ExprNode* init;
    ExprNode* condition;
    ExprNode* update;
    StmtNode* body;

public:
    ForNode(ExprNode* init_expr, ExprNode* cond_expr, ExprNode* update_expr, StmtNode* body_stmt)
        : init(init_expr), condition(cond_expr), update(update_expr), body(body_stmt) {}
    
    ~ForNode() {
        if (init) delete init;
        if (condition) delete condition;
        if (update) delete update;
        delete body;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Generate init expression
        if (init) {
            init->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        
        // Allocate 3 labels
        string L_start = "L" + to_string(label_count++);
        string L_body = "L" + to_string(label_count++);
        string L_end = "L" + to_string(label_count++);
        
        outcode << L_start << ":" << "\n";
        
        // Clear cache at loop head
        symbol_to_temp.clear();
        
        string ct = "";
        if (condition) {
            ct = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        outcode << "if " << ct << " goto " << L_body << "\n";
        outcode << "goto " << L_end << "\n";
        outcode << L_body << ":" << "\n";
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        if (update) {
            update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        outcode << "goto " << L_start << "\n";
        outcode << L_end << ":" << "\n";
        return "";
    }
};

// Return statement node

class ReturnNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ReturnNode(ExprNode* e) : expr(e) {}
    ~ReturnNode() { if (expr) delete expr; }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        if (expr) {
            string rt = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "return " << rt << "\n";
            return rt;
        }
        outcode << "return" << "\n";
        return "";
    }
};

// Declaration node

class DeclNode : public StmtNode {
private:
    string type;
    vector<pair<string, int>> vars; // Variable name and array size (0 for regular vars)

public:
    DeclNode(string t) : type(t) {}
    
    void add_var(string name, int array_size = 0) {
        vars.push_back(make_pair(name, array_size));
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto& v : vars) {
            if (v.second == 0) {
                outcode << "// Declaration: " << type << " " << v.first << "\n";
            } else {
                outcode << "// Declaration: " << type << " " << v.first << "[" << v.second << "]" << "\n";
            }
        }
        return "";
    }
    
    string get_type() const { return type; }
    const vector<pair<string, int>>& get_vars() const { return vars; }
};

// Function declaration node

class FuncDeclNode : public ASTNode {
private:
    string return_type;
    string name;
    vector<pair<string, string>> params; // Parameter type and name
    BlockNode* body;

public:
    FuncDeclNode(string ret_type, string n) : return_type(ret_type), name(n), body(nullptr) {}
    ~FuncDeclNode() { if (body) delete body; }
    
    void add_param(string type, string name) {
        params.push_back(make_pair(type, name));
    }
    
    void set_body(BlockNode* b) {
        body = b;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Clear cache per function
        symbol_to_temp.clear();
        
        // Emit function header comment
        outcode << "// Function: " << return_type << " " << name << "(";
        for (int i = 0; i < (int)params.size(); i++) {
            if (i > 0) outcode << ", ";
            outcode << params[i].first << " " << params[i].second;
        }
        outcode << ")" << "\n";
        
        // Generate body
        if (body) {
            body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return "";
    }
};

// Helper class for function arguments

class ArgumentsNode : public ASTNode {
private:
    vector<ExprNode*> args;

public:
    ~ArgumentsNode() {
        // Don't delete args here - they'll be transferred to FuncCallNode
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) args.push_back(arg);
    }
    
    ExprNode* get_argument(int index) const {
        if (index >= 0 && index < args.size()) {
            return args[index];
        }
        return nullptr;
    }
    
    size_t size() const {
        return args.size();
    }
    
    const vector<ExprNode*>& get_arguments() const {
        return args;
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // This node doesn't generate code directly
        return "";
    }
};

// Function call node

class FuncCallNode : public ExprNode {
private:
    string func_name;
    vector<ExprNode*> arguments;

public:
    FuncCallNode(string name, string result_type)
        : ExprNode(result_type), func_name(name) {}
    
    ~FuncCallNode() {
        for (auto arg : arguments) {
            delete arg;
        }
    }
    
    void add_argument(ExprNode* arg) {
        if (arg) arguments.push_back(arg);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // Generate code for each argument and emit param
        for (auto arg : arguments) {
            string at = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "param " << at << "\n";
        }
        string t = "t" + to_string(temp_count++);
        outcode << t << " = call " << func_name << ", " << arguments.size() << "\n";
        return t;
    }
};

// Program node (root of AST)

class ProgramNode : public ASTNode {
private:
    vector<ASTNode*> units;

public:
    ~ProgramNode() {
        for (auto unit : units) {
            delete unit;
        }
    }
    
    void add_unit(ASTNode* unit) {
        if (unit) units.push_back(unit);
    }
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        for (auto unit : units) {
            unit->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            outcode << "\n";
        }
        return "";
    }
};

#endif // AST_H
