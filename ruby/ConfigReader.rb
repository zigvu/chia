require 'yaml'

require_relative 'Rectangle.rb'

class ConfigReader
	attr_accessor :className, :multiThreaded, :currentRunName
	attr_accessor :inputBaseFolder, :outputBaseFolder, :tempFolder
	attr_accessor :imageFolder, :annotationFolder, :outputFolder
	attr_accessor :outputRectangleSize, :numberOfPatchPerImage, :includeSubFolders, :hasAnnotations
	attr_accessor :datasetTypeTrainTest, :datasetTypeSplitData, :datasetTypeTestOnly, :datasetSplit
	
	# sliding window
	attr_accessor :sw_isTest, :sw_StrideX, :sw_StrideY, :sw_downScaleTimes, :sw_upScaleTimes, :sw_scaleFactor
	attr_accessor :sw_frameDensity, :sw_PatchFolder, :sw_AnnotationFolder

	# root of other repos
	attr_accessor :khajuriRoot, :caffeRoot

	def initialize(configFile, inputBaseFolder, outputBaseFolder)
		y = YAML.load_file(configFile)
		@className = y['class_name']
		@multiThreaded = y['multi_threaded'] == true

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
		@sw_isTest = slidingWindow['is_test'] == true
		@sw_StrideX = Integer(slidingWindow['scaling']['x_stride'])
		@sw_StrideY = Integer(slidingWindow['scaling']['y_stride'])
		@sw_downScaleTimes = Integer(slidingWindow['scaling']['down_scale_times'])
		@sw_upScaleTimes = Integer(slidingWindow['scaling']['up_scale_times'])
		@sw_scaleFactor = Float(slidingWindow['scaling']['scale_factor']).round(1)

		@sw_frameDensity = Integer(slidingWindow['frame_density'])
		@sw_PatchFolder = slidingWindow['folders']['patch_output']
		@sw_AnnotationFolder = slidingWindow['folders']['annotation_output']

		@khajuriRoot = y['khajur_root']
		@caffeRoot = y['caffe_root']
	end
end
