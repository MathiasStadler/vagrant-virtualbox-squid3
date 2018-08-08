#!/bin/bash

# install bats to $HOME

cd "$HOME" || exit

# clone
git clone https://github.com/bats-core/bats-core.git

#
cd bats-core || exit

# install bats
./install.sh /usr/local
