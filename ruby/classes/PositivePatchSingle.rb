require 'fileutils'

require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'XMLReader.rb'
require_relative 'ImageMagick.rb'

class PositivePatchSingle
	def initialize(configReader, inputAnnotation, imageFolder, outputFolder)		
		@tempFolder = configReader.tempFolder
		@outputFolder = outputFolder

		FileUtils.mkdir_p(@tempFolder)
		FileUtils.mkdir_p(@outputFolder)

		@configReader = configReader
		@isTest = configReader.pp_isTest
		@outputRectangleSize = configReader.outputRectangleSize

		@pp_minObjectAreaFraction = configReader.pp_minObjectAreaFraction

		@pp_tx_jigglesFraction = configReader.pp_tx_jigglesFraction
		@pp_tx_maxNumJiggles = configReader.pp_tx_maxNumJiggles
		@pp_tx_minPixelMove = configReader.pp_tx_minPixelMove
		@pp_tx_downScaleTimes = configReader.pp_tx_downScaleTimes
		@pp_tx_upScaleTimes = configReader.pp_tx_upScaleTimes
		@pp_tx_scaleFactor = configReader.pp_tx_scaleFactor

		@xmlReader = XMLReader.new(inputAnnotation, imageFolder)
		@inputFileName = @xmlReader.imageFileName
		@xmlImageSize = @xmlReader.imageDimension

		@imageMagick = ImageMagick.new
	end

	def draw_all_scales
		# draw original scale first
		scale = 1.0
		draw_all_objects(scale)
		# draw down scale
		for scaleTimes in 1..@pp_tx_downScaleTimes
			scale = (1 - @pp_tx_scaleFactor * scaleTimes).round(1)
			draw_all_objects(scale)
		end
		# draw up scale
		for scaleTimes in 1..@pp_tx_upScaleTimes
			scale = (1 + @pp_tx_scaleFactor * scaleTimes).round(1)
			draw_all_objects(scale)
		end
	end

	def draw_all_objects(scale)
		allObjects = @xmlReader.get_object_names
		allObjects.each do |objName|
			tmpFile = "#{@tempFolder}/#{File.basename(@inputFileName, '.*')}_scl_#{scale}.png"

			objFolder = "#{@outputFolder}/#{objName}"
			FileUtils.mkdir_p(objFolder)
			outputFileName = "#{objFolder}/#{File.basename(@inputFileName, '.*')}_scl_#{scale}.png"

			rectangles = @xmlReader.get_rectangles(objName)
			if rectangles.count > 0
				FileUtils.cp(@inputFileName, tmpFile)
				draw_scaled_patches(objName, tmpFile, rectangles, tmpFile, scale, objFolder)
				if @isTest
					FileUtils.mv(tmpFile, outputFileName)
				else
					FileUtils.rm(tmpFile)
				end
			end
		end
	end

	def draw_scaled_patches(objName, inputFileName, rectangles, outputFileName, scale, objFolder)
		# scale image
		scaledImageSize = Rectangle.new
		scaledImageSize.from_dimension(
				0,0, 
				Integer(@xmlImageSize.width * scale), Integer(@xmlImageSize.height * scale))
		if not scaledImageSize.has_larger_area_than?(@outputRectangleSize)
			raise RuntimeError, "PositivePatchSingle: Cannot resize image to scale factor #{scale}"
		end
		@imageMagick.resize(inputFileName, scaledImageSize, outputFileName)
		imScaledImageSize = @imageMagick.identify(outputFileName)
		# scale rectangles
		transformedRectangles = []
		rectangles.each do |rectangle|
			transformedRectangle = rectangle.get_rectangular_transform(@xmlImageSize, imScaledImageSize)
			if @outputRectangleSize.has_larger_dimensions_than?(transformedRectangle)
				transformedRectangles << transformedRectangle
			end
		end
		# call draw_patches
		draw_patches(objName, outputFileName, imScaledImageSize, transformedRectangles, outputFileName, objFolder)
	end

	def draw_patches(objName, inputFileName, imageConstraintRect, rectangles, outputFileName, objFolder)
		coordinateMath = CoordinateMath.new
		rectangles.each_with_index do |rectangle, index|
			rectanglePatch = coordinateMath.poly_to_rectangle(imageConstraintRect, rectangle)

			# draw the most fitting rectangle
			if @isTest
				@imageMagick.draw_poly(inputFileName, rectangle, outputFileName, "#{objName}: Base: #{index}")
				@imageMagick.draw_poly(outputFileName, rectanglePatch, outputFileName, "#{objName}: Closest: #{index}")
			end

			# ensure that rectanglePatch meets the minimum dimension requirements
			next if (rectanglePatch.get_area * 1.0 / @outputRectangleSize.get_area) < @pp_minObjectAreaFraction

			patchCandidates = coordinateMath.get_patch_candidates(
				imageConstraintRect, rectanglePatch, @outputRectangleSize, @pp_tx_minPixelMove)
			patchCandidates.shuffle!

			patchCandidates.each_with_index do |cropPatch, pidx|
				# breaking conditions
				# if exceed number of jiggles allowed
			 	if pidx >= @pp_tx_maxNumJiggles
			 		break
			 	end
			 	# if only two candidates, take all
			 	if patchCandidates.count > 2
			 		# if more than 2, then take only required fraction
			 		break if (1.0 * pidx/patchCandidates.count) > @pp_tx_jigglesFraction
			 	end

			  # if looking for a square, panic if we don't get one back
				if @outputRectangleSize.is_square?
					if not cropPatch.is_square?
						cropPatch.print
						raise RuntimeError, "PositivePatchSingle: Couldn't construct a rectangle patch to crop"
					end
				end
				
				# finally, proliferate
				if @isTest
					@imageMagick.draw_poly(outputFileName, cropPatch, outputFileName, "#{objName}: Crop: #{index}.#{pidx}")			
				else
					outputFileName = "#{objFolder}/#{File.basename(inputFileName, '.*')}_crp_#{index}.#{pidx}.png"
					@imageMagick.crop(inputFileName, cropPatch, outputFileName)
				end
			end
		end
	end

end
