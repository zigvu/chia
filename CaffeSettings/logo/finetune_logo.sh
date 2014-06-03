#!/bin/bash

source folder_paths.sh

echo "Fine tuning net from imagenet reference model"

GLOG_logtostderr=1 $TOOLS/finetune_net.bin logo_solver.prototxt $REFERENCE_MODEL

echo "Done fine tuning net"
