#!/bin/bash

source folder_paths.sh

# Input: test folder with sub-folders corresponding to model classes

usage="./test_patches.sh <testFolder> <gpuId>"

if [ "$1" == "" ]; then
        echo "Incorrect usage. Please specify test folder with sub-folder of patches."
        echo "Results saved here in respective csv files."
        echo $usage
        exit -1;
fi

if [ "$2" == "" ]; then
        echo "Incorrect usage. Please specify GPUID"
        echo $usage
        exit -1;
fi

testFolder=$1

gpuID=$2

for testFolderName in $testFolder/*
do
        testFolderBaseName=$(basename "$testFolderName")
        echo "Scoring $testFolderBaseName ..."
        $PYTHON/get_predictions.py --model_def logo_deploy.prototxt \
                --pretrained_model $FINAL_MODEL_NAME \
                --gpu \
                --gpuId $gpuID \
                --center_only \
                --mean_file $PYTHON/caffe/imagenet/ilsvrc_2012_mean.npy \
                $testFolderName $testFolderBaseName
        echo "Done with $testFolderBaseName."
        sleep 3
done

# center crop on patch, no jiggle
