require 'yaml'

require_relative 'Rectangle.rb'

class ConfigReader
	attr_accessor :className, :multiThreaded, :currentRunName
	attr_accessor :inputBaseFolder, :outputBaseFolder, :tempFolder
	attr_accessor :imageFolder, :annotationFolder, :outputFolder
	attr_accessor :outputRectangleSize, :numberOfPatchPerImage, :includeSubFolders, :hasAnnotations
	attr_accessor :datasetTypeTrainTest, :datasetTypeSplitData, :datasetTypeTestOnly, :datasetSplit
	attr_accessor :slidingWindowStrideX, :slidingWindowStrideY, :downScaleTimes, :upScaleTimes, :scaleFactor

	def initialize(configFile, inputBaseFolder, outputBaseFolder)
		y = YAML.load_file(configFile)
		@className = y['class_name']
		@multiThreaded = y['multi_threaded'] == 'true'

		@inputBaseFolder = inputBaseFolder
		@outputBaseFolder = outputBaseFolder
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
		datasetSetup = y['dataset_setup']
		@datasetTypeTrainTest = datasetSetup['dataset_type'] == 'train_test'
		@datasetTypeSplitData = datasetSetup['dataset_type'] == 'split_data'
		@datasetTypeTestOnly = datasetSetup['dataset_type'] == 'test_only'

		trainPercent = datasetSetup['train'] == nil ? 0 : Float(datasetSetup['train'])
		valPercent = datasetSetup['val'] == nil ? 0 : Float(datasetSetup['val'])
		testPercent = datasetSetup['test'] == nil ? 0 : Float(datasetSetup['test'])
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
		@scaleFactor = Float(slidingWindow['scale_factor']).round(1)
	end
end
