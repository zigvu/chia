#!/usr/bin/env ruby

require_relative 'ConfigReader.rb'
require_relative 'DatasetCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Evaluate extracted frames from video"
		puts " "
		puts "Usage: ./evaluate_video_frames.rb config.yaml inputFolder outputFolder"
		puts " "
		puts "       inputFolder has two sub folders - images and annotations that correspond to"
		puts "       bounding boxes created in sliding window process"
		puts "       All results will be saved in various sub-directories of outputFolder"
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config, inputFolder, outputFolder)

	
end
