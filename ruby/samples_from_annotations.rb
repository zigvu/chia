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
require_relative 'SingleFileOperation.rb'

def run_sample(configReader, inputFileName, isAnnotatedRun)
	begin
		puts "Starting: #{File.basename(inputFileName,"*")}"
		singleFileOperation = SingleFileOperation.new(configReader)
		if isAnnotatedRun
			singleFileOperation.run_annotated_file(inputFileName)
		else
			singleFileOperation.run_non_annotated_file(inputFileName)
		end
		puts "Done: #{File.basename(inputFileName)}"
	rescue Exception => e
		puts "Error: #{File.basename(inputFileName)}: #{e.message}"
	end
end

if __FILE__ == $0
	if ARGV.count < 3
		puts "Crop files from annotation for network training"
		puts " "
		puts "Usage: ./samples_from_annotation.rb config.yaml inputBaseFolder outputBaseFolder"
		puts " "
		puts "       inputBaseFolder is expected to have annotation and images subfolder with names"
		puts "       specified in config.yaml file if we are requiring annotation extraction"
		exit
	end

	config = ARGV[0]
	inputBaseFolder =  ARGV[1]
	outputBaseFolder =  ARGV[2]

	configR = ConfigReader.new(config, inputBaseFolder, outputBaseFolder)
	FileUtils.rm_rf(configR.tempFolder)
	FileUtils.mkdir_p(configR.tempFolder)
	FileUtils.mkdir_p(configR.outputFolder)

	threads = []

	if configR.hasAnnotations
		Dir["#{configR.annotationFolder}/*.xml"].each do |fname|
			if configR.multiThreaded
				threads << Thread.new(configR, fname) { |configReader, xmlFileName|
					run_sample(configReader, xmlFileName, true)
				}
			else
				run_sample(configR, fname, true)
			end
		end
	else
		inputFolder = configR.imageFolder
		imageFiles = configR.includeSubFolders ? Dir["#{inputFolder}/**/*.png"] : Dir["#{inputFolder}/*.png"]

		imageFiles.each do |fname|
			if configR.multiThreaded
				threads << Thread.new(configR, fname) { |configReader, imageFileName|
					run_sample(configReader, imageFileName, false)
				}
			else
				run_sample(configR, fname, false)
			end
		end
	end

	if configR.multiThreaded
		threads.each { |thr| thr.join }
	end
end
