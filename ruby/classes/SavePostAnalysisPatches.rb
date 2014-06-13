require 'json'
require 'fileutils'

class SavePostAnalysisPatches
	def initialize(configReader, allPatchesResultHash, patchFolder, frameFolder, outputFolder)
		@vt_backgroundClasses = configReader.vt_backgroundClasses

		@allPatches = allPatchesResultHash
		@vt_nonBackgroundClasses = get_all_classes - @vt_backgroundClasses

		@patchFolder = patchFolder
		@frameFolder = frameFolder
		@outputFolder = outputFolder
	end

	def copy_patches_non_background_classes
		@vt_nonBackgroundClasses.each do |classId|
			copy_patches(classId)
		end
	end

	def copy_frame_background_classes
		classOutputFolder = "#{@outputFolder}/frames/background"
		FileUtils.mkdir_p(classOutputFolder)
		@allPatches.each do |frameNumber, fileJSON|
			saveFrame = true
			frameFilename = "#{@frameFolder}/#{fileJSON['frame_filename']}"
			fileJSON['scales'].each do |scale|
				break if not saveFrame
				scale['patches'].each do |patch|
					break if not saveFrame
					scoresArr = (patch['scores'].sort_by { |k, v| v }).reverse
					# if even in 1 scale, a positive patch appears, then, this is not background frame
					if @vt_nonBackgroundClasses.include?(Integer(scoresArr[0][0]))
						saveFrame = false
					end
				end
			end
			if saveFrame
				FileUtils.cp(frameFilename, classOutputFolder)
			end
		end
	end

	def copy_patches(classId)
		classOutputFolder = "#{@outputFolder}/patches/class_#{classId}"
		FileUtils.mkdir_p(classOutputFolder)
		@allPatches.each do |frameNumber, fileJSON|
			fileJSON['scales'].each do |scale|
				scale['patches'].each do |patch|
					patchFilename = "#{@patchFolder}/#{patch['patch_filename']}"
					scoresArr = (patch['scores'].sort_by { |k, v| v }).reverse
					if Integer(scoresArr[0][0]) == classId
						FileUtils.cp(patchFilename, classOutputFolder)
					end
				end
			end
		end
	end

	def get_all_classes
		clsArr = []
		@allPatches.first[1]['scales'].first['patches'].first['scores'].keys.each do |k|
			clsArr << Integer(k)
		end
		return clsArr
	end

end
