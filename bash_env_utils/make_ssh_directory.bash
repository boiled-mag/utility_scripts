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

pushd ~/

declare -r dot_ssh_directory=.ssh
declare -r authorized_keys_file=authorized_keys

mkdir -p ${dot_ssh_directory}
chmod 700 ${dot_ssh_directory}

touch ${dot_ssh_directory}/${authorized_keys_file}
chmod 600 ${dot_ssh_directory}/${authorized_keys_file}

popd

echo -e "${OK_PREFIX}" $0 has finished normally.

exit 0


