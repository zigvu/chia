// Finangled by Evan on 6/11


// Copyright 2014 BVLC and contributors.
//
// This is a simple script that allows one to quickly test a network whose
// structure is specified by text format protocol buffers, and whose parameter
// are loaded from a pre-trained network.
// Usage:
//    test_net net_proto pretrained_net_proto iterations [CPU/GPU]

#include <cuda_runtime.h>

#include <cstring>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <iostream>

#include "caffe/caffe.hpp"

using namespace caffe;  // NOLINT(build/namespaces)

int main(int argc, char** argv) {
  if (argc < 5 || argc > 7) {
    LOG(ERROR) << "test_net net_proto pretrained_net_proto iterations output_csv"
        << "[CPU/GPU] [Device ID]";
    return 1;
  }

  Caffe::set_phase(Caffe::TEST);

  if (argc >= 6 && strcmp(argv[5], "GPU") == 0) {
    Caffe::set_mode(Caffe::GPU);
    int device_id = 0;
    if (argc == 7) {
      device_id = atoi(argv[5]);
    }
    Caffe::SetDevice(device_id);
    LOG(ERROR) << "Using GPU #" << device_id;
  } else {
    LOG(ERROR) << "Using CPU";
    Caffe::set_mode(Caffe::CPU);
  }

  Net<float> caffe_test_net(argv[1]);
  caffe_test_net.CopyTrainedLayersFrom(argv[2]);
  int outputLayerNumOutputs = caffe_test_net.num_outputs();

  int total_iter = atoi(argv[3]);
  LOG(ERROR) << "Running " << total_iter << " iterations.";

  std::ofstream csvFile;
  csvFile.open (argv[4]);
  // char csvFirstLine[1024] = "Class";
  // for (int j = 0; j < outputLayerNumOutputs; j++) {
  //   sprintf(csvFirstLine, "%s,%d", csvFirstLine, j);
  // }
  // csvFile << csvFirstLine << std::endl;

  int counter = 0;
  for (int i = 0; i < total_iter; ++i) {
    const vector<Blob<float>*>& result = caffe_test_net.ForwardPrefilled();
    const vector<Blob<float>*>& softMaxLayerBlob = caffe_test_net.top_vecs()[ 23 ];

    for (int k = 0; k < softMaxLayerBlob[0]->num(); k++) {
      char csvLine[1024];
      sprintf(csvLine, "%d", counter++);
      for (int j = 0; j < outputLayerNumOutputs; j++) {
        sprintf(csvLine, "%s,%f", csvLine, softMaxLayerBlob[0]->cpu_data()[ 2 * k + j ]);
      }
      csvFile << csvLine << std::endl;
      LOG(ERROR) << csvLine;
    }
  }
  csvFile.close();

  return 0;
}

