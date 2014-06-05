
require_relative 'Rectangle.rb'
require_relative 'CoordinateMath.rb'
require_relative 'XMLReader.rb'
require_relative 'ImageMagick.rb'
require_relative 'AnnotationExtractor.rb'
require_relative 'ConfigReader.rb'

class SingleFileOperation
	def initialize(configReader)
		@configReader = configReader
	end

	def run_annotated_file(annotationFile)
		x = XMLReader.new("#{annotationFile}", @configReader.imageFolder)
		ax = AnnotationExtractor.new(@configReader.tempFolder, @configReader.outputFolder)
		ax.initialize_from_xml(x, @configReader.className)

		# perform task
		if @configReader.currentRunName == 'test_positive_patch'
			ax.test_positive_patch(@configReader.outputRectangleSize)

		elsif @configReader.currentRunName == 'test_negative_patch_from_positive'
			ax.test_negative_patch_from_positive(@configReader.outputRectangleSize, 
				@configReader.numberOfPatchPerImage)
		
		elsif @configReader.currentRunName == 'crop_positive_patch'
			ax.crop_positive_patch(@configReader.outputRectangleSize)

		elsif @configReader.currentRunName == 'crop_negative_patch_from_positive'
			ax.crop_negative_patch_from_positive(@configReader.outputRectangleSize, 
				@configReader.numberOfPatchPerImage)
		
		else
			puts "Error: Function not yet implemented"
		end
	end

	def run_non_annotated_file(imageFileName)
		ax = AnnotationExtractor.new(@configReader.tempFolder, @configReader.outputFolder)
		ax.initialize_from_file(imageFileName)

		# perform task
		if @configReader.currentRunName == 'test_negative_patch'
			ax.test_negative_patch(@configReader.outputRectangleSize, 
				@configReader.numberOfPatchPerImage)

		elsif @configReader.currentRunName == 'crop_negative_patch'
			ax.crop_negative_patch(@configReader.outputRectangleSize, 
				@configReader.numberOfPatchPerImage)
				
		elsif @configReader.currentRunName == 'test_sliding_window'
			ax.test_sliding_window(@configReader.outputRectangleSize, 
				@configReader.slidingWindowStrideX,
				@configReader.slidingWindowStrideY,
				@configReader.downScaleTimes,
				@configReader.upScaleTimes,
				@configReader.scaleFactor)

		elsif @configReader.currentRunName == 'crop_sliding_window'
			ax.crop_sliding_window(@configReader.outputRectangleSize, 
				@configReader.slidingWindowStrideX,
				@configReader.slidingWindowStrideY,
				@configReader.downScaleTimes,
				@configReader.upScaleTimes,
				@configReader.scaleFactor)
				
		else
			puts "Error: Function not yet implemented"
		end
	end
end

