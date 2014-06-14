require 'fileutils'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'ImageMagick.rb'

class NegativePatchCreator

	def initialize(configReader, inputFolder, outputFolder)
		@configReader = configReader
		@inputFolder = inputFolder
		@outputFolder = outputFolder
		@tempFolder = configReader.tempFolder

		FileUtils.mkdir_p(@outputFolder)
		FileUtils.mkdir_p(@tempFolder)

		@isTest = configReader.np_isTest
		@numPatchPerImage = configReader.np_NumPatchPerImage
		@outputRectangleSize = configReader.outputRectangleSize

		@imageMagick = ImageMagick.new
		@coordinateMath = CoordinateMath.new
		@basePolygon = Rectangle.new
		@basePolygon.from_dimension(0,0,0,0)
	end

	def create_negative_patches
		allInputFiles = @configReader.np_IncludeSubFolders ? Dir["#{@inputFolder}/**/*.png"] : Dir["#{@inputFolder}/*.png"]
		if @configReader.multiThreaded
			allInputFiles.each_slice(@configReader.numOfProcessors * 2) do |group|
				group.map do |inputFileName|
					Thread.new do
						patch_single_file(inputFileName)
					end
				end.each(&:join)
			end
		else
			allInputFiles.each do |inputFileName|
				patch_single_file(inputFileName)
			end
		end
	end

	def patch_single_file(inputFileName)
		puts "Starting #{File.basename(inputFileName)}..."
		begin
			draw_all_patches(inputFileName)
			puts "Done #{File.basename(inputFileName)}"
		rescue Exception => e
			puts "Error: #{File.basename(inputFileName)}: #{e.message}"
		end
	end

	def draw_all_patches(inputFileName)
		tmpFile = "#{@tempFolder}/#{File.basename(inputFileName, '.*')}.png"
		outputFileName = "#{@outputFolder}/#{File.basename(inputFileName, '.*')}_np.png"

		FileUtils.cp(inputFileName, tmpFile)
		imageSize = @imageMagick.identify(tmpFile)

		patchCandidates = @coordinateMath.get_negative_candidates(imageSize, @basePolygon, 
			@outputRectangleSize, @numPatchPerImage)
		patchCandidates.each_with_index do |cropPatch, pidx|
			# breaking conditions
		 	if pidx >= @numPatchPerImage
		 		break
		 	end
			draw_single_patch(tmpFile, cropPatch, tmpFile, pidx)
		end

		if @isTest
			FileUtils.mv(tmpFile, outputFileName)
		else
			FileUtils.rm(tmpFile)
		end
	end

	def draw_single_patch(inputFileName, rectangle, outputFileName, counter)
		if @isTest
			@imageMagick.draw_poly(inputFileName, rectangle, outputFileName, "Negative Crop #{counter}")
		else
			outputFileName = "#{@outputFolder}/#{File.basename(inputFileName, '.*')}_np_#{counter}.png"
			@imageMagick.crop(inputFileName, rectangle, outputFileName)
		end
	end

end
