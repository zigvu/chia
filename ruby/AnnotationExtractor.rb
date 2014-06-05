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
end
