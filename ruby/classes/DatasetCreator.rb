require 'fileutils'
require_relative 'ImageMagick.rb'

class DatasetCreator
	# each folder in inputFolder is assumed to be a separate class
	def initialize(inputFolder, outputFolder, configReader)
		@inputFolder = inputFolder
		@outputFolder = outputFolder
		@configReader = configReader
		@trainFolder = "#{@outputFolder}/train"
		@valFolder = "#{@outputFolder}/val"
		@testFolder = "#{@outputFolder}/test"

		@outputRectangleSize = @configReader.outputRectangleSize
		@imageMagick = ImageMagick.new

		FileUtils.mkdir_p(@outputFolder)
	end

	def split_for_caffe(trainPercent, valPercent, testPercent)
		if (trainPercent + valPercent + testPercent).round != 1
			raise RuntimeError, "DatasetCreator: splits don't add up to 100%"
		end

		# first, resize files but preserve input folder structure
		resizeTempFolder = "#{@outputFolder}/temp"
		FileUtils.mkdir_p(resizeTempFolder)
		convert_copy_image_parallel(@inputFolder, resizeTempFolder)

		# now that all files are resized, move files and create labels
		allclassHash = allclass_hash(@inputFolder)

		# create folders
		FileUtils.mkdir_p(@trainFolder)
		FileUtils.mkdir_p(@testFolder)
		FileUtils.mkdir_p(@valFolder)

		dataLabelMappingArr = []
		trainLabelArr = []
		valLabelArr = []
		testLabelArr = []

		Dir["#{resizeTempFolder}/*"].each do |folderPath|
			folderName = File.basename(folderPath)
			outputFolderTrain = "#{@trainFolder}/#{folderName}"
			outputFolderVal = "#{@valFolder}/#{folderName}"
			outputFolderTest = "#{@testFolder}/#{folderName}"

			trainCount = 0
			valCount = 0
			testCount = 0

			dataLabel = allclassHash[:"#{folderName}"]
			if dataLabel == nil
				raise RuntimeError, "Class #{folderName} not found after resize!"
			end
			
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
					FileUtils.mv(fname, outputFolderTrain)
					trainCount = trainCount + 1
				elsif valPercent > (valCount * 1.0 / allFiles.count)
					valLabelArr << "#{imageLabel}"
					FileUtils.mv(fname, outputFolderVal)
					valCount = valCount + 1
				else
					testLabelArr << "#{imageLabel}"
					FileUtils.mv(fname, outputFolderTest)
					testCount = testCount + 1
				end
			end
			dataLabelMappingArr << "#{folderName} #{dataLabel}"
		end

		FileUtils.rm_rf(resizeTempFolder)

		# save label files:
		write_arr_to_file("#{@trainFolder}/train_labels.txt", trainLabelArr)
		write_arr_to_file("#{@valFolder}/val_labels.txt", valLabelArr)
		write_arr_to_file("#{@testFolder}/test_labels.txt", testLabelArr)
		write_arr_to_file("#{@outputFolder}/label_mappings.txt", dataLabelMappingArr)
	end

	# if files are already placed in train test buckets
	# assume that @inputFolder has test and train folders with different
	# classes as subfolders to those
	def create_label_for_caffe
		FileUtils.mkdir_p(@trainFolder)
		FileUtils.mkdir_p(@testFolder)

		inputFolderTrain = "#{@inputFolder}/train"
		inputFolderTest = "#{@inputFolder}/test"
		allclassHash = allclass_hash(inputFolderTrain)

		# first, resize files but preserve input folder structure
		resizeTempFolder = "#{@outputFolder}/temp"

		puts "Working on train images..."
		puts ""
		FileUtils.mkdir_p(resizeTempFolder)
		convert_copy_image_parallel(inputFolderTrain, resizeTempFolder)
		dataLabelMappingArr, trainLabelArr = relocate_files(resizeTempFolder, @trainFolder, allclassHash)		

		puts "Working on test images..."
		puts ""
		FileUtils.rm_rf(resizeTempFolder)
		FileUtils.mkdir_p(resizeTempFolder)
		convert_copy_image_parallel(inputFolderTest, resizeTempFolder)
		dataLabelMappingArr, testLabelArr = relocate_files(resizeTempFolder, @testFolder, allclassHash)
		FileUtils.rm_rf(resizeTempFolder)

		# save label files:
		write_arr_to_file("#{@trainFolder}/train_labels.txt", trainLabelArr)
		write_arr_to_file("#{@testFolder}/test_labels.txt", testLabelArr)
		write_arr_to_file("#{@outputFolder}/label_mappings.txt", dataLabelMappingArr)
	end

	# assume that @inputFolder has classes as subfolders
	def create_test_lables
		puts "Working on test images..."
		puts ""
		testLabelArr = read_files(@inputFolder)

		# save label files:
		write_arr_to_file("#{@outputFolder}/leveldb_labels.txt", testLabelArr)
	end

	def relocate_files(inputFolder, outputFolder, allclassHash)
		dataLabelMappingArr = []
		labelArr = []

		Dir["#{inputFolder}/*"].each do |folderPath|
			folderName = File.basename(folderPath)
			outputFolderNew = "#{outputFolder}/#{folderName}"

			FileUtils.mkdir_p(outputFolderNew)
			allFiles = Dir["#{folderPath}/*.png"]
			allFiles.shuffle!

			dataLabel = allclassHash[:"#{folderName}"]
			if dataLabel == nil
				raise RuntimeError, "Class #{folderName} not found after resize!"
			end

			allFiles.each do |fname|
				fBaseName = File.basename(fname)
				imageLabel = "#{folderName}/#{fBaseName} #{dataLabel}"

				puts "#{imageLabel}"
				labelArr << "#{imageLabel}"
				FileUtils.mv(fname, outputFolderNew)
			end
			dataLabelMappingArr << "#{folderName} #{dataLabel}"
		end
		return dataLabelMappingArr, labelArr
	end

	def read_files(inputFolder)
		labelArr = []

		Dir["#{inputFolder}/*"].each do |folderPath|
			folderName = File.basename(folderPath)
			allFiles = Dir["#{folderPath}/*.png"]

			# assume test patches all belong to the same class
			dataLabel = 0

			allFiles.each do |fname|
				fBaseName = File.basename(fname)
				imageLabel = "#{folderName}/#{fBaseName} #{dataLabel}"

				puts "#{imageLabel}"
				labelArr << "#{imageLabel}"
			end
		end
		return labelArr
	end

	def allclass_hash(baseFolderName)
		allClass = {}
		dataLabel = 0
		sortedFolderList = Dir["#{baseFolderName}/*"].sort_by { |v| v.downcase}
		sortedFolderList.each do |folderPath|
			folderName = File.basename(folderPath)
			allClass.merge!({:"#{folderName}" => dataLabel})
			dataLabel = dataLabel + 1
		end
		return allClass
	end

	def write_arr_to_file(filename, array)
		File.open(filename, 'w') do |file|
			array.each do |ta|
				file.puts "#{ta}"
			end
		end
	end

	def convert_copy_image_parallel(inputFolder, outputFolder)
		Dir["#{inputFolder}/*"].each do |folderPath|
			folderName = File.basename(folderPath)
			outputFolderTemp = "#{outputFolder}/#{folderName}"
			FileUtils.mkdir_p(outputFolderTemp)

			allInputFiles = Dir["#{folderPath}/*"]
			# if multi-threaded is enabled, do in parallel
			if @configReader.multiThreaded
				allInputFiles.each_slice(@configReader.numOfProcessors * 2) do |group|
					group.map do |inputFileName|
						Thread.new do
							convert_copy_image(inputFileName, outputFolderTemp)
						end
					end.each(&:join)
				end
			else
				allInputFiles.each do |inputFileName|
					convert_copy_image(inputFileName, outputFolderTemp)
				end
			end
		end
	end

	def convert_copy_image(inputFileName, outputFolder)
		puts "Resizing file: #{inputFileName}"
		outputFileName = "#{outputFolder}/#{File.basename(inputFileName)}"
		@imageMagick.resize_exact(inputFileName, @outputRectangleSize, outputFileName)
	end
end
