
require_relative 'PositivePatchSingle.rb'

class PositivePatchCreator

	def initialize(configReader, annotationsFolder, imagesFolder, outputFolder)
		@annotationsFolder = annotationsFolder
		@imagesFolder = imagesFolder
		@outputFolder = outputFolder

		FileUtils.mkdir_p(@outputFolder)

		@configReader = configReader
	end

	def create_positive_patches
		allInputFiles = Dir["#{@annotationsFolder}/*.xml"]
		if @configReader.multiThreaded
			allInputFiles.each_slice(@configReader.numOfProcessors * 2) do |group|
				group.map do |inputFileName|
					Thread.new do
						patch_single_file(inputFileName)
					end
				end.each(&:join)
			end
		else
			allInputFiles.each do |inputFileName|
				patch_single_file(inputFileName)
			end
		end
	end

	def patch_single_file(inputAnnotation)
		puts "Starting #{File.basename(inputAnnotation)}..."
		begin
			pps = PositivePatchSingle.new(@configReader, inputAnnotation, @imagesFolder, @outputFolder)
			pps.draw_all_scales
			puts "Done #{File.basename(inputAnnotation)}"
		rescue Exception => e
			puts "Error: #{File.basename(inputAnnotation)}: #{e.message}"
		end
	end

end
