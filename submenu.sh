#!/bin/bash
function create_table {
    read -p "Enter table name: " table_name
    # Validate table name format
    regex='^[_a-zA-Z][_a-zA-Z0-9]*$'
    if ! [[ $table_name =~ $regex ]]; then
        echo "Invalid table name format! Table name must start with a letter or underscore and contain only letters, numbers, and underscores."
        return
    fi
    # Convert table name to lowercase
    table_name=$(echo "$table_name" | tr '[:upper:]' '[:lower:]')
    table_file="$table_name.txt"

    # Check if table file already exists
    if [ -f "$table_file" ]; then
        echo "Table '$table_name' already exists!"
        return
    fi

    # Ask for column names and data types
    echo "Enter column names and data types (e.g. id:int(pk) name:string age:int)"
    read -p "Columns: " columns

    # Validate columns
    # Each column is a pair of name:type separated by space, with optional (pk) for primary key
    # Allowed data types: int, string
    # Primary key is the first column if not specified explicitly
    # Example: id:int(pk) name:string age:int
    regex='^([a-zA-Z_]\w*):(int|string)(\(pk\))? *( [a-zA-Z_]\w*:(int|string)(\(pk\))?)*$'
    if ! [[ $columns =~ $regex ]]; then
        echo "Invalid columns format!"
        return
    fi

    # Write column names and data types to table file
    echo "$columns" | sed -E 's/(:int|\:string)(\(pk\))?/&\t\|/g' | sed -E 's/ +\|/\t\|/g' > "$table_file"
    echo "Table '$table_name' created successfully."
}

function insert_into_table {
    read -p "Enter table name: " table_name
    table_file="$table_name.txt"

    # Check if table file exists
    if ! [ -f "$table_file" ]; then
        echo "Table '$table_name' does not exist!"
        return
    fi

    # Read column names and primary key column name from table file
    column_names=$(head -n 1 "$table_file" | tr '|' '\n')
    pk_column=$(head -n 1 "$table_file" | awk '{print $NF}')

    # Prompt user to enter data for each column
    data=""
    for column in $column_names; do
        read -p "Enter value for column '$column': " value
        # Validate value format (no pipes allowed)
        if [[ "$value" == *"|"* ]]; then
            echo "Invalid value format: '|' not allowed!"
            return
        fi

        # Check if the column is the primary key column and if the entered value is already in the table
        if [[ "$column" == *"(pk)"* ]]; then
            if grep -q "^$value" "$table_file"; then
                echo "Invalid column value: '$value' already exists in '$column' column!"
                return
            fi
        fi

        data+="|$value"$'\t\t'
    done
    # Remove leading pipe character
    data="${data:1}"

    # Write data to table file
    echo "$data" >> "$table_file"
    echo "Data inserted into '$table_name' successfully."
}





function list_tables {
    echo "Tables in the database:"
    for file in *.txt; do
        # Extract the table name from the file name
        table_name=${file%.txt}
        # Replace any underscores with spaces for display
        table_name=${table_name//_/ }
        echo "- $table_name"
    done
}


function drop_table {
    read -p "Enter the name of the table to drop: " table_name
    # Remove any spaces from the table name
    table_name=${table_name// /""}
    table_file="${table_name}.txt"
    if [[ -f "$table_file" ]]; then
        rm "$table_file"
        echo "Table dropped successfully!"
    else
        echo "Table does not exist!"
    fi
}

function select_from_table {
    read -p "Enter the name of the table: " table_name
    table_file="${table_name}.txt"
    if [[ ! -f "$table_file" ]]; then
        echo "Table does not exist!"
    else
        echo "$(cat $table_file)"
    fi
}


function delete_from_table {
    read -p "Enter table name to delete all the records: " table_name
    table_file="$table_name.txt"

    # Check if table file exists
    if [ ! -f "$table_file" ]; then
        echo "Table '$table_name' does not exist!"
        return
    fi

    # Delete all lines except the first line
    sed -i '2,$d' "$table_file"
    echo "All records deleted from table '$table_name' successfully."
}




# function update_table() {
#     # implementation of update table function
# }
while true; do
    clear
    echo "Connected to database: $1"
    echo "=============================="
    echo "1. Create Table"
    echo "2. List Tables"
    echo "3. Drop Table"
    echo "4. Insert into Table"
    echo "5. Select From Table"
    echo "6. Delete From Table"
    echo "7. Update Table"
    echo "0. Disconnect Database"
    read -p "Enter your choice [1-7] or 0 to disconnect: " choice
    case $choice in
    1) create_table ;;
    2) list_tables ;;
    3) drop_table ;;
    4) insert_into_table ;;
    5) select_from_table ;;
    6) delete_from_table ;;
    7) update_table ;;
    0) cd ../; bash main_menu.sh ;;
    *) echo "Invalid choice!" ;;
    esac
    read -p "Press any key to continue..." -n1
done

