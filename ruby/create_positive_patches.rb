#!/usr/bin/env ruby

require_relative 'classes/ConfigReader.rb'
require_relative 'classes/PositivePatchCreator.rb'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Create positive patches from annotated images"
		puts " "
		puts "Usage: ./create_positive_patches.rb config.yaml inputFolder outputFolder"
		puts " "
		puts "       It is assumed that within the inputFolder, there are images and annotations"
		puts "       folders as specified in config.yaml file."
		puts "       Patches generated from each object class in annotation file will be stored"
		puts "       in separate folder in outputFolder."
		exit
	end

	config = ARGV[0]
	inputFolder = ARGV[1]
	outputFolder = ARGV[2]

	configReader = ConfigReader.new(config)
	annotationsFolder = "#{inputFolder}/#{configReader.pp_AnnotationsFolder}"
	imagesFolder = "#{inputFolder}/#{configReader.pp_ImagesFolder}"
	ppc = PositivePatchCreator.new(configReader, annotationsFolder, imagesFolder, outputFolder)
	ppc.create_positive_patches
end
