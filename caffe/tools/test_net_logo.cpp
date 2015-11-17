// Derived from test_net.cpp by Evan on 8/24/2015

#include <cuda_runtime.h>

#include <cstring>
#include <cstdlib>
#include <vector>
#include <fstream>
#include <iostream>
#include <sstream>
#include <time.h>
#include <math.h>

#include "caffe/caffe.hpp"

using namespace caffe;  // NOLINT(build/namespaces)

int main(int argc, char** argv) {
  if (argc < 5 || argc > 7) {
    LOG(ERROR) << "test_net net_proto pretrained_net_proto leveldb_label_file output_csv"
        << "[CPU/GPU] [Device ID]";
    return 1;
  }
  time_t timerBegin;
  time_t timerEnd;
  double totalTime;
  time(&timerBegin);

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
  int outputLayerNumOutputs = caffe_test_net.blob_by_name("prob")->channels();
  int batchSize = caffe_test_net.blob_by_name("prob")->num();

  // get number of iterations
  int numberOfPatchesToEvaluate = 0;
  std::string readLine;
  std::ifstream patchFileRead(argv[3]);
  while (std::getline(patchFileRead, readLine)){
    ++numberOfPatchesToEvaluate;
  }
  int total_iter = ceil((1.0 * numberOfPatchesToEvaluate + 1)/batchSize);

  LOG(ERROR) << "Total num of patches: " << numberOfPatchesToEvaluate << 
    " ; Running " << total_iter << " iterations.";

  // write to CSV output
  std::ofstream csvFile;
  csvFile.open (argv[4]);
  char csvFirstLine[1024] = "Class";
  for (int j = 0; j < outputLayerNumOutputs; j++) {
    sprintf(csvFirstLine, "%s,%d", csvFirstLine, j);
  }
  csvFile << csvFirstLine << std::endl;

  // open the file again to put in file name in begining of output
  std::ifstream patchFile(argv[3]);
  std::string patchFileName;

  for (int i = 0; i < total_iter; ++i) {
    const vector<Blob<float>*>& result = caffe_test_net.ForwardPrefilled();
    const vector<Blob<float>*>& softMaxLayerBlob = caffe_test_net.top_vecs()[ 23 ];

    for (int k = 0; k < softMaxLayerBlob[0]->num(); k++) {
      if(std::getline(patchFile, readLine)){
        std::stringstream ss(readLine);
        ss >> patchFileName;
        size_t sep = patchFileName.find_last_of("\\/");
        patchFileName = patchFileName.substr(sep + 1, patchFileName.size() - sep - 1);

        char csvLine[1024];
        sprintf(csvLine, "%s", patchFileName.c_str());
        for (int j = 0; j < outputLayerNumOutputs; j++) {
          sprintf(csvLine, "%s,%f", csvLine, softMaxLayerBlob[0]->cpu_data()[ outputLayerNumOutputs * k + j ]);
        }
        csvFile << csvLine << std::endl;
        LOG(ERROR) << csvLine;
      }
    }
  }

  time(&timerEnd);
  totalTime = difftime(timerEnd, timerBegin);
  LOG(ERROR) << "Total time spent: " << totalTime;

  return 0;
}

