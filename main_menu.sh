#!/bin/bash

function create_database() {
    read -p "Enter Database Name: " dbname
    if [[ $dbname =~ ^[a-zA-Z_][a-zA-Z0-9_]* ]]; then
        #the "=" operator test for string equality, "=~" operator used to match a string with regular expression
        # "^" indicates the start of the string
        # "[a-zA-Z_]" matches any uppercase or lowercase letter or underscore
        # "[a-zA-Z0-9_]*" the rest matches zero or more occurrences of any uppercase or lowercase letter or digit or underscore
        dbname=${dbname,,}
        # braces to combine the variable dbname and the ,, which is a Bash-specific feature to convert all letters to lower case
        # this dbname=${dbname},, or this dbname=$dbname,, will name like that databasename,,
        if [ -d "$dbname" ]; then
            echo "Database already exists!"
        else
            mkdir $dbname
            echo "Database created successfully!"
        fi
    else
        echo "Invalid database name! The name should only contain letters, numbers, underscores and without any spaces, and should start with an underscore or a letter (not a number)."
    fi
    read -p "Press any key to continue..." -n1
}

function list_databases() {
    echo "List of Databases:"
    #check if there is dires found
    if [ "$(find . -maxdepth 1 -type d -not -name '.' | sed '1d' | wc -l)" -gt 0 ]; then
        # "$(...)" is used to capture the output of the previous commands and store it as a string to compare with -gt 0
        # "find" command search all the subdirectories in the cur dir except the cur dir itself using .
        # -maxdepth 1 specifies maximum depth of the search and 1 means that the search will be only in the cur dir and not subdirs
        # -type d specifies that search should only return dires
        # -not -name '.' specifies the search exclude the cur dir .
        # sed '1d' removes the first line of the output which is the name of the cur dir
        # wc -l counts number of lines in the output which corresponds to the number of dirs and -l to make wc count the line not the words
        for d in */; do
            echo "${d%/}"
            # The "*/" all dires in the cur dir
            # The "${d%/}" expression removes "/" character from the dir
        done
    else
        echo "No databases found!"
    fi
    read -p "Press any key to continue..." -n1
}

function connect_to_database() {
    read -p "Enter Database Name: " dbname
    if [ -d "$dbname" ]; then
        handle_database_submenu $dbname
    else
        echo "Database does not exist!"
        read -p "Press any key to continue..." -n1
    fi
}

function drop_database() {
    read -p "Enter Database Name: " dbname
    if [ -d "$dbname" ]; then
        #[ or [[ the two will work but use [ to be compatatble with more shells
        # -d option to check if the dir is in the cur dir or not
        rm -r $dbname
        # -r to remove recursivly
        # rmdir remove only dirs and only empty dirs
        echo "Database dropped successfully!"
    else
        echo "Database does not exist!"
    fi
    read -p "Press any key to continue..." -n1
}

while true; do
    # ; to write muliple commands or keywords in one line
    clear
    echo "Main Menu:"
    echo "1. Create Database"
    echo "2. List Databases"
    echo "3. Connect To Database"
    echo "4. Drop Database"
    read -p "Enter your choice [1-4]: " choice

    case $choice in
    1) create_database ;;
        # could be e) or any characters but not 1] or 1}
    2) list_databases ;;
    3) connect_to_database ;;
    4) drop_database ;;
    *)
        echo "Invalid option. Press any key to continue..."
        read -n1
        ;;
        # -n1 option to read one char and continue the script
        # -s option to make the read char not visible like passwords
    esac
done
