#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include<bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;

    string symbol_type;             // VARIABLE / ARRAY / FUNCTION
    string data_type;               // int / float / void / char ...
    vector<string> parameter;       // Function parameter types
    int array_size;                 // Array size (0 if not an array)

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;

        symbol_type = "";
        data_type = "";
        array_size = 0;
    }

    string get_name()
    {
        return name;
    }

    string get_type()
    {
        return type;
    }

    string get_symbol_type()
    {
        return symbol_type;
    }

    string get_data_type()
    {
        return data_type;
    }

    vector<string> get_parameter()
    {
        return parameter;
    }

    int get_array_size()
    {
        return array_size;
    }


    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_symbol_type(string symbol_type)
    {
        this->symbol_type = symbol_type;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    void add_param_type(string param_type)
    {
        parameter.push_back(param_type);
    }

    void set_array_size(int array_size)
    {
        this->array_size = array_size;
    }

    ~symbol_info()
    {
        // No dynamic memory allocation, so nothing to deallocate.
    }
};

#endif