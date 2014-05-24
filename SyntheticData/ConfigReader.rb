require 'yaml'

require_relative 'Rectangle.rb'

class ConfigReader
	attr_accessor :className, :runType, :maxThreads
	attr_accessor :inputBaseFolder, :positiveImageFolder, :positiveAnnotationFolder, :negativeImageFolder
	attr_accessor :positiveOutputPatches, :negativeOutputPatchesFromPositive, :negativeOutputPatches
	attr_accessor :testRunResults, :tempFolder, :outputRectangleSize

	def initialize(configFile)
		y = YAML.load_file(configFile)
		@className = y['class_name']
		y['run_type'].each do |k, v|
			if v ; @runType = "#{k}" ; end
		end
		if @runType == nil
			raise RuntimeError, "ConfigReader: Must specify one and only one run type inconfig file"
		end
		@maxThreads = y['max_number_of_threads']

		@inputBaseFolder = y['input_base_folder']
		@positiveImageFolder = "#{@inputBaseFolder}/#{y['positive_input_images']}"
		@positiveAnnotationFolder = "#{@inputBaseFolder}/#{y['positive_input_annotation']}"
		@negativeImageFolder = "#{@inputBaseFolder}/#{y['negative_input_images']}"

		@outputBaseFolder = y['output_base_folder']
		@positiveOutputPatches = "#{@outputBaseFolder}/#{y['positive_output_patches']}"
		@negativeOutputPatchesFromPositive = "#{@outputBaseFolder}/#{y['negatie_output_patches_from_positive_images']}"
		@negativeOutputPatches = "#{@outputBaseFolder}/#{y['negative_output_patches']}"
		@testRunResults = "#{@outputBaseFolder}/#{y['test_results']}"

		@tempFolder = y['tempfs']

		outputWidth = Integer(y['output_width'])
		outputHeight = Integer(y['output_height'])
		@outputRectangleSize = Rectangle.new
		@outputRectangleSize.from_dimension(0, 0, outputWidth, outputHeight)
		if not @outputRectangleSize.is_square?
			raise RuntimeError, "ConfigReader: Currently only supports square configuration for output patch"
		end
	end


end
