#!/usr/bin/env ruby

require 'fileutils'
require 'csv'
require 'json'
require 'thread'

if __FILE__ == $0
  baseChiaFolder = "/home/ubuntu/chia"

  baseFolder = "/disk1/model_retraining"
  basePatchFolder = "#{baseFolder}/patches/production"
  stagingAreaFolder = "#{baseFolder}/staging_area"
  baseModelFolder = "/mnt/data/video_analysis/models/production"

  # scripts
  leveldbEvaluater = "#{baseChiaFolder}/caffe/build/tools/test_net_logo.bin"

  # configs
  caffeProtoVideo = "#{baseFolder}/configs/logo_video.prototxt"

  if ARGV.count != 1
    puts "This script evaluates all available patches using specified chia versions for"
    puts "import into kheer mini-iteration."
    puts "It is assumed that this script is run from the following location in GPU1:"
    puts "#{baseFolder}"
    puts " "
    puts "It is assumed that caffe models are stored in:"
    puts "#{baseModelFolder}/chiaVersionId[major.minor]"
    puts "Specify minor version = 0 for finalized versions used in video evaluation"
    puts " "
    puts "results are stored in the staging area:"
    puts "#{stagingAreaFolder}/combined_patch_buckets"
    puts " "
    puts "Usage: ~/chia/ruby/retraining_evaluate_all_patches_of_chia_versions.rb <evaluationChiaVersionId[major.minor]>"
    exit
  end

  chiaVersionIdMajor = ARGV[0].split(".")[0].to_i
  chiaVersionIdMinor = ARGV[0].split(".")[1].to_i

  # check if running from right place
  if Dir.pwd != baseFolder
    raise "Need to run this script from #{baseFolder}"
  end

  # get model file
  modelFolder = "#{baseModelFolder}/#{chiaVersionIdMajor}"
  if chiaVersionIdMinor != nil and chiaVersionIdMinor != 0
    modelFolder = "#{modelFolder}.#{chiaVersionIdMinor}"
  end
  modelFile = nil
  Dir.glob("#{modelFolder}/*").each do |mf|
    if mf.include?("caffe_logo_train_iter_")
      modelFile = mf
      break
    end
  end
  raise "Couldn't find model file in folder #{modelFolder}" if modelFile == nil
  puts "Using model: #{modelFile}"

  combinedPatchFolder = "#{stagingAreaFolder}/combined_patch_buckets"
  FileUtils.rm_rf(combinedPatchFolder)
  FileUtils.mkdir_p(combinedPatchFolder)

  puts "****************************************"
  puts "Running caffe model"
  puts "****************************************"
  puts ""

  caffeResultsFolder = "#{stagingAreaFolder}/caffeResults"
  FileUtils.rm_rf(caffeResultsFolder)
  FileUtils.mkdir_p(caffeResultsFolder)

  Dir.glob("#{basePatchFolder}/*").each do |d|
    next if not File.directory?(d)

    currentChiaVersionId = File.basename(d)
    puts "Working on chiaVersionId #{currentChiaVersionId}"

    # folder paths
    patchFolder = "#{d}/patches"
    leveldbFolder = "#{d}/leveldb/leveldb"
    leveldbLabels = "#{d}/leveldb/leveldb_labels.txt"
    patchBucketFolder = "#{d}/patch_buckets"

    resultsFile = "#{caffeResultsFolder}/#{currentChiaVersionId}.csv"
    modifiedPrototxtFile = "#{caffeResultsFolder}/#{currentChiaVersionId}_#{File.basename(caffeProtoVideo)}"
    # modify to point to right leveldb folder
    prototxt = File.read(caffeProtoVideo)
    modifiedPrototxt = prototxt.gsub("leveldb", "#{leveldbFolder}") 
    # open the file for writing
    File.open(modifiedPrototxtFile, "w") do |f|
      f.write(modifiedPrototxt)
    end

    cmdOpts = "#{leveldbEvaluater} #{modifiedPrototxtFile} #{modelFile} #{leveldbLabels} #{resultsFile} GPU 0"
    puts "#{cmdOpts}"
    cmdRetVal = system("#{cmdOpts}")
    raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

    # combine with original annotations json
    puts "Start reading results CSV file"
    # read CSV file into a hash
    # format:
    # {filename: [scores], }
    csvHash = {}
    File.foreach(resultsFile).with_index do |line, lineNum|
      # skip header
      next if lineNum == 0

      parsedCSV = CSV.parse(line).first
      fileName = parsedCSV[0].to_s
      csvHash[fileName] = parsedCSV[1..-1]
    end
    puts "Done reading CSV file"

    puts "Working on patch bucket files"
    Dir.glob("#{patchBucketFolder}/*.json") do |jsonFile|
      jsonBaseName = File.basename(jsonFile)
      jsonFileHash = JSON.load(File.open(jsonFile))
      combinedHash = {}
      combinedHash["annotation_id"] = jsonFileHash["annotation_id"]
      combinedHash["patches"] = {}
      jsonFileHash["patches"].each do |patchFileName|
        combinedHash["patches"][patchFileName] = csvHash[patchFileName] || []
      end
      outputFileName = File.join(combinedPatchFolder, jsonBaseName)
      File.open(outputFileName,"w") do |f|
        f.write(combinedHash.to_json)
      end
    end
    puts "Done working on patch bucket files"
  end

  combinedPatchFolderBasename = File.basename(combinedPatchFolder)
  Dir.chdir("#{stagingAreaFolder}") do
    cmdOpts = "tar -zcvf #{combinedPatchFolderBasename}.tar.gz #{combinedPatchFolderBasename}"
    puts "#{cmdOpts}"
    cmdRetVal = system("#{cmdOpts}")
    raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal
  end

  puts "****************************************"
  puts "Done with all patch evaluations"
  puts "****************************************"
  puts "Run:"
  puts "scp #{stagingAreaFolder}/#{combinedPatchFolderBasename}.tar.gz ubuntu@vm2:/tmp/iteration"
  puts ""
end
