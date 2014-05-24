#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'shellwords'
require 'active_support/core_ext/hash'
require 'nokogiri'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'XMLReader.rb'
require_relative 'ImageMagick.rb'
require_relative 'AnnotationExtractor.rb'
require_relative 'ConfigReader.rb'

if __FILE__ == $0
	if ARGV.count < 1
		puts "Crop files from annotation for StructSVM training"
		puts " "
		puts "Usage: ./samples_from_annotation.rb config.yaml"
		exit
	end

	config = ARGV[0]

	configR = ConfigReader.new(config)
	threads = []

	Dir["#{configR.annotationFolder}/*.xml"].each do |fname|
		#threads << Thread.new(configR, fname) { |configReader, xmlFileName|
		configReader = configR
		xmlFileName = fname
			begin
				puts "Starting: #{File.basename(xmlFileName,"*")}"
				x = XMLReader.new(
					"#{xmlFileName}", 
					configReader.imageFolder)
				ax = AnnotationExtractor.new(
					x, 
					configReader.className, 
					configReader.tempFolder, 
					configReader.outputFolder)

				# perform task
				if configReader.currentRunName == 'test_positive_patch'
					ax.test_positive_patch(configReader.outputRectangleSize)
				
				elsif configReader.currentRunName == 'test_negative_patch_from_positive'
					ax.test_negative_patch_from_positive(configReader.outputRectangleSize, 
						configReader.numberOfPatchPerImage)
				
				elsif configReader.currentRunName == 'crop_positive_patch'
					ax.crop_positive_patch(configReader.outputRectangleSize)

				elsif configReader.currentRunName == 'crop_negative_patch_from_positive'
					ax.crop_negative_patch_from_positive(configReader.outputRectangleSize, 
						configReader.numberOfPatchPerImage)
				
				else
					puts "Error: Function not yet implemented"
				end
				puts "Done: #{File.basename(xmlFileName)}"
			rescue Exception => e
				puts "Error: #{File.basename(xmlFileName)}: #{e.message}"
			end
		#}
	end

	#threads.each { |thr| thr.join }
end



