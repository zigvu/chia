#!/usr/bin/env ruby

require_relative 'classes/ConfigReader.rb'
require_relative 'classes/NegativePatchFromPositiveCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Create negative patches from non-annotated images"
		puts " "
		puts "Usage: ./create_negative_patches.rb config.yaml inputFolder outputFolder"
		puts " "
		puts "       It is assumed that within the inputFolder, there are images and annotations"
		puts "       folders as specified in config.yaml file."
		puts "       All extracted patches are dumped in outputFolder."
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config)
	annotationsFolder = "#{inputFolder}/#{configReader.npfp_AnnotationsFolder}"
	imagesFolder = "#{inputFolder}/#{configReader.npfp_ImagesFolder}"
	npfpc = NegativePatchFromPositiveCreator.new(configReader, annotationsFolder, imagesFolder, outputFolder)
	npfpc.create_negative_patches
end
