#!/bin/bash

function create_database() {
    read -p "Enter Database Name: " dbname
    if [[ $dbname =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        #the "=" operator test for string equality, "=~" operator used to match a string with regular expression
        # "^" indicates the start of the string
        # "[a-zA-Z_]" matches any uppercase or lowercase letter or underscore
        # "[a-zA-Z0-9_]*" the rest matches zero or more occurrences of any uppercase or lowercase letter or digit or underscore
        # $ symbol at the end of the regex which indicates that the string should end with the preceding pattern onlyyy and to handle spaces
        dbname=${dbname,,}
        # braces to combine the variable dbname and the ,, which is a Bash-specific feature to convert all letters to lower case
        # this dbname=${dbname},, or this dbname=$dbname,, will name like that databasename,,
        if [ -d $dbname ]; then
            echo "Database already exists!"
        else
            mkdir $dbname
            echo "Database created successfully!"
        fi
    else
        echo "Invalid database name! The name should only contain letters, numbers, underscores and without any spaces, and should start with an underscore or a letter (not a number)."
    fi
    read -n1 -p "Press any key to continue..."
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function list_databases() {
    echo "List of Databases:"
    #check if there is dires found
    if [ $(find . -maxdepth 1 -type d -not -name '.' | sed '1d' | wc -l) -gt 0 ]; then
        # . after find just the path paramter it can be only find
        # "$(...)" is used to capture the output of the previous commands and store it as a string to compare with -gt 0
        # "find" command search files or dires on cur dir
        # -maxdepth 1 specifies max depth of the search and 1 means that the search will be only in the cur dir and not subdirs
        # -type d specifies that search should only return dires
        # -not -name '.' specifies the search exclude the cur dir .
        # sed '1d' removes the first line of the find output which is the name of ./.git dir or sed '1,2d' to removes first two lines
        # wc -l counts number of lines in the output which corresponds to the number of dirs without . or ./.git and -l to make wc count the line not the words
        for d in */; do
            echo "${d%/}"
            # The "*/" all dires in the cur dir
            # The "${d%/}" expression removes "/" character from the dir
        done
    else
        echo "No databases found!"
    fi
    read -n1 -p "Press any key to continue..."
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function connect_to_database() {
    read -p "Enter Database Name: " dbname
    if [ -d $dbname ]; then
        cd $dbname
        ../submenu.sh $dbname
    else
        echo "Database does not exist!"
        read -n1 -p "Press any key to continue..."
    fi
}
#-------------------------------------------------------------------------------------------------------------------------------------------------
function drop_database() {
    read -p "Enter Database Name: " dbname
    if [ -d $dbname ]; then
        #[ or [[ the two will work but [ will be compatatble with more shells
        # -d option to check if the dir is in the cur dir or not
        rm -r $dbname
        # -r to remove recursivly
        # rmdir remove only emptyyy dirs
        echo "Database dropped successfully!"
    else
        echo "Database does not exist!"
    fi
    read -n1 -p "Press any key to continue..." 
}
#------------------------------------------------------------------------------------------------------------------------------------------------
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
        # -n1 option to read one char and run the script again
    esac
done