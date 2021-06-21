#!/usr/bin/env bash

# -------------------------------------------------------------------------------- #
# Description                                                                      #
# -------------------------------------------------------------------------------- #
# This script will locate and process all relevant files within the given git      #
# repository. Errors will be stored and a final exit status used to show if a      #
# failure occured during the processing.                                           #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Configure the shell.                                                             #
# -------------------------------------------------------------------------------- #

set -Eeuo pipefail

# -------------------------------------------------------------------------------- #
# Global Variables                                                                 #
# -------------------------------------------------------------------------------- #
# TEST_COMMAND - The command to execute to perform the test.                       #
# FILE_TYPE_SEARCH_PATTERN - The pattern used to match file types.                 #
# FILE_NAME_SEARCH_PATTERN - The pattern used to match file names.                 #
# EXIT_VALUE - Used to store the script exit value - adjusted by the fail().       #
# -------------------------------------------------------------------------------- #

TEST_COMMAND='puppet-lint'
FILE_TYPE_SEARCH_PATTERN='No Magic Pattern'
FILE_NAME_SEARCH_PATTERN='\.pp$'
EXIT_VALUE=0

# -------------------------------------------------------------------------------- #
# Success                                                                          #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file was successful.             #
# -------------------------------------------------------------------------------- #

function success()
{
    local message="${1:-}"

    if [[ -n "${message}" ]]; then
        printf ' [  %s%sOK%s  ] Processing successful for %s\n' "${bold}" "${success}" "${normal}" "${message}"
    fi
}

# -------------------------------------------------------------------------------- #
# Fail                                                                             #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file failed and adjust the       #
# EXIT_VALUE to record this.                                                       #
# -------------------------------------------------------------------------------- #

function fail()
{
    local message="${1:-}"
    local errors="${2:-}"

    if [[ -n "${message}" ]]; then
        printf ' [ %s%sFAIL%s ] Processing failed for %s\n' "${bold}" "${error}" "${normal}" "${message}"
    fi

    if [[ -n "${errors}" ]]; then
        echo "${errors}"
    fi

    EXIT_VALUE=1
}

# -------------------------------------------------------------------------------- #
# Skip                                                                             #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file was skipped.                #
# -------------------------------------------------------------------------------- #

function skip()
{
    local message="${1:-}"

    file_count=$((file_count+1))
    if [[ -n "${message}" ]]; then
        printf ' [ %s%sSkip%s ] Skipping %s\n' "${bold}" "${skip}" "${normal}" "${message}"
    fi
}

# -------------------------------------------------------------------------------- #
# Check                                                                            #
# -------------------------------------------------------------------------------- #
# Check a specific file.                                                           #
# -------------------------------------------------------------------------------- #

function check()
{
    local filename="$1"
    local errors

    file_count=$((file_count+1))
    if errors=$( ${TEST_COMMAND} "${filename}" 2>&1 ); then
        success "${filename}"
        ok_count=$((ok_count+1))
    else
        fail "${filename}" "${errors}"
        fail_count=$((fail_count+1))
    fi
}

# -------------------------------------------------------------------------------- #
# Scan Files                                                                       #
# -------------------------------------------------------------------------------- #
# Locate all of the relevant files within the repo and process compatible ones.    #
# -------------------------------------------------------------------------------- #

function scan_files()
{
    while IFS= read -r filename
    do
        if file -b "${filename}" | grep -qE "${FILE_TYPE_SEARCH_PATTERN}"; then
            check "${filename}"
        elif [[ "${filename}" =~ ${FILE_NAME_SEARCH_PATTERN} ]]; then
            check "${filename}"
        fi
    done < <(git ls-files | sort -zVd)
}

function center_text()
{
    textsize=${#1}
    span=$(((screen_width + textsize) / 2))

    printf '%*s\n' "${span}" "$1"
}

function draw_line
{
    printf '%*s\n' "${screen_width}" '' | tr ' ' -
}

function header
{
    draw_line
    center_text "${BANNER}"
    draw_line
}

function footer
{
    draw_line
    center_text "Total: ${file_count}, OK: ${ok_count}, Failed: ${fail_count}, Skipped: $skip_count"
    draw_line
}

function setup
{
    export TERM=xterm

    screen_width=$(tput cols)
    bold="$(tput bold)"
    normal="$(tput sgr0)"
    error="$(tput setaf 1)"
    success="$(tput setaf 2)"
    skip="$(tput setaf 6)"

    file_count=0
    ok_count=0
    fail_count=0
    skip_count=0
}

# -------------------------------------------------------------------------------- #
# Install                                                                          #
# -------------------------------------------------------------------------------- #
# Install the required tooling.                                                    #
# -------------------------------------------------------------------------------- #

function install_prerequisites
{
    local gem_name='puppet-lint'

    gem install ${gem_name}

    VERSION=$(gem list | grep "^${gem_name} " | sed 's/[^0-9.]*\([0-9.]*\).*/\1/')
    BANNER="Scanning all puppet code with ${gem_name} (version: ${VERSION})"
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

setup
install_prerequisites
header
scan_files
footer

exit $EXIT_VALUE

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
