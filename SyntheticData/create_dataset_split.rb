#!/usr/bin/env ruby

require_relative 'ConfigReader.rb'
require_relative 'DatasetCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Create data set for caffe training/testing"
		puts " "
		puts "Usage: ./create_dataset_split.rb config.yaml inputFolder outputFolder"
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config)
	datasetSplit = configReader.datasetSplit

	dc = DatasetCreator.new(inputFolder, outputFolder)
	dc.split_for_caffe(datasetSplit[:train], datasetSplit[:val], datasetSplit[:test])
end
