#!/bin/bash

function create_table {
    read -p "Enter table name: " table_name
        # Validate table name format
    if [[ "$table_name" =~ ^[_a-zA-Z][_a-zA-Z0-9]{0,127}$ ]]; then
        # Convert table name to lowercase
        table_name=${table_name,,}
        table_file=$table_name.txt
        # check if table exist
        if [ -f $table_file ]; then
            echo "Table already exists!"
            return
        fi
    else
        echo "Invalid table name! The name should only contain letters, numbers, underscores and without any spaces, and should start with an underscore or a letter (not a number) with minimum 1 and maximum 128 characters.."
        return
    fi

    # Ask for column names and data types
    echo -e "Enter column names and data types in this format (e.g. id:int(pk) name:string age:int) \nNote: Ensure that the pk is must and be the first column"
    read -p "Columns: " columns

    # Validate columns
    # Each column is a pair of name:type separated by space, appended with (pk) for primary key (first column)
    # Allowed data types: int, string --> Example: id:int(pk) name:string age:int
    regex='^([a-zA-Z_]\w*):(int|string)(\(pk\)) *( [a-zA-Z_]\w*:(int|string))*$'
    if ! [[ "$columns" =~ $regex ]]; then
        echo "Invalid columns format!"
        return
    fi
    # convert upper to lower cases
    columns=${columns,,}
    # Write column names and data types to table file with the appropriate formatting
    echo $columns | sed -E 's/(:int|\:string)(\(pk\))? /&\t\|/g' >$table_file
    
    echo "Table $table_name created successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function list_tables {
    if [[ ! $(ls *.txt 2>/dev/null) ]]; then
        echo "No tables exist in this database."
    else
        echo "Tables in the database:"
        for file in *.txt; do
            table_name=${file%.txt}
            echo - "$table_name"
        done
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function drop_table {
    read -p "Enter the name of the table to drop: " table_name
    table_file=$table_name.txt
    # check if table exist in current directory
    if [ -f "$table_file" ]; then
        rm "$table_file"
        echo "Table dropped successfully!"
    else
        echo "Table does not exist!"
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function insert_into_table {
    read -p "Enter table name: " table_name
    table_file=$table_name.txt

    # Check if table file exists in current directory
    if ! [ -f "$table_file" ]; then
        echo "Table does not exist!"
        return
    fi

    # Read column names and primary key column name from table file
    column_names=$(head -n 1 "$table_file" | tr '|' '\n')
    # It reads the first line of a file specified by the variable $table_file.
    # It pipes this line to the tr command which translates or replaces all occurrences of the | character with a newline character \n.
    # The output of tr is then assigned to the variable column_names.


    # Prompt user to enter data for each column (each line of varable column_names)
    data=""
    for column in $column_names; do
        read -p "Enter value for column '$column': " value


        # Check if the column type is 'int' or 'string' and validate the input accordingly
        if [[ "$column" == *"int"* ]]; then
            if ! [[ $value =~ ^-?[0-9]*$ ]] || (( value < -2147483648 )) || (( value > 2147483647 )); then
                    # -? optional negative sign
                echo "Invalid column data: $value is not an integer within the range of a 32-bit signed integer for column $column!"
                return
            fi
        elif [[ "$column" == *"string"* ]]; then
            if [[ "$value" == *"|"* ]] || [[ ${#value} -gt 65000 ]]; then
                echo "Invalid value format: '|' not allowed or the new value exceeds 65000 characters for column '$column'!"
                return
            fi
        fi

        # Check if the column is the primary key column and if the entered value is already in the table
        if [[ "$column" == *"(pk)"* ]]; then
            if grep -q "^$value\b" "$table_file"; then
            # grep searches for a pattern (^$value) in the file $table_file means to match the beginning of a line (^) followed by the value of $value
            # -q option suppresses the output of grep and only returns the exit status. If grep finds a match, the exit status is 0 else exit status is 1, which means failure.
            # The regular expression ^$value\b matches lines that start with the value in the $value variable, followed by a word boundary (\b). This ensures that the match is for the first word of the line, rather than any instance of the value appearing within the line.
                echo "Invalid column value: $value already exists in $column column!"
                return
            fi
        fi
        data+="|$value"$'\t\t'

        # The $'...' syntax is used to enable escape sequences in strings.
    done

    # Remove first pipe character
    data="${data:1}"
    # Write data to table file
    sed -i '$a\'"$data"'' "$table_file"
    #\ is used to escape the newline character that separates the command from the text to be appended
    #'' is an empty string that separates $data from the next argument, which is $table_file
    echo "Data inserted into $table_name successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function select_from_table {
    read -p "Enter the name of the table: " table_name
    table_file=$table_name.txt
    # check if table exist in current directory
    if [ ! -f "$table_file" ]; then
        echo "Table does not exist!"
        return
    fi

    read -p "Select all table or select by primary key? (all/key): " option
    if [ "$option" == "all" ]; then
        cat "$table_file"
    elif [ "$option" == "key" ]; then
        read -p "Enter the primary key value: " pk_value
        pk_output=$(grep "^$pk_value\b" "$table_file")
        if [[ ! "$pk_output" ]]; then
            echo "not found"
        else
            echo "$pk_output"
        fi
    else
        echo "Invalid option selected!"
        return
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function delete_from_table {
    read -p "Enter table name: " table_name
    table_file=$table_name.txt

    # Check if table file exists
    if [ ! -f "$table_file" ]; then
        echo "Table does not exist!"
        return
    fi

    read -p "Do you want to delete all records from '$table_name' (Y/N)? " delete_all
    if [[ "$delete_all" == "Y" || "$delete_all" == "y" ]]; then
        # Delete all lines except the first line
        sed -i '2,$d' "$table_file"
        echo "All records deleted from table '$table_name' successfully."
    elif [[ "$delete_all" == n || N ]]; then
        read -p "Enter value the pk for the record to delete: " pk_value
        if [[ ! "$pk_value" ]]; then
            echo "Primary key value is empty. Please enter a value."
            return
        fi
        if grep -q "^$pk_value" "$table_file"; then
            # grep searches for a pattern (^$pk_value) in the file $table_file means to match the beginning of a line (^) followed by the value of $pk_value
            # -q option suppresses the output of grep and only returns the exit status. If grep finds a match, the exit status is 0 else exit status is 1, which means failure.
            sed -i "/\<$pk_value\>/d" "$table_file"
            # option -i means to edit the file in place it modifies the contents of the file directly instead of printing the modified text to the standard output
            # /\<$pk_value\>/d means to delete any line that begins with a full word with the value of $pk_value
            echo "Record with primary key '$pk_value' deleted from table '$table_name' successfully."
        else
            echo "Record with primary key '$pk_value' does not exist in table '$table_name'!"
        fi
    else
        echo "Invalid option selected!"
        return
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function update_table {
    read -p "Enter table name to update: " table_name
    table_file=$table_name.txt

    # Check if table file exists
    if [ ! -f "$table_file" ]; then
        echo "Table does not exist!"
        return
    fi

    # Prompt user to enter primary key value
    read -p "Enter the primary key value of the row to update: " pk_value

    # Find the row with the specified primary key value
    row=$(grep "^$pk_value" "$table_file")
    # to find the pk with this value pk_value followed by a space

    if [ ! "$row" ]; then
        echo "No row found with primary key value '$pk_value'"
        return
    fi

    # Read column names and primary key column name from table file
    column_names=$(head -n 1 "$table_file" | tr '|' '\n')
    # It reads the first line of a file specified by the variable $table_file.
    # It pipes this line to the tr command which translates or replaces all occurrences of the | character with a newline character \n.
    # The output of tr is then assigned to the variable column_names.


    # Prompt user to enter new values for each column
    new_data=""
    for column in $column_names; do
        # Check if the column is the primary key column
        if [[ "$column" == *"(pk)"* ]]; then
            # Add the primary key value to the new data
            new_data+="$pk_value"$'\t\t'
        else
            # Prompt user to enter a new value for the column
            read -p "Enter new value for column $column: " new_value
            # Check if the column type is 'int' or 'string' and validate the input accordingly
            if [[ "$column" == *"int"* ]]; then
                if ! [[ $new_value =~ ^-?[0-9]*$ ]] || (( new_value < -2147483648 )) || (( new_value > 2147483647 )) ; then
                     # -? optional negative sign
                   echo "Invalid column data: $new_value is not an integer within the range of a 32-bit signed integer for column $column!"
                   return
                fi
            elif [[ "$column" == *"string"* ]]; then
                if [[ "$new_value" == *"|"* ]] || [[ ${#new_value} -gt 65000 ]]; then
                    echo "Invalid value format: '|' not allowed or the new value exceeds 65000 characters for column '$column'!"
                    return
                fi
            fi
            new_data+="|$new_value"$'\t\t'
        fi
    done

    # Replace the old row with the new data
    sed -i "s/^$pk_value\s\+.*/$new_data/" "$table_file"
    # find a line starts with pk_value followd by one or more white spaces and any number of anything after that using (.*)
    echo "Row with primary key value '$pk_value' updated successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
clear
echo -e "Connected to database: $1 \n-------------------------------------------"
PS3="Enter your choice [1-7] or 8 to disconnect: "
select opt in "Create Table" "List Tables" "Drop Table" "Insert into Table" "Select From Table" "Delete From Table" "Update Table" "Disconnect Database"; do
    case $opt in
    "Create Table") create_table ;;
    "List Tables") list_tables ;;
    "Drop Table") drop_table ;;
    "Insert into Table") insert_into_table ;;
    "Select From Table") select_from_table ;;
    "Delete From Table") delete_from_table ;;
    "Update Table") update_table ;;
    "Disconnect Database")
        cd ../
        bash main_menu.sh
        ;;
    *) echo "Invalid choice!" ;;
    esac
    read -p "Press any key to continue..." -n1
    clear
    echo -e "Connected to database: $1 \n-------------------------------------------"
done