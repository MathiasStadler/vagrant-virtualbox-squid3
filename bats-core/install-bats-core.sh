#!/bin/bash

# install bats to $HOME

cd "$HOME" || exit

git clone https://github.com/bats-core/bats-core.git
cd bats-core || exit
./install.sh /usr/local
