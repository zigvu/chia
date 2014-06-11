#!/usr/bin/env ruby

require_relative 'classes/ConfigReader.rb'
require_relative 'classes/NegativePatchCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Create negative patches from non-annotated images"
		puts " "
		puts "Usage: ./create_negative_patches.rb config.yaml inputFolder outputFolder"
		puts " "
		puts "       It is assumed that within the inputFolder, there are images or sub-folders with"
		puts "       images. If images are in sub-folders, then corresponding setting should be set in"
		puts "       config.yaml file. All extracted patches are dumped in outputFolder."
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config)
	npc = NegativePatchCreator.new(configReader, inputFolder, outputFolder)
	npc.create_negative_patches
end
