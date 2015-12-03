#!/usr/bin/env ruby

require 'fileutils'
require 'csv'
require 'json'
require 'thread'

if __FILE__ == $0
  baseKhajuriFolder = "/home/ubuntu/khajuri"

  baseVideoFolder = "/mnt/data/video_analysis/videos/kheer_idied/production"


  # scripts
  khajurVideoFrameExtractor = "#{baseKhajuriFolder}/tool/VideoFramesExtractor.py"

  if ARGV.count != 2
    puts "This script extracts frames from video for export to cellroti."
    puts "Additionally, it also creates thumbnails required for cellroti."
    puts " "
    puts "Prior to running this script please place/link all required videos in:"
    puts "#{baseVideoFolder}/<videoId>"
    puts " "
    puts "Ensure that all export configuration is found in <kheerExportFolder>"
    puts "The files therein should match what kheer exports"
    puts " "
    puts "All frames and thumbnails are saved in:"
    puts "<outputFolder>/<videoId>/frames"
    puts "<outputFolder>/<videoId>/thumbnails"
    puts " "
    puts "Usage: ~/chia/ruby/extract_frames_for_cellroti.rb <kheerExportFolder> <outputFolder>"
    exit
  end

  kheerExportFolder = ARGV[0]
  outputFolder = ARGV[1]

  FileUtils.rm_rf(outputFolder)
  FileUtils.mkdir_p(outputFolder)

  # ensure that videos exist
  videoMap = []
  filemapFile = "#{kheerExportFolder}/filemap.json"
  fileMapHash = JSON.load(File.open(filemapFile))

  fileMapHash.each do |videoId, fileDetails|
    videoFile = "#{baseVideoFolder}/#{videoId}.mp4"
    raise "No video present for video id #{videoId}" if not File.exists?(videoFile)

    framesToExtractFile = "#{kheerExportFolder}/#{fileDetails['frames_to_extract']}"
    raise "No frames to extract file present for video id #{videoId}" if not File.exists?(framesToExtractFile)

    framesOutputFolder = "#{outputFolder}/#{fileDetails['cellroti_video_id']}/frames"
    thumbnailsOutputFolder = "#{outputFolder}/#{fileDetails['cellroti_video_id']}/thumbnails"

    videoMap << {
      videoFile: videoFile,
      framesToExtractFile: framesToExtractFile,
      framesOutputFolder: framesOutputFolder,
      thumbnailsOutputFolder: thumbnailsOutputFolder
    }
  end

  puts "****************************************"
  puts "Extracting frames"
  puts "****************************************"
  puts ""
  # parallelize video extraction
  work_q = Queue.new
  videoMap.each{|videoDetails| work_q.push videoDetails }
  workers = (0...16).map do
    Thread.new do
      begin
        while videoDetails = work_q.pop(true)
          videoFile = videoDetails[:videoFile]
          framesToExtractFile = videoDetails[:framesToExtractFile]
          framesOutputFolder = videoDetails[:framesOutputFolder]
          thumbnailsOutputFolder = videoDetails[:thumbnailsOutputFolder]

          FileUtils.mkdir_p(framesOutputFolder)

          cmdOpts = "#{khajurVideoFrameExtractor} #{videoFile} #{framesToExtractFile} #{framesOutputFolder}"
          puts "#{cmdOpts}"
          cmdRetVal = system("#{cmdOpts}")
          raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

          # convert to jpg format
          cmdOpts = "mogrify -format jpg #{framesOutputFolder}/*.png && rm -rf #{framesOutputFolder}/*.png"
          puts "#{cmdOpts}"
          cmdRetVal = system("#{cmdOpts}")
          raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

          # copy to thumbnails folder
          FileUtils.cp_r(framesOutputFolder, thumbnailsOutputFolder)

          # resize to thumbnails
          cmdOpts = "mogrify -resize 200x113 #{thumbnailsOutputFolder}/*.jpg"
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
  puts "Done - Can send frames to cellroti"
  puts "****************************************"
  puts ""
end
