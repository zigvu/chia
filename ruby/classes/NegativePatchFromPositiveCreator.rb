require 'fileutils'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'ImageMagick.rb'
require_relative 'XMLReader.rb'

class NegativePatchFromPositiveCreator

	def initialize(configReader, annotationsFolder, imagesFolder, outputFolder)
		@configReader = configReader
		@annotationsFolder = annotationsFolder
		@imagesFolder = imagesFolder
		@outputFolder = outputFolder
		@tempFolder = configReader.tempFolder

		FileUtils.mkdir_p(@outputFolder)
		FileUtils.mkdir_p(@tempFolder)

		@isTest = configReader.npfp_isTest
		@numPatchPerImage = configReader.npfp_NumPatchPerImage
		@outputRectangleSize = configReader.outputRectangleSize

		@imageMagick = ImageMagick.new
		@coordinateMath = CoordinateMath.new
	end

	def create_negative_patches
		allInputFiles = Dir["#{@annotationsFolder}/*.xml"]
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

	def patch_single_file(inputAnnotation)
		puts "Starting #{File.basename(inputAnnotation)}..."
		begin
			draw_all_objects(inputAnnotation)
			puts "Done #{File.basename(inputAnnotation)}"
		rescue Exception => e
			puts "Error: #{File.basename(inputAnnotation)}: #{e.message}"
		end
	end

	def draw_all_objects(inputAnnotation)
		xmlReader = XMLReader.new(inputAnnotation, @imagesFolder)
		inputFileName = xmlReader.imageFileName
		xmlImageSize = xmlReader.imageDimension

		basePolygons = []
		allObjects = xmlReader.get_object_names
		allObjects.each do |objName|
			objRects = xmlReader.get_rectangles(objName)
			basePolygons = basePolygons + objRects if objRects != nil
		end
		if basePolygons.count != 1
			raise RuntimeError, "AnnotationExtractor: Skipping file because it has multiple annotations"
		else
			basePolygon = basePolygons.first
		end
		objRectangle = @coordinateMath.poly_to_rectangle(xmlImageSize, basePolygon)
		draw_all_patches(objRectangle, inputFileName, xmlImageSize)
	end

	def draw_all_patches(objRectangle, inputFileName, imageSize)
		tmpFile = "#{@tempFolder}/#{File.basename(inputFileName, '.*')}.png"
		outputFileName = "#{@outputFolder}/#{File.basename(inputFileName, '.*')}_npfp.png"

		FileUtils.cp(inputFileName, tmpFile)

		# sample in high density and keep those closest to objRectangle - giving the same patches - so not using
		patchCandidates = @coordinateMath.get_negative_candidates(imageSize, objRectangle, 
			@outputRectangleSize, @numPatchPerImage)
		#patchCandidates = @coordinateMath.order_by_distance(patchCandidates, objRectangle)
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
			outputFileName = "#{@outputFolder}/#{File.basename(inputFileName, '.*')}_npfp_#{counter}.png"
			@imageMagick.crop(inputFileName, rectangle, outputFileName)
		end
	end

end
