require 'json'
require 'fileutils'

class PatchLevelResults
	def initialize(classificationFile)
		@patchResults = patch_result_extractor(classificationFile)
	end

	def get_pred_class_for(patchFileName)
		return @patchResults[:"#{patchFileName}"][:pred_class]
	end

	def get_pred_score_for(patchFileName)
		return @patchResults[:"#{patchFileName}"][:pred_score]
	end

	def get_class_count(predClass)
		count = 0
		@patchResults.each do |k, v|
			count = count + 1 if v[:pred_class] == predClass
		end
		return count
	end

	def get_average_score(predClass)
		count = 0
		total = 0
		@patchResults.each do |k, v|
			if v[:pred_class] == predClass
				count = count + 1
				total = total + v[:pred_score]
			end
		end
		return (total * 1.0 / count)
	end

	# load classification output file
	def patch_result_extractor(classificationFile)
		patchResults = {}
		File.open(classificationFile, 'r').each_line do |line|
			cleanLine = line.delete(' ').split(',')
			next if cleanLine[1] == nil
			# format from get_predictions.py file
			patchFileName = cleanLine[0]
			predScore = Float(cleanLine[1])
			predClass = Integer(cleanLine[2])

			patchResults.merge!({
				:"#{patchFileName}" => {pred_score: predScore, pred_class: predClass}
				})
		end
		return patchResults
	end

end
