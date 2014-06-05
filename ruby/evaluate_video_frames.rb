#!/usr/bin/env ruby

require 'fileutils'

require_relative 'ConfigReader.rb'
require_relative 'SlidingWindowCreator.rb'
require_relative 'CommonUtils.rb'
require_relative 'PatchLevelResults.rb'
require_relative 'FrameLevelResults.rb'

if __FILE__ == $0
	if ARGV.count < 4
		puts "Evaluate extracted frames from video"
		puts " "
		puts "Usage: ./evaluate_video_frames.rb config.yaml inputVideo modelFile outputFolder"
		puts " "
		puts "       All results will be saved in various sub-directories of outputFolder"
		exit
	end

	configFile = ARGV[0]
	inputVideo = ARGV[1]
	modelFile = ARGV[2]
	outputFolder = ARGV[3]

	# set folder names
	frameFolder = "#{outputFolder}/#{File.basename(inputVideo,'.*')}"
	FileUtils.mkdir_p(frameFolder)
	patchFolder = "#{outputFolder}/#{configReader.sw_PatchFolder}"
	annotationFolder = "#{outputFolder}/#{configReader.sw_AnnotationFolder}"

	positiveFrameFolder = "#{outputFolder}/classified/positiveFrame"
	negativeFrameFolder = "#{outputFolder}/classified/negativeFrame"
	positivePatchFolder = "#{outputFolder}/classified/positivePatch"
	negativePatchFolder = "#{outputFolder}/classified/negativePatch"
	FileUtils.mkdir_p(negativeFrameFolder)
	FileUtils.mkdir_p(positivePatchFolder)

	configReader = ConfigReader.new(configFile, 'notUsed', 'notUsed')
	commonUtils = CommonUtils.new

	

	# first, extract all frames
	videoReaderCommand = "#{configReader.khajuriRoot}/VideoReader/VideoReader" + 
			" #{inputVideo}" +
			" #{configReader.sw_frameDensity}" +
			" #{frameFolder}"
	commonUtils.print_banner("Start: Generate frames from video")
	commonUtils.bash(videoReaderCommand)
	commonUtils.print_banner("End  : Generate frames from video")

	

	# extract patches from frames
	commonUtils.print_banner("Start: Generate patches from frame")
	swc = SlidingWindowCreator.new(configReader, frameFolder, patchFolder, annotationFolder)
	swc.generate_sliding_window
	commonUtils.print_banner("End  : Generate patches from frame")

	

	# evaluate patches through detector
	caffePythonPath = "#{configReader.caffeRoot}/python"
	modelBasePath = File.dirname(modelFile)
	# TODO: remove: extension ".csv" is added inside python
	resultFileName = "patch_result"
	getPredictionsCommand = "#{caffePythonPath}/get_predictions.py" +
			" --model_def #{modelBasePath}/logo_deploy.prototxt" +
			" --gpu" +
			" --mean_file #{caffePythonPath}/caffe/imagenet/ilsvrc_2012_mean.npy" +
			" #{patchFolder} #{resultFileName}"
	commonUtils.print_banner("Start: Running caffe on patches")
	commonUtils.bash(getPredictionsCommand)
	commonUtils.print_banner("End  : Running caffe on patches")

	

	# re-construct patch level and frame level results
	commonUtils.print_banner("Start: Analyzing results")
	patchLevelResults = PatchLevelResults.new("#{resultFileName}.csv")
	
	# TODO: remove: this should come from label_mappings.txt and backgroundClass in config
	# also enable multi-classing
	posPatchCount = patchLevelResults.get_class_count(0)
	negPatchCount = patchLevelResults.get_class_count(1)
	puts "Postive Patch Count: #{posPatchCount}, Negative Patch Count: #{negPatchCount}"
	# go through all frames and put negatives in the negative frame folder
	Dir["#{annotationFolder}/*.json"].each do |jFile|
		frameLevelResults = FrameLevelResults.new(jFile, patchLevelResults)
		# keep only positive patches
		patchFileNames = frameLevelResults.get_detected_patch_filenames(0)
		if patchFileNames.count == 0
			# this is a negative frame, so copy the corresponding file
			FileUtils.mv("#{frameFolder}/#{frameLevelResults.get_frame_filename}", "#{negativeFrameFolder}")
		else
			# positive detections - copy them to positive patch folder
			patchFileNames.each do |patchFile|
				FileUtils.mv("#{patchFolder}/#{patchFile}", "#{positivePatchFolder}")
			end
		end
	end
	# finally, move over left over positive frames and negative patches
	FileUtils.mv("#{frameFolder}", "#{positiveFrameFolder}")
	FileUtils.mv("#{patchFolder}", "#{negativePatchFolder}")
	commonUtils.print_banner("End: Analyzing results")
end
