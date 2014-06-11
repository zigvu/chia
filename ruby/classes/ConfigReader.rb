require 'yaml'

require_relative 'Rectangle.rb'

class ConfigReader
	attr_accessor :multiThreaded, :tempFolder, :outputRectangleSize

	# dataset split
	attr_accessor :datasetTypeTrainTest, :datasetTypeSplitData, :datasetTypeTestOnly, :datasetSplit

	# positive patch
	attr_accessor :pp_isTest, :pp_ImagesFolder, :pp_AnnotationsFolder
	attr_accessor :pp_tx_jigglesFraction, :pp_tx_maxNumJiggles, :pp_tx_minPixelMove, :pp_tx_numShear
	attr_accessor :pp_tx_upScaleTimes, :pp_tx_downScaleTimes, :pp_tx_scaleFactor

	# negative patch from positive
	attr_accessor :npfp_isTest, :npfp_ImagesFolder, :npfp_AnnotationsFolder, :npfp_NumPatchPerImage

	# negative patch
	attr_accessor :np_isTest, :np_IncludeSubFolders, :np_NumPatchPerImage
	
	# sliding window
	attr_accessor :sw_isTest, :sw_StrideX, :sw_StrideY, :sw_downScaleTimes, :sw_upScaleTimes, :sw_scaleFactor
	attr_accessor :sw_frameDensity, :sw_PatchFolder, :sw_AnnotationFolder

	# root of other repos
	attr_accessor :khajuriRoot, :caffeRoot

	def initialize(configFile)
		y = YAML.load_file(configFile)
		@multiThreaded = y['multi_threaded'] == true

		@khajuriRoot = y['khajur_root']
		@caffeRoot = y['caffe_root']


		@tempFolder = y['tempfs']
		
		# get desired dimensions
		outputWidth = Integer(y['output_width'])
		outputHeight = Integer(y['output_height'])
		@outputRectangleSize = Rectangle.new
		@outputRectangleSize.from_dimension(0, 0, outputWidth, outputHeight)

		# dataset split
		datasetSetup = y['dataset_setup']
		@datasetTypeTrainTest = datasetSetup['dataset_type'] == 'train_test'
		@datasetTypeSplitData = datasetSetup['dataset_type'] == 'split_data'
		@datasetTypeTestOnly = datasetSetup['dataset_type'] == 'test_only'

		datasetSplt = datasetSetup['dataset_split']
		trainPercent = datasetSplt['train'] == nil ? 0 : Float(datasetSplt['train'])
		valPercent = datasetSplt['validation'] == nil ? 0 : Float(datasetSplt['validation'])
		testPercent = datasetSplt['test'] == nil ? 0 : Float(datasetSplt['test'])
		@datasetSplit = {
			train: trainPercent,
			val: valPercent,
			test: testPercent
		}

		# positive patch
		positivePatch = y['positive_patch']
		@pp_isTest = positivePatch['is_test'] == true
		@pp_ImagesFolder = positivePatch['folders']['image_input']
		@pp_AnnotationsFolder = positivePatch['folders']['annotation_input']
		
		transformations = positivePatch['transformations']
		@pp_tx_jigglesFraction = Float(transformations['jiggles']['fraction_to_keep'])
		@pp_tx_maxNumJiggles = Integer(transformations['jiggles']['max_num_jiggles'])
		@pp_tx_minPixelMove = Integer(transformations['jiggles']['min_pixel_move'])
		@pp_tx_numShear = Integer(transformations['shear']['num_shear'])
		@pp_tx_downScaleTimes = Integer(transformations['scaling']['down_scale_times'])
		@pp_tx_upScaleTimes = Integer(transformations['scaling']['up_scale_times'])
		@pp_tx_scaleFactor = Float(transformations['scaling']['scale_factor']).round(1)

		# negative patch from positive
		negativePatchFromPositive = y['negative_patch_from_positive']
		@npfp_isTest = negativePatchFromPositive['is_test'] == true
		@npfp_ImagesFolder = negativePatchFromPositive['folders']['image_input']
		@npfp_AnnotationsFolder = negativePatchFromPositive['folders']['annotation_input']
		@npfp_NumPatchPerImage = Integer(negativePatchFromPositive['number_of_patch_per_image'])

		# negative_patch
		negativePatch = y['negative_patch']
		@np_isTest = negativePatch['is_test'] == true
		@np_IncludeSubFolders = negativePatch['folders']['include_sub_folders'] == 'yes'
		@np_NumPatchPerImage = Integer(negativePatch['number_of_patch_per_image'])
		
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
	end
end
