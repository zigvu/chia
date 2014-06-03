#!/bin/bash

source folder_paths.sh

echo "Resume training"

GLOG_logtostderr=1 $TOOLS/train_net.bin \
    logo_solver.prototxt caffe_logo_train_5000.solverstate

echo "Done."
