#!/usr/bin/env ruby

require 'fileutils'
require 'csv'
require 'json'

if __FILE__ == $0
	if ARGV.count < 3
		puts "Combine patch bucket JSON file with score CSV file"
		puts " "
		puts "Usage: ./combine_patch_buckets_with_scores.rb <patch_bucket_folder> <score_file> <output_folder>"
		exit
	end

	patchBucketFolder = ARGV[0]
	scoreFile = ARGV[1]
	outputFolder = ARGV[2]

	FileUtils.mkdir_p(outputFolder)

	puts "Start reading CSV file"
	# read CSV file into a hash
	# format:
	# {filename: [scores], }
	csvHash = {}
	File.foreach(scoreFile).with_index do |line, lineNum|
		# skip header
		next if lineNum == 0

		parsedCSV = CSV.parse(line).first
		fileName = parsedCSV[0].to_s
		csvHash[fileName] = parsedCSV[1..-1]
	end
	puts "Done reading CSV file"

	puts "Working on patch bucket files"
	Dir.glob("#{patchBucketFolder}/*.json") do |jsonFile|
		jsonBaseName = File.basename(jsonFile)
		jsonFileHash = JSON.load(File.open(jsonFile))
		combinedHash = {}
		combinedHash["annotation_id"] = jsonFileHash["annotation_id"]
		combinedHash["patches"] = {}
		jsonFileHash["patches"].each do |patchFileName|
			combinedHash["patches"][patchFileName] = csvHash[patchFileName] || []
		end
		outputFileName = File.join(outputFolder, jsonBaseName)
		File.open(outputFileName,"w") do |f|
			f.write(combinedHash.to_json)
		end
	end
	puts "Done working on patch bucket files"

end
