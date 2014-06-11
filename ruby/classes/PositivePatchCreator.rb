
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
		threads = []
		Dir["#{@annotationsFolder}/*.xml"].each do |inputAnnotation|
			if @configReader.multiThreaded
				threads << Thread.new(inputAnnotation) { |fname|
					patch_single_file(fname)
				}
			else
				patch_single_file(inputAnnotation)
			end
			#break
		end

		if @configReader.multiThreaded
			threads.each { |thr| thr.join }
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
