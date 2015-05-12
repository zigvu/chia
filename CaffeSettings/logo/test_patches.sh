#!/bin/bash

source folder_paths.sh

# Input: folder of patches to test

usage="./test_patches.sh <testFolderName> <gpuId>"

if [ "$1" == "" ]; then
	echo "Incorrect usage. Please specify testFolderName"
	echo $usage
	exit -1;
fi

if [ "$2" == "" ]; then
	echo "Incorrect usage. Please specify GPUID"
	echo $usage
	exit -1;
fi

testFolderName=$1
testFolderBaseName=$(basename "$testFolderName")

gpuID=$2

$PYTHON/get_predictions.py --model_def logo_deploy.prototxt \
		--pretrained_model $FINAL_MODEL_NAME \
		--gpu \
		--gpuId $gpuID \
		--mean_file $PYTHON/caffe/imagenet/ilsvrc_2012_mean.npy \
		$testFolderName $testFolderBaseName

echo "Done."
