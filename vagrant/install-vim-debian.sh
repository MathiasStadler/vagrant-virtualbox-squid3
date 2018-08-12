#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update && sudo apt-get install -y --no-install-recommends vim

# create /etc/vim/vimrc.local

cat <<EOF >"/etc/vim/vimrc.local"
#http://vim.wikia.com/wiki/Fix_arrow_keys_that_display_A_B_C_D_on_remote_shell
set nocompatible
EOF
