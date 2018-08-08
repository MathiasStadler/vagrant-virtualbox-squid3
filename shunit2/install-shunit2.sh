#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

cd $HOME || exit 1

git clone https://github.com/kward/shunit2.git

cd shunit2
