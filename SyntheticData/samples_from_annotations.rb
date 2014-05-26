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

	if configR.hasAnnotations
		Dir["#{configR.annotationFolder}/*.xml"].each do |fname|
			# configReader = configR
			# xmlFileName = fname
			threads << Thread.new(configR, fname) { |configReader, xmlFileName|
				begin
					puts "Starting: #{File.basename(xmlFileName,"*")}"
					singleFileOperation = SingleFileOperation.new(configReader)
					singleFileOperation.run_annotated_file(xmlFileName)
					puts "Done: #{File.basename(xmlFileName)}"
				rescue Exception => e
					puts "Error: #{File.basename(xmlFileName)}: #{e.message}"
				end
			}
		end
	else
		inputFolder = configR.imageFolder
		imageFiles = configR.includeSubFolders ? Dir["#{inputFolder}/**/*.png"] : Dir["#{inputFolder}/*.png"]

		imageFiles.each do |fname|
			# configReader = configR
			# imageFileName = fname
			threads << Thread.new(configR, fname) { |configReader, imageFileName|
				begin
					puts "Starting: #{File.basename(imageFileName,"*")}"
					singleFileOperation = SingleFileOperation.new(configReader)
					singleFileOperation.run_non_annotated_file(imageFileName)
					puts "Done: #{File.basename(imageFileName)}"
				rescue Exception => e
					puts "Error: #{File.basename(imageFileName)}: #{e.message}"
				end
			}
		end
	end

	threads.each { |thr| thr.join }
end
