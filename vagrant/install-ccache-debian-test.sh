#!/bin/bash

# form here mainly
# https://github.com/ccache/ccache/issues/194

readonly TEST_FILE="hello_world"
readonly TEST_FILE_CPP="$TEST_FILE.cpp"
readonly TEST_FILE_O="$TEST_FILE.o"

function install_necessary_packages() {

	sudo apt-get update && sudo apt-get install -y --no-install-recommends build-essential

}

function create_test_file() {

	cat <<EOF >"${TEST_FILE_CPP}"
#include <iostream>

int main() {
    std::cout << "Hello" << std::endl;
    return 1;
}

EOF

}

function compile_test_file() {

	export CC="/usr/bin/gcc"
	export CXX="/usr/bin/g++"
	ccache gcc -g -pipe -o $TEST_FILE_O -c $TEST_FILE_CPP

}

function call_ccache_statistic() {

	ccache -s
}

install_necessary_packages
create_test_file
compile_test_file
call_ccache_statistic
