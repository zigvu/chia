require 'json'
require 'fileutils'

class FrameLevelResults
	def initialize(patchJSONFile, patchLevelResults)
		@patchJSON = JSON.parse(IO.read(patchJSONFile))
		@patchLevelResults = patchLevelResults
	end

	def get_frame_filename
		return @patchJSON["frame_filename"]
	end

	# currently, get the max patch score in all scales for predClass
	def get_frame_level_detections(predClass)
		maxScore = 0
		maxScale = nil
		maxBB = nil
		@patchJSON["scales"].each do |scale|
			scale["patches"].each do |patch|
				patchFilename = patch["patch_filename"]
				patchPredClass = @patchLevelResults.get_pred_class_for(patchFilename)
				patchPredScrore = @patchLevelResults.get_pred_score_for(patchFilename)
				if patchPredClass == predClass && patchPredScrore > maxScore
					maxScore = patchPredScrore
					maxScale = scale["scale"]
					maxBB = patch["patch"]
				end
			end
		end
		return maxScore, maxScale, maxBB
	end

	def get_detected_patch_filenames(predClass)
		patchFilenames = []
		@patchJSON["scales"].each do |scale|
			scale["patches"].each do |patch|
				patchFilename = patch["patch_filename"]
				patchPredClass = @patchLevelResults.get_pred_class_for(patchFilename)
				if patchPredClass == predClass
					patchFilenames << patchFilename
				end
			end
		end
		return patchFilenames
	end
end
