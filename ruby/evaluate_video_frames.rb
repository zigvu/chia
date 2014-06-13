#!/usr/bin/env ruby

require 'fileutils'

require_relative 'classes/ConfigReader.rb'
require_relative 'classes/SlidingWindowCreator.rb'
require_relative 'classes/CommonUtils.rb'
require_relative 'classes/PatchTracker.rb'
require_relative 'classes/SavePostAnalysisPatches.rb'


if __FILE__ == $0
	if ARGV.count < 4
		puts "Evaluate extracted frames from video"
		puts " "
		puts "Usage: ./evaluate_video_frames.rb config.yaml inputVideo videoProtoFile modelFile"
		puts " "
		puts "       All results will be saved in various sub-directories of 'output' folder"
		exit
	end

	configFile = ARGV[0]
	inputVideo = ARGV[1]
	videoProtoFile = ARGV[2]
	modelFile = ARGV[3]
	outputFolder = 'output'

	configReader = ConfigReader.new(configFile)
	commonUtils = CommonUtils.new
	endToEndTimeCounter = CommonUtils.new

	# -----------------------------------------------
	# set folder names
	frameFolder = "#{outputFolder}/#{File.basename(inputVideo,'.*')}"
	patchFolder = "#{outputFolder}/#{configReader.sw_PatchFolder}"
	annotationFolder = "#{outputFolder}/#{configReader.sw_AnnotationFolder}"
	leveldbFolder = "#{outputFolder}/logo-leveldb"
	postAnalysisFolder = "#{outputFolder}/post_analysis"

	leveldbLabelFile = "#{outputFolder}/leveldb_labels.txt"
	caffeResultFile = "#{outputFolder}/caffe_result.csv"


	FileUtils.mkdir_p(frameFolder)
	FileUtils.mkdir_p(patchFolder)
	FileUtils.mkdir_p(annotationFolder)
	FileUtils.mkdir_p(leveldbFolder)


	# -----------------------------------------------
	# Extract all frames
	videoReaderCommand = "#{configReader.khajuriRoot}/VideoReader/VideoReader" + 
			" #{inputVideo}" +
			" #{configReader.sw_frameDensity}" +
			" #{frameFolder}"
	commonUtils.print_banner("Start: Generate frames from video")
	commonUtils.bash(videoReaderCommand)
	commonUtils.print_banner("End  : Generate frames from video")
	commonUtils.print_time("Generate frames from video")
	


	# -----------------------------------------------
	# Extract patches from frames
	commonUtils.print_banner("Start: Generate patches from frame")
	slidingWindowCreator = SlidingWindowCreator.new(configReader, frameFolder, patchFolder, annotationFolder)
	slidingWindowCreator.generate_sliding_windows
	commonUtils.print_banner("End  : Generate patches from frame")
	commonUtils.print_time("Generate patches from frame")



	# -----------------------------------------------
	# Create level db for caffe
	commonUtils.print_banner("Start: Generate leveldb for caffe")
	patchTracker = PatchTracker.new(configReader, patchFolder, annotationFolder)
	patchTracker.add_patch_number_for_leveldb
	patchTracker.update_all_annotations

	patchTracker = PatchTracker.new(configReader, patchFolder, annotationFolder)
	patchTracker.write_leveldb_labels(leveldbLabelFile)

	createLeveldbCommand = "#{configReader.caffeRoot}/build/tools/convert_imageset.bin" +
		" #{patchFolder}/" +
		" #{leveldbLabelFile}" +
		" #{leveldbFolder}/logo-video-leveldb" # note: we don't want randomization in test
	commonUtils.bash(createLeveldbCommand)
	commonUtils.print_banner("End  : Generate leveldb for caffe")
	commonUtils.print_time("Generate leveldb for caffe")


	# -----------------------------------------------
	# Run caffe
	commonUtils.print_banner("Start: Run caffe")
	caffeIterations = patchTracker.get_caffe_min_iterations
	useGPU = configReader.vt_useGPU ? "GPU" : "CPU"
	runCaffeCommand = "#{configReader.caffeRoot}/build/tools/test_net.bin" +
		" #{videoProtoFile}" +
		" #{modelFile}" +
		" #{caffeIterations}" +
		" #{caffeResultFile}" +
		" #{useGPU}"
	commonUtils.bash(runCaffeCommand)

	patchTracker.add_leveldb_results(caffeResultFile)
	patchTracker.update_all_annotations
	commonUtils.print_banner("End  : Run caffe")
	commonUtils.print_time("Run caffe")


	# -----------------------------------------------
	# Save frames for post-analysis
	patchTracker = PatchTracker.new(configReader, patchFolder, annotationFolder)
	commonUtils.print_banner("Start: Save frames/patches for post-analysis")
	allPatchesResultHash = patchTracker.allPatches
	savePostAnalysisPatches = SavePostAnalysisPatches.new(
		configReader, allPatchesResultHash, patchFolder, frameFolder, postAnalysisFolder)
	savePostAnalysisPatches.copy_patches_non_background_classes
	savePostAnalysisPatches.copy_frame_background_classes
	commonUtils.print_banner("End  : Save frames/patches for post-analysis")
	commonUtils.print_time("Save frames/patches for post-analysis")	

	endToEndTimeCounter.print_time("End-to-End video analysis")
end
