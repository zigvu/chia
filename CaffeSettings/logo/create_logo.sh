#!/bin/bash
# Create leveldb inputs for caffe

source folder_paths.sh

# delete previously made leveldb first
rm -rf logo-leveldb
mkdir -p logo-leveldb

echo "Creating leveldb...train"
GLOG_logtostderr=1 $TOOLS/convert_imageset.bin \
		$INPUT_DATA/train/ \
		$INPUT_DATA/train/train_labels.txt \
		logo-leveldb/logo-train-leveldb 1

echo "Creating leveldb...test"
GLOG_logtostderr=1 $TOOLS/convert_imageset.bin \
		$INPUT_DATA/test/ $INPUT_DATA/test/test_labels.txt \
		logo-leveldb/logo-test-leveldb 1

# Warning: we use the imagenet mean image
#          so don't use this
# echo "Computing image mean..."
# GLOG_logtostderr=1 $TOOLS/compute_image_mean.bin \
# 		logo-leveldb/logo-train-leveldb \
# 		logo-mean.binaryproto

echo "Done creating leveldb"
