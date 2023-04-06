#!/bin/bash

function create_database() {
    read -p "Enter Database Name: " dbname
    # check database name
    if [[ "$dbname" =~ ^[a-zA-Z_][a-zA-Z0-9_]{0,127}$ ]]; then
        dbname=${dbname,,}
        if [ -d "$dbname" ]; then
            echo "Database already exists!"
        else
            mkdir "$dbname"
            echo "Database created successfully!"
        fi
    else
        echo -e "Invalid database name! \n\"The name should only contain letters, numbers, underscores and without any spaces, and should start with an underscore or a letter (not a number) with minimum 1 and maximum 128 characters.\""
    fi
    read -n1 -p "Press any key to continue..."
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function list_databases() {
    echo "List of Databases:"
    # check if there is directories in the current directory and exclude any errors
    if [ "$(ls -d */ 2>/dev/null)" ]; then
        for d in */; do
            echo ${d%/} # remove / from directory name
        done
    else
        echo "No databases found!"
    fi
    read -n1 -p "Press any key to continue..."
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function connect_to_database() {
    read -p "Enter Database Name: " dbname
    # check if there is a directory (database) with the input name and cd to it
    if [ -d "$dbname" ]; then
        cd "$dbname"
        ../submenu.sh "$dbname"
    else
        echo "Database does not exist!"
    fi
    read -n1 -p "Press any key to continue..."
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function drop_database() {
    read -p "Enter Database Name: " dbname
    # check if there is a directory (database) with the input name
    if [ -d "$dbname" ]; then
        rm -r "$dbname"
        echo "Database dropped successfully!"
    else
        echo "Database does not exist!"
    fi
    read -n1 -p "Press any key to continue..." 
}
#------------------------------------------------------------------------------------------------------------------------------------------------
while true; do
    clear
    echo "Main Menu:"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    read -p "Enter your choice [1-4]: " choice
    case "$choice" in
    1) create_database ;;
    2) list_databases ;;
    3) connect_to_database ;;
    4) drop_database ;;
    *)
        read -p "Invalid option. Press any key to continue..." -n1
        ;;
    esac
done