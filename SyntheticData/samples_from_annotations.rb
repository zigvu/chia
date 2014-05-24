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

	Dir["#{configR.positiveAnnotationFolder}/*.xml"].each do |fname|
		threads << Thread.new(configR, fname) { |configReader, xmlFileName|
			begin
				puts "Starting: #{File.basename(xmlFileName,"*")}"
				x = XMLReader.new(
					"#{xmlFileName}", 
					configReader.positiveImageFolder)
				ax = AnnotationExtractor.new(
					x, 
					configReader.className, 
					configReader.tempFolder, 
					configReader.testRunResults)

				# perform task
				if configReader.runType == 'test_positive_patch'
					ax.test_positive_patch(configReader.outputRectangleSize)
				elsif configReader.runType == 'crop_positive_patch'
					ax.extract_positive_patch(configReader.outputRectangleSize)
				end
				puts "Done: #{File.basename(xmlFileName)}"
			rescue Exception => e
				puts "Error: #{File.basename(xmlFileName)}: #{e.message}"
			end
		}
	end

	threads.each { |thr| thr.join }
end



