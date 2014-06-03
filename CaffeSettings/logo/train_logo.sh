#!/bin/bash

source folder_paths.sh

GLOG_logtostderr=1 $TOOLS/train_net.bin logo_solver.prototxt

echo "Done."
