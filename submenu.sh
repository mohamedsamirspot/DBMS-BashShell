#!/bin/bash

function create_table {
    read -p "Enter table name: " table_name
    # Validate table name format
    if [[ $table_name =~ ^[_a-zA-Z][_a-zA-Z0-9]*$ ]]; then
        # Convert table name to lowercase
        table_name=${table_name,,}

        table_file=$table_name.txt

        if [ -f $table_file ]; then
            echo "Table already exists!"
            return
        fi
    else
        echo "Invalid table name! The name should only contain letters, numbers, underscores and without any spaces, and should start with an underscore or a letter (not a number)."
        return
    fi

    # Ask for column names and data types
    echo -e "Enter column names and data types in this format (e.g. id:int(pk) name:string age:int) \nNote: Ensure that the pk is must and be the first column"
    # The -e option in the echo command enables the interpretation of escape sequences like \n
    read -p "Columns: " columns

    # Validate columns
    # Each column is a pair of name:type separated by space, appended with (pk) for primary key (first column)
    # Allowed data types: int, string
    # Example: id:int(pk) name:string age:int
    regex='^([a-zA-Z_]\w*):(int|string)(\(pk\)) *( [a-zA-Z_]\w*:(int|string))*$'
    if ! [[ $columns =~ $regex ]]; then
        echo "Invalid columns format!"
        return
    fi

    # ^ asserts the start of the string
    # ([a-zA-Z_]\w*) matches a word that starts with a letter or underscore, followed by zero or more letters, digits, or underscores
    # \w to accept digits
    # : matches a colon
    # (int|string) matches either "int" or "string"
    # (\(pk\)) matches "(pk)" in parentheses
    # * matches zero or more occurrences of the preceding space character
    # ( [a-zA-Z_]\w*:(int|string))* matches zero or more occurrences of a space character, followed by a word that starts with a letter or underscore, a colon, and either "int" or "string"
    # $ asserts the end of the string

    columns=${columns,,} # convert upper to lower cases
    # Write column names and data types to table file
    echo $columns | sed -E 's/(:int|\:string)(\(pk\))? /&\t\|/g' >$table_file

    # -E option in the sed command can make it easier to write and read regular expressions, especially when dealing with more complex patterns.
    #     s/ : This indicates a substitution operation.
    # (:int|:string) : This is a group that matches either the string ":int" or the string ":string". The vertical bar (|) is used to indicate alternation between the two possible matches. In regular expressions, parentheses are used to group elements together.
    # (pk)? : This is a group that matches the string "(pk)" optionally. The question mark indicates that the previous group is optional.
    # space after (pk)? is important for formatting
    # /&\t|/g : means to replace the matched pattern with itself followed by a tab character ("\t") and a vertical bar ("|") This is the replacement string, which replaces any matches found by the pattern. It consists of three parts:
    # & : This refers to the entire matched substring.
    # \t : This is a tab character.
    # | : This is a vertical bar character, which is often used to separate columns in data.
    # The "g" at the end of the pattern indicates that the substitution should be applied globally, replacing all occurrences in the input string.
    echo "Table $table_name created successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function list_tables {
    if [ ! $(find -name '*.txt') ]; then
        # ! inside [] or outside nothing differnt
        echo "No tables exist in this database."
    else
        echo "Tables in the database:"
        for file in *.txt; do
            # Extract the table name from the file name
            table_name=${file%.txt}
            echo - $table_name
        done
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function drop_table {
    read -p "Enter the name of the table to drop: " table_name
    table_file=${table_name}.txt
    if [ -f $table_file ]; then
        rm $table_file
        echo "Table dropped successfully!"
    else
        echo "Table does not exist!"
    fi
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function insert_into_table {
    read -p "Enter table name: " table_name
    table_file=$table_name.txt

    # Check if table file exists
    if ! [ -f "$table_file" ]; then
        echo "Table does not exist!"
        return
    fi

    # Read column names and primary key column name from table file
    column_names=$(head -n 1 "$table_file" | tr '|' '\n')
    # It reads the first line of a file specified by the variable $table_file.
    # It pipes this line to the tr command which translates or replaces all occurrences of the | character with a newline character \n.
    # The output of tr is then assigned to the variable column_names.


    # Prompt user to enter data for each column
    data=""
    for column in $column_names; do
        read -p "Enter value for column '$column': " value

        # Check if the column type is 'int' and validate the input accordingly
        if [[ "$column" == *"int"* ]]; then
            if ! [[ "$value" =~ ^[0-9]+$ ]]; then
                echo "Invalid column data: $value is not an integer for column $column!"
                return
            fi
        fi

        # check for | (no pipes allowed)
        if [[ "$value" == *"|"* ]]; then
            echo "Invalid value format: '|' not allowed!"
            return
        fi

        # Check if the column is the primary key column and if the entered value is already in the table
        if [[ "$column" == *"(pk)"* ]]; then
            if grep -q "^$value" "$table_file"; then
            # grep searches for a pattern (^$value) in the file $table_file means to match the beginning of a line (^) followed by the value of $value
            # -q option suppresses the output of grep and only returns the exit status. If grep finds a match, the exit status is 0 else exit status is 1, which means failure.
                echo "Invalid column value: $value already exists in $column column!"
                return
            fi
        fi

        data+="|$value"$'\t\t'
    done
    # Remove first pipe character
    data="${data:1}"
    # By using ${data:1} 1 is the index, the first character (the delimiter) is removed from the beginning of the string, and the resulting substring is stored back in the data variable. The modified data string can then be used in subsequent commands without the delimiter at the beginning.

    # Write data to table file
    echo $data >> $table_file
    # > overwrite       >> append
    echo "Data inserted into $table_name successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
function select_from_table {
    read -p "Enter the name of the table: " table_name
    table_file=$table_name.txt
    if [ ! -f $table_file ]; then
        echo "Table does not exist!"
        return
    fi

    read -p "Select all table or select by primary key? (all/key): " option
    if [ $option == "all" ]; then
        echo "$(cat $table_file)"
        # "" to prevent cat from printing in one line
    elif [ $option == "key" ]; then
        read -p "Enter the primary key value: " pk_value
        pk_output=$(grep ^$pk_value $table_file)
        if [[ ! $pk_output ]]; then
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
    if [[ $delete_all == "Y" || $delete_all == "y" ]]; then
        # Delete all lines except the first line
        sed -i '2,$d' "$table_file"
        echo "All records deleted from table '$table_name' successfully."
    elif [[ $delete_all == n || N ]]; then
        read -p "Enter value the pk for the record to delete: " pk_value
        if [[ ! $pk_value ]]; then
            echo "Primary key value is empty. Please enter a value."
            return
        fi
        if grep -q "^$pk_value" "$table_file"; then
            # grep searches for a pattern (^$pk_value) in the file $table_file means to match the beginning of a line (^) followed by the value of $pk_value
            # -q option suppresses the output of grep and only returns the exit status. If grep finds a match, the exit status is 0 else exit status is 1, which means failure.
            sed -i "/^$pk_value/d" "$table_file"
            # option -i means to edit the file in place it modifies the contents of the file directly instead of printing the modified text to the standard output
            # /^$pk_value/d means to delete any line that begins with the value of $pk_value
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

    # Read column names and primary key column name from table file
    column_names=$(head -n 1 "$table_file" | tr '|' '\n')
    # It reads the first line of a file specified by the variable $table_file.
    # It pipes this line to the tr command which translates or replaces all occurrences of the | character with a newline character \n.
    # The output of tr is then assigned to the variable column_names.

    # Prompt user to enter primary key value
    read -p "Enter the primary key value of the row to update: " pk_value

    # Find the row with the specified primary key value
    row=$(grep "^$pk_value\s\+" "$table_file")
    # to find the pk with this value pk_value followed by a space
    # \s is not like s/ in the create function it is a regular expression metacharacter that matches any whitespace character, including space, tab, newline, and other whitespace characters.

    if [ ! "$row" ]; then
        echo "No row found with primary key value '$pk_value'"
        return
    fi

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
                if ! [[ "$new_value" =~ ^[0-9]+$ ]]; then
                    echo "Invalid column data: $new_value is not an integer for column $column!"
                    return
                fi
            elif [[ "$column" == *"string"* ]]; then
                if [[ "$new_value" == *"|"* ]]; then
                    echo "Invalid value format: '|' not allowed for column '$column'!"
                    return
                fi
            fi
            new_data+="|$new_value"$'\t\t'
        fi
    done

    # Replace the old row with the new data
    sed -i "s/^$pk_value\s\+.*/$new_data/" "$table_file"

    # sed -i: This runs sed in "in-place" mode, meaning that it will modify the file directly rather than printing the modified contents to standard output.
    # "s/^$pk_value\s\+.*/$new_data/" is the substitution command that specifies what text to replace and with what. Here's what each part of the command does:
    # s/ indicates that this is a substitution command.
    # ^$pk_value is a regular expression that matches the start of a line (^) followed by the value of $pk_value variable, which is a pattern or value to search for.
    # \s\+ matches one or more whitespace characters.
    # .* matches any number of characters (except for a newline).
    # $new_data is the replacement text, which is a variable containing the new value that will replace the old value.
    # " and / are delimiter characters that surround the command and separate its parts.
    # "$table_file" is the path to the file that will be edited. The $table_file variable contains the name of the file to be modified.
    echo "Row with primary key value '$pk_value' updated successfully."
}
#----------------------------------------------------------------------------------------------------------------------------------------------
clear
echo "Connected to database: $1"
echo "=============================="
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
    echo "Connected to database: $1"
    echo "=============================="
done



# while true; do
#     clear
#     echo "Connected to database: $1"
#     echo "=============================="
#     echo "1. Create Table"
#     echo "2. List Tables"
#     echo "3. Drop Table"
#     echo "4. Insert into Table"
#     echo "5. Select From Table"
#     echo "6. Delete From Table"
#     echo "7. Update Table"
#     echo "0. Disconnect Database"
#     read -p "Enter your choice [1-7] or 0 to disconnect: " choice
#     case $choice in
#     1) create_table ;;
#     2) list_tables ;;
#     3) drop_table ;;
#     4) insert_into_table ;;
#     5) select_from_table ;;
#     6) delete_from_table ;;
#     7) update_table ;;
#     0)
#         cd ../
#         ./main_menu.sh
#         ;;
#     *) echo "Invalid choice!" ;;
#     esac
#     read -n1 -p "Press any key to continue..."
# done
