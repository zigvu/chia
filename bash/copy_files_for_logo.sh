#!/bin/bash


usage="sudo ./copy_files_for_logo.sh <outputFolder>"

if [ "$1" == "" ]; then
	echo "Incorrect usage. Please specify outputFolder"
	echo $usage
	exit -1;
fi

outputFolder=$1

echo "Copying files to $outputFolder"

cp -R ../CaffeSettings $outputFolder/.
cp -R ../python $outputFolder/.
cp -R ../ruby $outputFolder

echo "Done copying all files"
