#!/bin/bash


usage="sudo ./create_swap.sh <swap_size>"

if [ "$1" == "" ]; then
	echo "Incorrect usage. Please specify swap size in MB. Also, run as sudo"
	echo $usage
	exit -1;
fi

# store swap size
swap_size=$1

echo "Creating swap of size $swap_size MB"

dd if=/dev/zero of=/mnt/myswapfile bs=1M count=$swap_size
chmod 600 /mnt/myswapfile
mkswap /mnt/myswapfile
swapon /mnt/myswapfile
swapon -s
free
