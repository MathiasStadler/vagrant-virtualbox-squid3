#!/bin/bash

# form here mainly
# https://github.com/ccache/ccache/issues/194

readonly TEST_FILE="hello_world"
readonly TEST_FILE_CPP="$TEST_FILE.cpp"
readonly TEST_FILE_O="$TEST_FILE.o"
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

	ccache g++ -g -pipe -o $TEST_FILE_O -c $TEST_FILE_CPP

}

function call_ccache_statistic() {

	ccache -s
}

create_test_file
compile_test_file
call_ccache_statistic
