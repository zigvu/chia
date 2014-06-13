require 'json'
require 'fileutils'
require 'shellwords'
require 'active_support/core_ext/hash'
require 'nokogiri'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'ImageMagick.rb'

class SlidingWindowCreator

	def initialize(configReader, inputFolder, patchFolder, annotationFolder)
		@inputFolder = inputFolder
		@tempFolder = configReader.tempFolder

		FileUtils.mkdir_p(@tempFolder)

		@configReader = configReader
		@isTest = configReader.sw_isTest
		@patchSize = configReader.outputRectangleSize
		@sw_StrideX = configReader.sw_StrideX
		@sw_StrideY = configReader.sw_StrideY
		@sw_downScaleTimes = configReader.sw_downScaleTimes
		@sw_upScaleTimes = configReader.sw_upScaleTimes
		@sw_scaleFactor = configReader.sw_scaleFactor

		@patchFolder = patchFolder
		@annotationFolder = annotationFolder
		FileUtils.mkdir_p(@patchFolder)
		FileUtils.mkdir_p(@annotationFolder)

		@imageMagick = ImageMagick.new
	end

	def generate_sliding_windows
		allInputFiles = Dir["#{@inputFolder}/*.png"]
		if @configReader.multiThreaded
			allInputFiles.each_slice(@configReader.numOfProcessors * 2) do |group|
				group.map do |inputFileName|
					Thread.new do
						slide_single_image(inputFileName)
					end
				end.each(&:join)
			end
		else
			allInputFiles.each do |inputFileName|
				slide_single_image(inputFileName)
			end
		end
	end

	def slide_single_image(inputFileName)
		puts "Starting #{File.basename(inputFileName)}..."
		sliding_window(inputFileName)
		puts "Done #{File.basename(inputFileName)}"
	end

	def sliding_window(inputFileName)
		slidingWindows = []
		originalSize = @imageMagick.identify(inputFileName)

		# first, run original size
		scale = 1.0
		sw_Boxes = sliding_window_helper(inputFileName, originalSize, scale)
		slidingWindows << {scale: scale, patches: sw_Boxes}

		# down scale
		for scaleTimes in 1..@sw_downScaleTimes
			scale = (1 - @sw_scaleFactor * scaleTimes).round(1)
			scaledImageSize = Rectangle.new
			scaledImageSize.from_dimension(
				0,0, 
				Integer(originalSize.width * scale), Integer(originalSize.height * scale))
			
			sw_Boxes = sliding_window_helper(inputFileName, scaledImageSize, scale)
			slidingWindows << {scale: scale, patches: sw_Boxes}
		end

		# up scale
		for scaleTimes in 1..@sw_upScaleTimes
			scale = (1 + @sw_scaleFactor * scaleTimes).round(1)
			scaledImageSize = Rectangle.new
			scaledImageSize.from_dimension(
				0,0, 
				Integer(originalSize.width * scale), Integer(originalSize.height * scale))
			
			sw_Boxes = sliding_window_helper(inputFileName, scaledImageSize, scale)
			slidingWindows << {scale: scale, patches: sw_Boxes}
		end
		return write_sliding_window_json(inputFileName, slidingWindows)
	end

	def sliding_window_helper(inputFileName, scaledImageSize, scale)
		coordinateMath = CoordinateMath.new
		sw_Boxes = []

		# make sure new scale is at least as big as outputRectangleSize
		if scaledImageSize.has_larger_area_than?(@patchSize)
			tempFileName = "#{@tempFolder}/#{File.basename(inputFileName,".*")}_scl_#{scale}.png"
			@imageMagick.resize(inputFileName, scaledImageSize, tempFileName)

			bboxes = coordinateMath.sliding_window_boxes(
				scaledImageSize, @patchSize, @sw_StrideX, @sw_StrideY)

			bboxes.each_with_index do |bbox, index|
				patchFileName = "#{@patchFolder}/#{File.basename(tempFileName,".*")}_idx_#{index}.png"
				if @isTest
					@imageMagick.draw_poly(tempFileName, bbox, tempFileName, "#{index}")
				else
					@imageMagick.crop(tempFileName, bbox, patchFileName)
				end
				sw_Boxes << {patch_filename: File.basename(patchFileName), patch: bbox.to_hash}
			end
			# if this is test, copy poly-drawn image to right location
			if @isTest
				outputFileName = "#{@patchFolder}/#{File.basename(inputFileName,".*")}_scl_#{scale}.png"
				FileUtils.cp(tempFileName, outputFileName)
			end
			FileUtils.rm_rf(tempFileName)
		end
		return sw_Boxes
	end

	def write_sliding_window_json(inputFileName, slidingWindows)
		outputFileName = "#{@annotationFolder}/#{File.basename(inputFileName,".*")}.json"
		outputJson = {
			annotation_filename: File.basename(outputFileName),
			frame_filename: File.basename(inputFileName),
			frame_number: Integer(File.basename(inputFileName,".*").split("_frame_")[1]),
			scales: slidingWindows}

		File.open(outputFileName, 'w') do |file|
			file.puts JSON.pretty_generate(outputJson)
		end
	end
end
