#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:

    symbol_table(int bucket_count)
    {
        this->bucket_count = bucket_count;
        current_scope = NULL;
        current_scope_id = 1;
    }

    ~symbol_table()
    {
        while(current_scope != NULL)
        {
            exit_scope();
        }
    }

    void enter_scope()
    {
        scope_table *new_scope = new scope_table(bucket_count, current_scope_id, current_scope);

        current_scope = new_scope;

        current_scope_id++;
    }

    void exit_scope()
    {
        if(current_scope == NULL)
        {
            return;
        }

        scope_table *temp = current_scope;

        current_scope = current_scope->get_parent_scope();

        delete temp;
    }

    bool insert(symbol_info *symbol)
    {
        if(current_scope == NULL)
        {
            return false;
        }

        return current_scope->insert_in_scope(symbol);
    }

    bool remove(symbol_info *symbol)
    {
        if(current_scope == NULL)
        {
            return false;
        }

        return current_scope->delete_from_scope(symbol);
    }

    symbol_info *lookup(symbol_info *symbol)
    {
        return lookup_by_name(symbol->get_name());
    }

    // Lab 3: the semantic checks look symbols up by name
    symbol_info *lookup_by_name(string name)
    {
        scope_table *temp = current_scope;

        while(temp != NULL)
        {
            symbol_info *result = temp->lookup_in_scope_by_name(name);

            if(result != NULL)
            {
                return result;
            }

            temp = temp->get_parent_scope();
        }

        return NULL;
    }

    // Lab 3: needed to detect a re-declaration in the *same* scope only
    symbol_info *lookup_in_current_scope(string name)
    {
        if(current_scope == NULL)
        {
            return NULL;
        }

        return current_scope->lookup_in_scope_by_name(name);
    }

    void print_current_scope(ofstream &outlog)
    {
        if(current_scope == NULL)
        {
            return;
        }

        current_scope->print_scope_table(outlog);
    }

    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" << endl << endl;

        scope_table *temp = current_scope;

        bool first = true;

        while(temp != NULL)
        {
            if(!first)
                outlog << endl;   // blank line between two scope tables

            first = false;

            temp->print_scope_table(outlog);

            temp = temp->get_parent_scope();
        }

        outlog << endl << "################################" << endl << endl;
    }

    // Optional helper
    scope_table* get_current_scope()
    {
        return current_scope;
    }
};

#endif
