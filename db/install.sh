#!/bin/bash

# Define constants.
#==============================================================================
# The default sql directory.
#------------------------------------------------------------------------------
SQL_DIR="sql"

create_directory()
{
    local DIRECTORY="$1"

    rm -rf "$DIRECTORY"
    mkdir "$DIRECTORY"
}

display_heading_message()
{
    echo
    echo "********************** $@ **********************"
    echo
}

display_message()
{
    echo "$@"
}

display_error()
{
    >&2 echo "$@"
}

pop_directory()
{
    popd >/dev/null
}

push_directory()
{
    local DIRECTORY="$1"

    pushd "$DIRECTORY" >/dev/null
}

display_help()
{
    display_message "Usage: ./install.sh [OPTIONS]..."
    display_message "Manage the instalation database"
    display_message "Script options:"
    display_message "  --help"
    display_message "  --install"
    display_message "  --make"
    display_message "  --creatdb"
    display_message "  --update"
    display_message "  --patch"
    display_message "  --kladr"
    display_message "  --api"
}

# Initialize environment.
#==============================================================================
# Exit this script on the first error.
#------------------------------------------------------------------------------
set -e

# Parse command line options that are handled by this script.
#------------------------------------------------------------------------------
for OPTION in "$@"; do
    case $OPTION in
        # Standard script options.
        (--help)	DISPLAY_HELP="yes";;

        # Script options.
        (--install)	SCRIPT="install";;
        (--make)	SCRIPT="make";;
        (--createdb)	SCRIPT="createdb";;
        (--patch)	SCRIPT="patch";;
        (--kladr)	SCRIPT="kladr";;
        (--api)		SCRIPT="api";;
    esac
done

# Set param.
#------------------------------------------------------------------------------
if [[ !($SCRIPT) ]]; then
    SCRIPT="install"
fi

display_configuration()
{
    display_message "Installer configuration."
    display_message "--------------------------------------------------------------------"
    display_message "SCRIPT: $SCRIPT"
    display_message "--------------------------------------------------------------------"
}

# Standard sql build.
build_sql()
{
    push_directory "$SQL_DIR"

    sudo -u postgres -H psql -d template1 -f $SCRIPT.psql 2>"../log/$SCRIPT.log"

    pop_directory
}

# Build.
#==============================================================================

if [[ $DISPLAY_HELP ]]; then
    display_help
else
    display_configuration
    time build_sql "${SCRIPT[@]}"
fi
