#!/usr/bin/env sh

# you can point this to whereever the input data currently resides - use absolute path
INPUT_DATA=input

# Change the last number to indicate how many iterations are run in training phase
FINAL_MODEL_NAME=caffe_logo_train_iter_5000

# Caffe paths - do NOT change - changing here will conflict with prototxt paths
CAFFE_ROOT=/home/ubuntu/chia/caffe
TOOLS=$CAFFE_ROOT/build/tools
PYTHON=$CAFFE_ROOT/python
REFERENCE_MODEL=$CAFFE_ROOT/examples/imagenet/caffe_reference_imagenet_model
