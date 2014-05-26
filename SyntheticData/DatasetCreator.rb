require 'fileutils'

class DatasetCreator
	# each folder in inputFolder is assumed to be a separate class
	def initialize(inputFolder, outputFolder)
		@inputFolder = inputFolder
		@outputFolder = outputFolder
		@trainFolder = "#{@outputFolder}/train"
		@valFolder = "#{@outputFolder}/val"
		@testFolder = "#{@outputFolder}/test"

		FileUtils.mkdir_p(@outputFolder)
		FileUtils.mkdir_p(@trainFolder)
		FileUtils.mkdir_p(@valFolder)
		FileUtils.mkdir_p(@testFolder)
	end

	def split_for_caffe(trainPercent, valPercent, testPercent)
		if (trainPercent + valPercent + testPercent).round != 1
			raise RuntimeError, "DatasetCreator: splits don't add up to 100%"
		end

		dataLabel = 0
		dataLabelMappingArr = []
		trainLabelArr = []
		valLabelArr = []
		testLabelArr = []

		Dir["#{@inputFolder}/*"].each do |folderPath|
			folderName = File.basename(folderPath)
			outputFolderTrain = "#{@trainFolder}/#{folderName}"
			outputFolderVal = "#{@valFolder}/#{folderName}"
			outputFolderTest = "#{@testFolder}/#{folderName}"

			trainCount = 0
			valCount = 0
			testCount = 0
			
			FileUtils.mkdir_p(outputFolderTrain)
			FileUtils.mkdir_p(outputFolderVal)
			FileUtils.mkdir_p(outputFolderTest)
			allFiles = Dir["#{folderPath}/*"]
			allFiles.shuffle!

			allFiles.each do |fname|
				fBaseName = File.basename(fname)
				imageLabel = "#{folderName}/#{fBaseName} #{dataLabel}"

				puts "#{imageLabel}"
				if trainPercent > (trainCount * 1.0 / allFiles.count)
					trainLabelArr << "#{imageLabel}"
					FileUtils.cp(fname, outputFolderTrain)
					trainCount = trainCount + 1
				elsif valPercent > (valCount * 1.0 / allFiles.count)
					valLabelArr << "#{imageLabel}"
					FileUtils.cp(fname, outputFolderVal)
					valCount = valCount + 1
				else
					testLabelArr << "#{imageLabel}"
					FileUtils.cp(fname, outputFolderTest)
					testCount = testCount + 1
				end
			end
			dataLabelMappingArr << "#{folderName} #{dataLabel}"
			dataLabel = dataLabel + 1
		end

		# save label files:
		write_arr_to_file("#{@trainFolder}/train_labels.txt", trainLabelArr)
		write_arr_to_file("#{@valFolder}/val_labels.txt", valLabelArr)
		write_arr_to_file("#{@testFolder}/test_labels.txt", testLabelArr)
		write_arr_to_file("#{@outputFolder}/label_mappings.txt", dataLabelMappingArr)
	end

	def write_arr_to_file(filename, array)
		File.open(filename, 'w') do |file|
			array.each do |ta|
				file.puts "#{ta}"
			end
		end
	end
end
