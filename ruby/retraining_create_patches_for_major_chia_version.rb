#!/usr/bin/env ruby

require 'fileutils'
require 'csv'
require 'json'
require 'thread'

if __FILE__ == $0
  baseChiaFolder = "/home/ubuntu/chia"
  baseKhajuriFolder = "/home/ubuntu/khajuri"

  baseFolder = "/disk1/model_retraining"
  baseVideoFolder = "/mnt/data/video_analysis/videos/kheer_idied/production"

  baseAnnoFolder = "#{baseFolder}/annotations/production"
  baseFrameFolder = "#{baseFolder}/frames"
  basePatchFolder = "#{baseFolder}/patches/production"
  stagingAreaFolder = "#{baseFolder}/staging_area"

  # scripts
  khajurVideoFrameExtractor = "#{baseKhajuriFolder}/tool/VideoFramesExtractor.py"
  patchExtractor = "#{baseChiaFolder}/python/PatchExtraction/extract_positive_patches.py"
  datasetSplitTest = "#{baseChiaFolder}/ruby/create_dataset_split.rb"
  leveldbCreator = "#{baseChiaFolder}/caffe/build/tools/convert_imageset.bin"

  # configs
  patchExtractorConfig = "#{baseFolder}/configs/python_patch_extraction_config.yaml"
  datasetSplitTestConfig = "#{baseFolder}/configs/ruby_create_test_dataset_config.yaml"

  if ARGV.count != 1
    puts "This script extracts frames and patches based on kheer output. It also"
    puts "creates leveldb for minor iteration consumption"
    puts "It is assumed that this script is run from the following location in GPU1:"
    puts "#{baseFolder}"
    puts " "
    puts "Prior to running this script please place kheer annotations in:"
    puts "#{baseAnnoFolder}/<majorChiaVersionId>"
    puts " "
    puts "Prior to running this script please place/link all required videos in:"
    puts "#{baseVideoFolder}/<videoId>"
    puts " "
    puts "All frames are saved in:"
    puts "#{baseFrameFolder}/<videoId>"
    puts " "
    puts "All patches are saved in:"
    puts "#{basePatchFolder}/<majorChiaVersionId>"
    puts " "
    puts "Usage: ~/chia/ruby/retraining_create_patches_for_major_chia_version.rb <majorChiaVersionId>"
    exit
  end

  chiaVersionId = ARGV[0].split(".")[0]

  # check if running from right place
  if Dir.pwd != baseFolder
    raise "Need to run this script from #{baseFolder}"
  end

  # check if annotations exist
  cvAnnoFolder = "#{baseAnnoFolder}/#{chiaVersionId}"
  if not Dir.exists?(cvAnnoFolder)
    raise "Need annotations for chiaVersionId #{chiaVersionId} at: #{cvAnnoFolder}"
  end

  # ensure that videos exist
  videoIds = []
  Dir.glob("#{cvAnnoFolder}/*").each do |d|
    if File.directory?(d)
      videoId = File.basename(d).to_i
      videoIds << videoId
      # ensure that annotations are present
      frameIdFile = "#{d}/frame_ids.txt"
      raise "No frame ids present for video id #{videoId}" if not File.exists?(frameIdFile)
      annoFolder = "#{d}/annotations"
      raise "No annotations present for video id #{videoId}" if not File.exists?(annoFolder)
      videoFile = "#{baseVideoFolder}/#{videoId}.mp4"
      raise "No video present for video id #{videoId}" if not File.exists?(videoFile)
    end
  end
  videoIds.sort!

  puts "****************************************"
  puts "Extracting frames from following videos: #{videoIds}"
  puts "****************************************"
  puts ""
  # parallelize video extraction
  work_q = Queue.new
  videoIds.each{|videoId| work_q.push videoId }
  workers = (0...16).map do
    Thread.new do
      begin
        while videoId = work_q.pop(true)
          videoFile = "#{baseVideoFolder}/#{videoId}.mp4"
          frameIdFile = "#{cvAnnoFolder}/#{videoId}/frame_ids.txt"
          frameFolder = "#{baseFrameFolder}/#{videoId}"
          FileUtils.mkdir_p(frameFolder)
          cmdOpts = "#{khajurVideoFrameExtractor} #{videoFile} #{frameIdFile} #{frameFolder} #{videoId}"
          puts "#{cmdOpts}"
          cmdRetVal = system("#{cmdOpts}")
          raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal
        end
      rescue ThreadError
      end
    end
  end
  workers.map(&:join)

  puts "****************************************"
  puts "Extracting patches"
  puts "****************************************"
  puts ""

  cvPatchFolder = "#{basePatchFolder}/#{chiaVersionId}"
  FileUtils.mkdir_p(cvPatchFolder)

  # create symlinks of all frames/annotations to a common location
  inImagesFolder = "#{cvPatchFolder}/images"
  FileUtils.rm_rf(inImagesFolder)
  FileUtils.mkdir_p(inImagesFolder)
  videoIds.each do |videoId|
    frameFolderFiles = Dir.glob("#{baseFrameFolder}/#{videoId}/*.png")
    frameFolderFiles.each do |frameFolderFile|
      FileUtils.ln_sf(frameFolderFile, inImagesFolder)
    end
  end

  inAnnotationFolder = "#{cvPatchFolder}/annotations"
  FileUtils.rm_rf(inAnnotationFolder)
  FileUtils.mkdir_p(inAnnotationFolder)
  videoIds.each do |videoId|
    videoAnnoFiles = Dir.glob("#{cvAnnoFolder}/#{videoId}/annotations/*.json")
    videoAnnoFiles.each do |videoAnnoFile|
      FileUtils.ln_sf(videoAnnoFile, inAnnotationFolder)
    end
  end

  # extract patches - the output is in patches folder
  outPatchFolder = "#{cvPatchFolder}/patches"
  FileUtils.rm_rf(outPatchFolder)
  FileUtils.mkdir_p(outPatchFolder)
  cmdOpts = "#{patchExtractor} #{patchExtractorConfig} #{cvPatchFolder} #{cvPatchFolder}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal


  puts "****************************************"
  puts "Creating LevelDb"
  puts "****************************************"
  puts ""
  # split dataset as test
  outLeveldbFolder = "#{cvPatchFolder}/leveldb"
  FileUtils.rm_rf(outLeveldbFolder)
  FileUtils.mkdir_p(outLeveldbFolder)
  cmdOpts = "#{datasetSplitTest} #{datasetSplitTestConfig} #{outPatchFolder} #{outLeveldbFolder}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

  leveldbLabelFile = "#{outLeveldbFolder}/leveldb_labels.txt"
  outLeveldbDb = "#{outLeveldbFolder}/leveldb"
  # we shouldn't randomize for testing purposes
  cmdOpts = "#{leveldbCreator} #{outPatchFolder}/ #{leveldbLabelFile} #{outLeveldbDb}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

  # clean up
  FileUtils.rm_rf(inImagesFolder)
  FileUtils.rm_rf(inAnnotationFolder)

  puts "****************************************"
  puts "Done - Can start mini iterations now"
  puts "****************************************"
  puts ""
end
