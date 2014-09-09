#!/usr/bin/env ruby

require 'fileutils'
require 'json'

if __FILE__ == $0
	if ARGV.count < 4
		puts "Rename logo name in JSON output from video_annotation tool"
		puts " "
		puts "Usage: ./rename_logo_in_json.rb inputJSONFolder outputJSONFolder \"oldLogoName\" \"newLogoName\""
		puts " "
		puts "       Note that for bash to not expand provided arguments, both oldLogoName"
		puts "       and new newLogoName should be enclosed in quotation marks"
		exit
	end

	inputJSONFolder = ARGV[0]
	outputJSONFolder = ARGV[1]
	oldLogoName = ARGV[2]
	newLogoName = ARGV[3]

	FileUtils.mkdir_p(outputJSONFolder)

	Dir["#{inputJSONFolder}/*.json"].each do |fname|
		origJSON = JSON.parse(IO.read(fname))
		newJSON = JSON.parse(IO.read(fname))
		newJSON["annotations"].each do |k, v|
			if oldLogoName == k
				origJSON["annotations"][newLogoName] = v
				origJSON["annotations"].delete(k)
			end
		end
		# Save file
		File.open("#{outputJSONFolder}/#{File.basename(fname)}", 'w') do |file|
			file.puts JSON.pretty_generate(origJSON)
		end
	end

end
