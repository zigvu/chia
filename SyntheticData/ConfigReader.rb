require 'yaml'

require_relative 'Rectangle.rb'

class ConfigReader
	attr_accessor :className, :runType, :maxThreads, :currentRunName
	attr_accessor :inputBaseFolder, :outputBaseFolder, :tempFolder
	attr_accessor :imageFolder, :annotationFolder, :outputFolder
	attr_accessor :outputRectangleSize, :numberOfPatchPerImage, :includeSubFolders, :hasAnnotations
	attr_accessor :datasetSplit
	attr_accessor :slidingWindowStrideX, :slidingWindowStrideY, :downScaleTimes, :upScaleTimes

	def initialize(configFile)
		y = YAML.load_file(configFile)
		@className = y['class_name']
		@maxThreads = y['max_number_of_threads']

		@inputBaseFolder = y['input_base_folder']
		@outputBaseFolder = y['output_base_folder']
		@tempFolder = y['tempfs']

		y['runs'].each do |k, v|
				@currentRunName = k	if v['current']
		end
		if @currentRunName == '' || @currentRunName == nil
			raise RuntimeError, "ConfigReader: Must specify one and only one run type in config file"
		end

		runSetting = y['runs'][@currentRunName]
		@imageFolder = "#{@inputBaseFolder}/#{runSetting['input_images_folder']}"
		@annotationFolder = "#{@inputBaseFolder}/#{runSetting['input_annotations_folder']}"
		@outputFolder = "#{@outputBaseFolder}/#{runSetting['output_folder']}"
		
		# get desired dimensions
		outputWidth = Integer(y['output_width'])
		outputHeight = Integer(y['output_height'])
		@outputRectangleSize = Rectangle.new
		@outputRectangleSize.from_dimension(0, 0, outputWidth, outputHeight)
		if not @outputRectangleSize.is_square?
			raise RuntimeError, "ConfigReader: Currently only supports square configuration for output patch"
		end

		@numberOfPatchPerImage = Integer(runSetting['number_of_patch_per_image']) if runSetting['number_of_patch_per_image'] != nil
		@includeSubFolders = runSetting['include_sub_folders'] == "yes" ? true : false
		@hasAnnotations = runSetting['input_annotations_folder'] == "none" ? false : true

		# dataset split
		trainPercent = y['dataset_split']['train'] == nil ? 0 : Float(y['dataset_split']['train'])
		valPercent = y['dataset_split']['val'] == nil ? 0 : Float(y['dataset_split']['val'])
		testPercent = y['dataset_split']['test'] == nil ? 0 : Float(y['dataset_split']['test'])
		@datasetSplit = {
			train: trainPercent,
			val: valPercent,
			test: testPercent
		}

		# sliding window
		slidingWindow = y['sliding_window']
		@slidingWindowStrideX = Integer(slidingWindow['x_stride'])
		@slidingWindowStrideY = Integer(slidingWindow['y_stride'])
		@downScaleTimes = Integer(slidingWindow['down_scale_times'])
		@upScaleTimes = Integer(slidingWindow['up_scale_times'])
	end
end
