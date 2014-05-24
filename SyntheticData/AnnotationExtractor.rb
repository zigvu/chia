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
	def initialize(xmlReader, className, tempFolder = '/tmp/magick', outputFolder = '/tmp/magick')
		@xmlReader = xmlReader
		@className = className
		@tempFolder = tempFolder
		@outputFolder = outputFolder

		FileUtils.mkdir_p(@tempFolder)
		FileUtils.mkdir_p(@outputFolder)

		@imageMagick = ImageMagick.new
		@inputFileName = @xmlReader.imageFileName
		@tempFileName = "#{@tempFolder}/#{File.basename(@inputFileName,"*")}_temp.png"
	end

	def test_positive_patch(outputRectangleSize)
		outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,"*")}_test.png"

		# test image sizes:
		xmlImageSize = @xmlReader.imageDimension
		imageSizeImageMagick = @imageMagick.identify(@inputFileName)
		if not xmlImageSize.equals(imageSizeImageMagick)
			raise RuntimeError, "AnnotationExtractor: XML image dimension is incorrect"
		end

		# draw original polygon
		basePolygon = @xmlReader.get_rectangle(@className)
		@imageMagick.draw_poly(@inputFileName, basePolygon, outputFileName, 'Base Rectangle')

		# draw the most fitting square
		coordinateMath = CoordinateMath.new
		squarePatch = coordinateMath.poly_to_square(xmlImageSize, basePolygon)
		@imageMagick.draw_poly(outputFileName, squarePatch, outputFileName, 'Closest Square')

		# draw actual area being cut
		cropPatch = coordinateMath.resize_to_match(xmlImageSize, squarePatch, outputRectangleSize)
		if not cropPatch.is_square?
			raise RuntimeError, "AnnotationExtractor: Couldn't construct a square patch to crop"
		end
		@imageMagick.draw_poly(outputFileName, cropPatch, outputFileName, 'Crop Square')
	end

	def extract_positive_patch(outputRectangleSize)
		xmlImageSize = @xmlReader.imageDimension
		uniqueIdentfier = (0...8).map { (65 + rand(26)).chr }.join

		coordinateMath = CoordinateMath.new
		basePolygon = @xmlReader.get_rectangle(@className)
		squarePatch = coordinateMath.poly_to_square(xmlImageSize, basePolygon)
		cropPatch = coordinateMath.resize_to_match(xmlImageSize, squarePatch, outputRectangleSize)

		outputFileName = "#{@outputFolder}/#{File.basename(@inputFileName,"*")}_#{uniqueIdentfier}.png"
		@imageMagick.crop(@inputFileName, cropPatch, outputFileName)
	end
end
