#!/bin/bash

# Dynamically create an array by name
function arr() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable" 1>&2
		return 1
	}
	declare -g -a $1=\(\)
}

# Insert incrementing by incrementing index eg. array+=(data)
function arr_insert() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable" 1>&2
		return 1
	}
	declare -p "$1" >/dev/null 2>&1
	[[ $? -eq 1 ]] && {
		echo "Bash variable [${1}] doesn't exist" 1>&2
		return 1
	}
	declare -n r=$1
	r[${#r[@]}]=$2
}

# Update an index by position
function arr_set() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable" 1>&2
		return 1
	}
	declare -p "$1" >/dev/null 2>&1
	[[ $? -eq 1 ]] && {
		echo "Bash variable [${1}] doesn't exist" 1>&2
		return 1
	}
	declare -n r=$1
	r[$2]=$3
}

# Get the array content ${array[@]}
function arr_get() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable" 1>&2
		return 1
	}
	declare -p "$1" >/dev/null 2>&1
	[[ $? -eq 1 ]] && {
		echo "Bash variable [${1}] doesn't exist" 1>&2
		return 1
	}
	declare -n r=$1
	echo ${r[@]}
}

# Get the value stored at a specific index eg. ${array[0]}
function arr_at() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable" 1>&2
		return 1
	}
	declare -p "$1" >/dev/null 2>&1
	[[ $? -eq 1 ]] && {
		echo "Bash variable [${1}] doesn't exist" 1>&2
		return 1
	}
	[[ ! "$2" =~ ^(0|[-]?[1-9]+[0-9]*)$ ]] && {
		echo "Array index must be a number" 1>&2
		return 1
	}
	declare -n r=$1
	local max=${#r[@]}
	# Array has items and index is in range
	if [[ $max -gt 0 && $i -ge 0 && $i -lt $max ]]; then
		echo ${r[$2]}
	fi
}

# Get the value stored at a specific index eg. ${array[0]}
function arr_count() {
	[[ ! "$1" =~ ^[a-zA-Z_]+[a-zA-Z0-9_]*$ ]] && {
		echo "Invalid bash variable " 1>&2
		return 1
	}
	declare -p "$1" >/dev/null 2>&1
	[[ $? -eq 1 ]] && {
		echo "Bash variable [${1}] doesn't exist" 1>&2
		return 1
	}
	declare -n r=$1
	echo ${#r[@]}
}

array_names=(bob jane dick)

for name in "${array_names[@]}"; do
	arr dyn_$name
done

echo "Arrays Created"
declare -a | grep "a dyn_"

# Insert three items per array
for name in "${array_names[@]}"; do
	echo "Inserting dyn_$name abc"
	arr_insert dyn_$name "abc"
	echo "Inserting dyn_$name def"
	arr_insert dyn_$name "def"
	echo "Inserting dyn_$name ghi"
	arr_insert dyn_$name "ghi"
done

for name in "${array_names[@]}"; do
	echo "Setting dyn_$name[0]=first"
	arr_set dyn_$name 0 "first"
	echo "Setting dyn_$name[2]=third"
	arr_set dyn_$name 2 "third"
done

declare -a | grep 'a dyn_'

for name in "${array_names[@]}"; do
	arr_get dyn_$name
done

for name in "${array_names[@]}"; do
	echo "Dumping dyn_$name by index"
	# Print by index
	for ((i = 0; i < $(arr_count dyn_$name); i++)); do
		echo "dyn_$name[$i]: $(arr_at dyn_$name $i)"

	done
done

for name in "${array_names[@]}"; do
	echo "Dumping dyn_$name"
	for n in $(arr_get dyn_$name); do
		echo $n
	done
done
