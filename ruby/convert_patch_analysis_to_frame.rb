#!/usr/bin/env ruby

require 'fileutils'
require_relative 'classes/CommonUtils.rb'

class CombinePatchSingleVideo
	def initialize(baseFolder, videoName)
		videoFolder = "#{baseFolder}/#{videoName}"
		allFrameFolder = "#{videoFolder}/#{videoName}"
		negativeFrameFolder = "#{videoFolder}/groundTruth/negative"
		positiveCleanFolder = "#{videoFolder}/groundTruth/positive_clean"
		positiveBorderlineFolder = "#{videoFolder}/groundTruth/positive_borderline"

		@baseFolder = baseFolder
		@videoName = videoName
		@combinedPatchFolder = "#{videoFolder}/combined_patches"

		@allFrames = []
		@nFrames = []
		@pCFrames = []
		@pBFrames = []

		Dir["#{allFrameFolder}/*.png"].each do |fname|; @allFrames << File.basename(fname); end
		Dir["#{negativeFrameFolder}/*.png"].each do |fname|; @nFrames << File.basename(fname); end
		Dir["#{positiveCleanFolder}/*.png"].each do |fname|; @pCFrames << File.basename(fname); end
		Dir["#{positiveBorderlineFolder}/*.png"].each do |fname|; @pBFrames << File.basename(fname); end

		@commonUtils = CommonUtils.new
	end

	def run(detectorThreshold, hitThreshold)
		# run python script
		FileUtils.rm_rf(@combinedPatchFolder)
		pythonCmd = "../python/PatchCombiner/frame_level_results.py #{@baseFolder}" + 
			" #{@videoName} #{detectorThreshold} #{hitThreshold} 0"
		@commonUtils.bash(pythonCmd)

		@cpFrames = []
		Dir["#{@combinedPatchFolder}/*.png"].each do |fname|; @cpFrames << File.basename(fname); end

		# now, we have the results, run our analysis
		tpC = 0
		tpB = 0
		fnC = 0
		fnB = 0

		tn = 0
		fp = 0

		@cpFrames.each do |cpFrame|
			cpClass = cpFrame.split("_")[0]
			cpFname = cpFrame.split("_")[1..-1].join("_")
			# zero is negative
			if cpClass == "0"
				if @nFrames.include?(cpFname)
					tn = tn + 1
				elsif @pCFrames.include?(cpFname)
					fnC = fnC + 1
				elsif @pBFrames.include?(cpFname)
					fnB = fnB + 1
				else
					raise RuntimeError, "File: #{cpFname} doesn't belong to any class"
				end
			else
				if @pCFrames.include?(cpFname)
					tpC = tpC + 1
				elsif @pBFrames.include?(cpFname)
					tpB = tpB + 1
				elsif @nFrames.include?(cpFname)
					fp = fp + 1
				else
					raise RuntimeError, "File: #{cpFname} doesn't belong to any class"
				end
			end
		end
		allCount = tpC + tpB + fnC + fnB + tn + fp
		if allCount != @allFrames.count
			raise RuntimeError, "AllCount doesn't match the total number of frames"
		end

		posCount = @pCFrames.count + @pBFrames.count
		negCount = @nFrames.count
		#puts "Positive: #{posCount}, Negative: #{negCount}, All: #{allCount}"

		# compute for just clean positives:
		xTP = tpC; xFN = fnC; xTN = tn; xFP = fp
		accuracy = ((xTP * 1.0 + xTN)/(xTP * 1.0 + xFN + xTN + xFP)).round(2)
		cleanResults = "#{xTP},#{xFN},#{xTN},#{xFP},#{accuracy}"

		xTP = tpC + tpB; xFN = fnC + fnB; xTN = tn; xFP = fp
		accuracy = ((xTP * 1.0 + xTN)/(xTP * 1.0 + xFN + xTN + xFP)).round(2)
		allResults = "#{xTP},#{xFN},#{xTN},#{xFP},#{accuracy}"

		return cleanResults, allResults
	end
end

if __FILE__ == $0
	if ARGV.count < 2
		puts "Evaluate extracted frames from video"
		puts " "
		puts "Usage: ./convert_patch_analysis_to_frame.rb baseFolder videoName"
		puts " "
		exit
	end

	baseFolder = ARGV[0]
	videoName = ARGV[1]

	cleanResultsCSVFile = File.open("#{baseFolder}/#{videoName}/patch_combination_clean_results.csv",'w')
	allResultsCSVFile = File.open("#{baseFolder}/#{videoName}/patch_combination_all_results.csv",'w')

	detectorThresholds = [0.5, 0.7, 0.9, 0.98]
	hitThresholds = [2, 4, 6, 8, 10, 12, 14, 16]

	cleanResultsCSVFile.puts "DetectorThreshold,HitThreshold,TP,FN,TN,FP,Accuracy"
	allResultsCSVFile.puts "DetectorThreshold,HitThreshold,TP,FN,TN,FP,Accuracy"

	combinePatchSingleVideo = CombinePatchSingleVideo.new(baseFolder, videoName)
	detectorThresholds.each do |detectorThreshold|
		hitThresholds.each do |hitThreshold|
			cleanResult, allResult = combinePatchSingleVideo.run(detectorThreshold, hitThreshold)
			puts "DetectorThreshold: #{detectorThreshold}, HitThreshold: #{hitThreshold}"
			puts "Clean: #{cleanResult}"
			puts "All  : #{allResult}"
			puts " "
			cleanResultsCSVFile.puts "#{detectorThreshold},#{hitThreshold},#{cleanResult}"
			allResultsCSVFile.puts "#{detectorThreshold},#{hitThreshold},#{allResult}"
		end
	end

	cleanResultsCSVFile.close
	allResultsCSVFile.close
end
