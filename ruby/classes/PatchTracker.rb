require 'json'
require 'fileutils'

class PatchTracker
	attr_reader :allPatches

	def initialize(configReader, patchFolder, annotationFolder)
		@patchFolder = patchFolder
		@annotationFolder = annotationFolder

		@vt_caffeBatchSize = configReader.vt_caffeBatchSize

		# key: frameNumber, value: JSON from file
		@allPatches = {}
		read_all_annotations
	end

	def read_all_annotations
		tempPatches = {}
		Dir["#{@annotationFolder}/*.json"].each do |fname|
			j = JSON.parse(IO.read(fname))
			tempPatches.merge!({ Integer(j['frame_number']) => j })
		end
		# put in order of frame number
		sortedKeys = tempPatches.keys.sort
		sortedKeys.each do |sortedKey|
			@allPatches.merge!({sortedKey => tempPatches[sortedKey]})
		end
		return true
	end

	# adds patch number to each patch to keep track in leveldb
	def add_patch_number_for_leveldb
		leveldbCounter = 0
		@allPatches.each do |frameNumber, fileJSON|
			fileJSON['scales'].each do |scale|
				scale['patches'].each do |patch|
					patch.merge!({leveldb_counter: leveldbCounter})
					leveldbCounter = leveldbCounter + 1
				end
			end
		end
	end

	def add_leveldb_results(resultFileName)
		allScores = {}
		File.open(resultFileName, 'r').each_line do |line|
			cleanLine = line.chomp.delete(' ').split(',')
			next if cleanLine[1] == nil
			# index 0 is the leveldb_counter
			leveldbCounter = Integer(cleanLine[0])
			# subsequent indices are class probs
			scores = {}
			for i in 1..(cleanLine.count - 1)
				scores.merge!({(i - 1) => Float(cleanLine[i])})
			end
			allScores.merge!({leveldbCounter => scores})
		end
		@allPatches.each do |frameNumber, fileJSON|
			fileJSON['scales'].each do |scale|
				scale['patches'].each do |patch|
					leveldbCounter = Integer(patch['leveldb_counter'])
					patch.merge!({scores: allScores[leveldbCounter]})
				end
			end
		end
	end

	def write_leveldb_labels(outputFileName)
		file = File.open(outputFileName, 'w')
		leveldbLabels = {}
		# first, read all counter/filename combo
		@allPatches.each do |frameNumber, fileJSON|
			fileJSON['scales'].each do |scale|
				scale['patches'].each do |patch|
					patchFilename = patch['patch_filename']
					leveldbCounter = Integer(patch['leveldb_counter'])
					leveldbLabels.merge!({ leveldbCounter => patchFilename })
				end
			end
		end
		
		leveldbArr = leveldbLabels.sort_by { |labelCounter, patchName| labelCounter }
		sanityCheckCounter = 0
		leveldbArr.each do |labeldbItem|
			if labeldbItem[0] != sanityCheckCounter
				puts "labeldbItem[0]: #{labeldbItem[0]}; sanityCheckCounter: #{sanityCheckCounter}"
				raise RuntimeError, "PatchTracker: Error writing leveldb labels - label counter not contiguous"
			end
			sanityCheckCounter = sanityCheckCounter + 1
		end
		leveldbArr.each do |labeldbItem|
			# pretend all patches are in the first class
			file.puts "#{labeldbItem[1]} 0"
		end
		file.close
	end

	def get_caffe_min_iterations
		patchCount = 0
		@allPatches.each do |frameNumber, fileJSON|
			fileJSON['scales'].each do |scale|
				scale['patches'].each do |patch|
					patchCount = patchCount + 1
				end
			end
		end
		return (patchCount * 1.0 / @vt_caffeBatchSize).ceil
	end

	def update_all_annotations
		@allPatches.each do |frameNumber, fileJSON|
			outputFileName = "#{@annotationFolder}/#{fileJSON['annotation_filename']}"
			FileUtils.rm(outputFileName)
			write_annotation(outputFileName, fileJSON)
		end
	end

	def write_annotation(outputFileName, hash)
		File.open(outputFileName, 'w') do |file|
			file.puts JSON.pretty_generate(hash)
		end
	end

	def dump_csv(outputFileName)
		file = File.open(outputFileName, 'w')
		
		topLine = "frame_number,frame_filename,annotation_filename,scale,patch_filename," + 
				"patch_dim_x,patch_dim_y,patch_dim_width,patch_dim_height"
		scrs = allPatches.first[1]["scales"][0]["patches"][0]["scores"]
		scrsKeyArr = []
		scrs.each do |k,v|; scrsKeyArr << k; end
		scrsKeyArr.each do |sck|
			topLine = "#{topLine},scores_cls_#{sck}"
		end
		file.puts topLine
		@allPatches.each do |frame_number, fileJSON|
			frame_filename = fileJSON["frame_filename"]
			annotation_filename = fileJSON["annotation_filename"]
			fileJSON['scales'].each do |scale|
				scaleNum = Float(scale["scale"])
				scale['patches'].each do |patch|
					patch_filename = patch["patch_filename"]
					patch_dim_x = patch["patch"]["x"]
					patch_dim_y = patch["patch"]["y"]
					patch_dim_width = patch["patch"]["width"]
					patch_dim_height = patch["patch"]["height"]
					line = "#{frame_number},#{frame_filename},#{annotation_filename},#{scaleNum},#{patch_filename}," + 
							"#{patch_dim_x},#{patch_dim_y},#{patch_dim_width},#{patch_dim_height}"
					scrsKeyArr.each do |sck|
						line = "#{line},#{patch['scores'][sck]}"
					end
					file.puts line
				end
			end
		end
		file.close
	end

end
