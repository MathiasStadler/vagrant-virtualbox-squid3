#!/bin/bash

# ATTENTION !!!
# precondition for this script
# the output of the command
# VBoxManage showvminfo #{VM_NAME} --machinereadable
# is available
# I provide this info with a file provider the guest
# the info is stored in
# /home/vagrant/vm.info

# Exit immediately if a command returns a non-zero status
set -e

# set VM_INFO_FILE variable
readonly VM_INFO_FILE="/home/vagrant/vm.info"

# check if vm.info available
if ! [ -e "${VM_INFO_FILE}" ]; then
	echo "ERROR File ${VM_INFO_FILE} NOT available"
	exit 0
fi

# parse vm.info for the number of first bridge network adapter
# SC2002 Error readonly NUMBER_OF_NETWORK_ADAPTER=$(cat ${VM_INFO_FILE} | grep bridged | sed 's/=.*//' | sed 's/.*\(.\)/\1/')
# fix
readonly NUMBER_OF_NETWORK_ADAPTER=$(grep <${VM_INFO_FILE} bridged | sed 's/=.*//' | sed 's/.*\(.\)/\1/')

# parse vm.info for MAC of the network adapter
# readonly MAC_ADDRESS_OF_NETWORK_ADAPTER=$(cat vm.info |grep "macaddress${NUMBER_OF_NETWORK_ADAPTER}"|sed 's/.*=//'|sed 's/"//g')
# grep field macaddress |grep value |add double point each two sign|remove last sign
# SC2002 ERROR readonly MAC_ADDRESS_ADAPTER=$(cat vm.info | grep "macaddress${NUMBER_OF_NETWORK_ADAPTER}" | sed 's/.*=//' | sed 's/"//g' | sed 's/.\{2\}/&:/g' | sed 's/.$//')
# fix
readonly MAC_ADDRESS_ADAPTER=$(grep <${VM_INFO_FILE} "macaddress${NUMBER_OF_NETWORK_ADAPTER}" | sed 's/.*=//' | sed 's/"//g' | sed 's/.\{2\}/&:/g' | sed 's/.$//')

# parse adapter
readonly INTERFACE=$(ip -o link | grep -i "${MAC_ADDRESS_ADAPTER}" | awk '{print $2}' | sed 's/.$//')

# parse ip of bridge adapter
readonly IP=$(ip -o address | grep eth1 | awk '{print $4}' | ip -o address | grep "${INTERFACE}" | awk '{print $4}' | sed 's#/.*##')

# Classless Inter-Domain Routing
readonly CIDR=$(ip -o address | grep eth1 | awk '{print $4}' | ip -o address | grep "${INTERFACE}" | awk '{print $4}' | sed 's#.*/##')

# netmask
# from here
# https://stackoverflow.com/questions/20762575/explanation-of-convertor-of-cidr-to-netmask-in-linux-shell-netmask2cdir-and-cdir

mask2cdr() {
	# Assumes there's no "255." after a non-255 byte in the mask
	local x=${1##*255.}
	set -- 0^^^128^192^224^240^248^252^254^ $(((${#1} - ${#x}) * 2)) "${x%%.*}"
	x=${1%%$3*}
	echo $(($2 + (${#x} / 4)))
}

cdr2mask() {
	# Number of args to shift, 255..255, first non-255 byte, zeroes
	set -- $((5 - ($1 / 8))) 255 255 255 255 $(((255 << (8 - ($1 % 8))) & 255)) 0 0 0
	#	[ "$1" -gt 1 ] && shift "$1" || shift
	if [ "$1" -gt 1 ]; then shift "$1"; else shift; fi
	echo "${1-0}.${2-0}.${3-0}.${4-0}"
}

readonly NETMASK=$(cdr2mask "${CIDR}")

echo "${IP}" >/home/vagrant/vm.bridge.ip
echo "${INTERFACE}" >/home/vagrant/vm.bridge.interface

echo "First bridge interface of vm"
echo "Interface ${INTERFACE}"
echo "MAC address ${MAC_ADDRESS_ADAPTER}"
echo "IP ${IP}"
echo "CIDR ${CIDR}"
echo "NETMASK ${NETMASK}"
