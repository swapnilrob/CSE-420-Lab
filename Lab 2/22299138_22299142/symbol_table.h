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

    symbol_info *lookup(symbol_info *symbol)
    {
        scope_table *temp = current_scope;

        while(temp != NULL)
        {
            symbol_info *result = temp->lookup_in_scope(symbol);

            if(result != NULL)
            {
                return result;
            }

            temp = temp->get_parent_scope();
        }

        return NULL;
    }

    void print_current_scope()
    {
        // Not required in this assignment.
        // We use print_all_scopes() instead.
    }

    void print_all_scopes(ofstream& outlog)
    {
        outlog << "################################" << endl << endl;

        scope_table *temp = current_scope;

        while(temp != NULL)
        {
            temp->print_scope_table(outlog);

            temp = temp->get_parent_scope();
        }

        outlog << "################################" << endl << endl;
    }

    // Optional helper
    scope_table* get_current_scope()
    {
        return current_scope;
    }
};

#endif