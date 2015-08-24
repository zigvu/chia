#!/usr/bin/env ruby

require_relative 'classes/ConfigReader.rb'
require_relative 'classes/DatasetCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Create data set for caffe training/testing"
		puts " "
		puts "Usage: ./create_dataset_split.rb config.yaml inputFolder outputFolder"
		puts " "
		puts "       If the 'dataset_type' is set to 'split_data' in config file, then each folder"
		puts "       within the data folder is treated as a separate class and the dataset is"
		puts "       divided into train/val/test portions."
		puts "       If the 'dataset_type' mode is set to 'train_test' in config file, then two"
		puts "       folders - train and test - are expected inside inputFolder and the subfolders"
		puts "       of these are assumed to be separate classes."
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config)
	dc = DatasetCreator.new(inputFolder, outputFolder, configReader)

	if configReader.datasetTypeSplitData
		datasetSplit = configReader.datasetSplit	
		dc.split_for_caffe(datasetSplit[:train], datasetSplit[:val], datasetSplit[:test])
	elsif configReader.datasetTypeTrainTest
		dc.create_label_for_caffe
	elsif configReader.datasetTypeTestOnly
		dc.create_test_lables
	else
		raise RuntimeError, "The config specified in config.yaml hasn't been implemented"
	end
end
