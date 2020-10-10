#!/bin/bash
# -*- coding: utf-8 -*-

# set shell options
set -eu

################################################################################
# Log prefixes
################################################################################
declare -r OK_PREFIX="[ \033[32mOK    \033[0m ]"
declare -r ERROR_PREFIX="[ \033[31mERROR \033[0m ]"
declare -r NOTICE_PREFIX="[ \033[34mNOTICE\033[0m ]"

################################################################################
# Functions
################################################################################
function usage() {
    cat<<EOF
usage:
    $0 [options]

options:
  -h    show this help.
EOF
    exit 1
}

################################################################################
# Entry point
################################################################################
while getopts ":h" OPT; do
    case ${OPT} in
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

echo -e "${OK_PREFIX}" $0 has finished normally.

exit 0


