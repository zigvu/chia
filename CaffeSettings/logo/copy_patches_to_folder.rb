#!/usr/bin/env ruby

require 'fileutils'
require 'shellwords'

if __FILE__ == $0
	if ARGV.count < 4
		puts "Copy files of particular class from inputFolder to outputFolder"
		puts " "
		puts "Usage: ./copy_patches_to_folder.rb classificationFile.csv <classInteger> inputFolder outputFolder"
		puts " "
		puts "       classificationFile.csv: file with the classification result on inputFolder patches"
		puts "       <classInteger>         : integer indicating the class as given by label_mappings.txt in training"
		puts "       inputFolder            : folder with patches that was evaluated to get classificationFile.csv"
		puts "       outputFolder           : folder where patches that have <classInteger> class will be saved"
		exit
	end

	classificationFile = ARGV[0]
	classInteger =  Integer(ARGV[1])
	inputFolder =  ARGV[2]
	outputFolder =  ARGV[3]
	FileUtils.mkdir_p(outputFolder)

	lineCount = 0
	classCount = 0
	File.open(classificationFile, 'r').each_line do |line|
		cleanLine = line.delete(' ').split(',')
		next if cleanLine[1] == nil
		# format from get_predictions.py file
		fileName = cleanLine[0]
		predScore = Float(cleanLine[1])
		predClass = Integer(cleanLine[2])

		if predClass == classInteger
			puts "Copying file #{fileName}"
			FileUtils.cp("#{inputFolder}/#{fileName}","#{outputFolder}")
			classCount = classCount + 1
		end
		lineCount = lineCount + 1
	end

	puts "Total Patch Count: #{lineCount}, Class #{classInteger} Patch Count: #{classCount}"
end
