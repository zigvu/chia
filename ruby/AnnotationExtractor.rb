require 'json'
require 'fileutils'
require 'shellwords'
require 'active_support/core_ext/hash'
require 'nokogiri'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'XMLReader.rb'
require_relative 'ImageMagick.rb'

class AnnotationExtractor
	def initialize(tempFolder, outputFolder)
		@tempFolder = tempFolder
		@outputFolder = outputFolder

		FileUtils.mkdir_p(@tempFolder)
		FileUtils.mkdir_p(@outputFolder)

		@imageMagick = ImageMagick.new
	end

	def initialize_from_xml(xmlReader, className)
		@xmlReader = xmlReader
		@className = className
		@inputFileName = @xmlReader.imageFileName
		@tempFileName = "#{@tempFolder}/#{File.basename(@inputFileName,".*")}_temp.png"
		@xmlImageSize = @xmlReader.imageDimension
	end

	def initialize_from_file(imageFileName)
		@inputFileName = imageFileName
	end

	def test_negative_patch(outputRectangleSize, numberOfPatchPerImage)
		basePolygon = Rectangle.new
		basePolygon.from_dimension(0,0,0,0)
		coordinateMath = CoordinateMath.new
		
		imageSize = @imageMagick.identify(@inputFileName)
		outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_neg_test.png"
		FileUtils.cp(@inputFileName, outputFileName)
		# get candidate patches for negative
		negativePatch = coordinateMath.get_negative_candidate(imageSize, basePolygon, outputRectangleSize)
		counter = 0
		while negativePatch != nil && counter < numberOfPatchPerImage
			@imageMagick.draw_poly(outputFileName, negativePatch, outputFileName, "Negative Crop #{counter}")
			negativePatch = coordinateMath.get_negative_candidate(imageSize, basePolygon, outputRectangleSize)
			counter = counter + 1
		end
	end

	def crop_negative_patch(outputRectangleSize, numberOfPatchPerImage)
		uniqueIdentfier = (0...8).map { (65 + rand(26)).chr }.join
		basePolygon = Rectangle.new
		basePolygon.from_dimension(0,0,0,0)
		coordinateMath = CoordinateMath.new
		
		imageSize = @imageMagick.identify(@inputFileName)
		# get candidate patches for negative
		negativePatch = coordinateMath.get_negative_candidate(imageSize, basePolygon, outputRectangleSize)
		counter = 0
		while negativePatch != nil && counter < numberOfPatchPerImage
			outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_#{uniqueIdentfier}_#{counter}.png"
			@imageMagick.crop(@inputFileName, negativePatch, outputFileName)
			negativePatch = coordinateMath.get_negative_candidate(imageSize, basePolygon, outputRectangleSize)
			counter = counter + 1
		end
	end

	def test_negative_patch_from_positive(outputRectangleSize, numberOfPatchPerImage)
		outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_neg_test_from_pos.png"

		# draw original polygon
		basePolygons = @xmlReader.get_rectangles(@className)
		if basePolygons.count > 1 || basePolygons.count == 0
			raise RuntimeError, "AnnotationExtractor: Skipping file because it has multiple annotations"
		else
			basePolygon = basePolygons.first
		end
		@imageMagick.draw_poly(@inputFileName, basePolygon, outputFileName, 'Base Rectangle')

		# draw the most fitting rectangle
		coordinateMath = CoordinateMath.new
		rectPatch = coordinateMath.poly_to_rectangle(@xmlImageSize, basePolygon)
		@imageMagick.draw_poly(outputFileName, rectPatch, outputFileName, 'Closest Rectangle')

		# get candidate patches for negative
		negativePatch = coordinateMath.get_negative_candidate(@xmlImageSize, rectPatch, outputRectangleSize)
		if negativePatch != nil
			counter = 0
			while negativePatch != nil && counter < numberOfPatchPerImage
				@imageMagick.draw_poly(outputFileName, negativePatch, outputFileName, "Negative Crop #{counter}")
				negativePatch = coordinateMath.get_negative_candidate(@xmlImageSize, rectPatch, outputRectangleSize)
				counter = counter + 1
			end
		else
			rect = Rectangle.new
			rect.from_dimension(0,0,50,30)
			@imageMagick.draw_poly(outputFileName, rect, outputFileName, 'Negative Not Found')
		end
	end

	def crop_negative_patch_from_positive(outputRectangleSize, numberOfPatchPerImage)
		uniqueIdentfier = (0...8).map { (65 + rand(26)).chr }.join

		coordinateMath = CoordinateMath.new
		basePolygons = @xmlReader.get_rectangles(@className)
		if basePolygons.count > 1 || basePolygons.count == 0
			raise RuntimeError, "AnnotationExtractor: Skipping file because it has multiple annotations"
		else
			basePolygon = basePolygons.first
		end
		rectPatch = coordinateMath.poly_to_rectangle(@xmlImageSize, basePolygon)

		# get candidate patches for negative
		counter = 0
		negativePatch = coordinateMath.get_negative_candidate(@xmlImageSize, rectPatch, outputRectangleSize)
		while negativePatch != nil && counter < numberOfPatchPerImage
			outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_#{uniqueIdentfier}_#{counter}.png"
			@imageMagick.crop(@inputFileName, negativePatch, outputFileName)
			negativePatch = coordinateMath.get_negative_candidate(@xmlImageSize, rectPatch, outputRectangleSize)
			counter = counter + 1
		end
	end

	def test_positive_patch(outputRectangleSize)
		outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_pos_test.png"
		FileUtils.cp(@inputFileName, outputFileName)

		# test image sizes:
		imageSizeImageMagick = @imageMagick.identify(@inputFileName)
		if not @xmlImageSize.equals(imageSizeImageMagick)
			raise RuntimeError, "AnnotationExtractor: XML image dimension is incorrect"
		end

		# draw original polygon
		basePolygons = @xmlReader.get_rectangles(@className)
		basePolygons.each_with_index do |basePolygon, index|
			@imageMagick.draw_poly(outputFileName, basePolygon, outputFileName, "Base Rectangle #{index}")

			# draw the most fitting square
			coordinateMath = CoordinateMath.new
			squarePatch = coordinateMath.poly_to_square(@xmlImageSize, basePolygon)
			@imageMagick.draw_poly(outputFileName, squarePatch, outputFileName, "Closest Square #{index}")

			# draw actual area being cut
			cropPatch = coordinateMath.resize_to_match(@xmlImageSize, squarePatch, outputRectangleSize)
			if not cropPatch.is_square?
				raise RuntimeError, "AnnotationExtractor: Couldn't construct a square patch to crop"
			end
			@imageMagick.draw_poly(outputFileName, cropPatch, outputFileName, "Crop Square #{index}")
		end
	end

	def crop_positive_patch(outputRectangleSize)
		uniqueIdentfier = (0...8).map { (65 + rand(26)).chr }.join

		coordinateMath = CoordinateMath.new
		basePolygons = @xmlReader.get_rectangles(@className)
		basePolygons.each_with_index do |basePolygon, index|
			squarePatch = coordinateMath.poly_to_square(@xmlImageSize, basePolygon)
			cropPatch = coordinateMath.resize_to_match(@xmlImageSize, squarePatch, outputRectangleSize)

			outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,".*")}_#{uniqueIdentfier}_#{index}.png"
			@imageMagick.crop(@inputFileName, cropPatch, outputFileName)
		end
	end

	def test_sliding_window(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			downScaleTimes, upScaleTimes, scaleFactor)
		sliding_window(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			downScaleTimes, upScaleTimes, scaleFactor, true)
	end

	def crop_sliding_window(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			downScaleTimes, upScaleTimes, scaleFactor)
		sliding_window(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			downScaleTimes, upScaleTimes, scaleFactor, false)
	end

	def sliding_window(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			downScaleTimes, upScaleTimes, scaleFactor, isTest)
		slidingWindows = []
		originalSize = @imageMagick.identify(@inputFileName)

		# first, run original size
		scale = 1.0
		slidingWindowBoxes = sliding_window_helper(outputRectangleSize, slidingWindowStrideX,
				slidingWindowStrideY, originalSize, scale, isTest)
		slidingWindows << {scale: scale, patches: slidingWindowBoxes}

		# down scale
		for scaleTimes in 1..downScaleTimes
			scale = (1 - scaleFactor * scaleTimes).round(1)
			scaledImageSize = Rectangle.new
			scaledImageSize.from_dimension(0,0, 
				Integer(originalSize.width * scale), Integer(originalSize.height * scale))
			slidingWindowBoxes = sliding_window_helper(outputRectangleSize, slidingWindowStrideX,
				slidingWindowStrideY, scaledImageSize, scale, isTest)
			slidingWindows << {scale: scale, patches: slidingWindowBoxes}
		end

		# up scale
		for scaleTimes in 1..upScaleTimes
			scale = (1 + scaleFactor * scaleTimes).round(1)
			scaledImageSize = Rectangle.new
			scaledImageSize.from_dimension(0,0, 
				Integer(originalSize.width * scale), Integer(originalSize.height * scale))
			slidingWindowBoxes = sliding_window_helper(outputRectangleSize, slidingWindowStrideX,
				slidingWindowStrideY, scaledImageSize, scale, isTest)
			slidingWindows << {scale: scale, patches: slidingWindowBoxes}
		end
		return write_sliding_window_json(slidingWindows)
	end

	def sliding_window_helper(outputRectangleSize, 
			slidingWindowStrideX, slidingWindowStrideY,
			scaledImageSize, scale, isTest)
		coordinateMath = CoordinateMath.new
		slidingWindowBoxes = []
		patchOutputFolder = "#{@outputFolder}/images"
		FileUtils.mkdir_p(patchOutputFolder)

		# make sure new scale is at least as big as outputRectangleSize
		if scaledImageSize.has_larger_area_than?(outputRectangleSize)
			tempFileName = "#{@tempFolder}/#{File.basename(@inputFileName,".*")}_sliding_#{scale}.png"
			@imageMagick.resize(@inputFileName, scaledImageSize, tempFileName)

			bboxes = coordinateMath.sliding_window_boxes(
				scaledImageSize, outputRectangleSize, 
				slidingWindowStrideX, slidingWindowStrideY)

			bboxes.each_with_index do |bbox, index|
				patchFileName = "#{patchOutputFolder}/#{File.basename(tempFileName,".*")}_#{index}.png"
				if isTest
					@imageMagick.draw_poly(tempFileName, bbox, tempFileName, "#{index}")
				else
					@imageMagick.crop(tempFileName, bbox, patchFileName)
				end
				slidingWindowBoxes << {patch_filename: File.basename(patchFileName), patch: bbox.to_hash}
			end
			# if this is test, copy poly-drawn image to right location
			if isTest
				outputFileName = "#{patchOutputFolder}/#{File.basename(@inputFileName,".*")}_sliding_test_#{scale}.png"
				FileUtils.cp(tempFileName, outputFileName)
			end
			FileUtils.rm_rf(tempFileName)
		end
		return slidingWindowBoxes
	end

	def write_sliding_window_json(slidingWindows)
		annotationOutputFolder = "#{@outputFolder}/annotations"
		FileUtils.mkdir_p(annotationOutputFolder)

		outputFileName = "#{annotationOutputFolder}/#{File.basename(@inputFileName,".*")}_sliding.json"
		outputJson = {frame_filename: File.basename(@inputFileName), scales: slidingWindows}

		File.open(outputFileName, 'w') do |file|
			file.puts JSON.pretty_generate(outputJson)
		end
	end
end
