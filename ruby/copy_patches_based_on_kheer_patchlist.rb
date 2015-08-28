#!/usr/bin/env ruby

require 'fileutils'
require 'csv'
require 'json'

if __FILE__ == $0
  if ARGV.count < 3
    puts "Copy patches from specified environment input folder to staging area "
    puts "based on patch list from kheer for retraining or QA purposes."
    puts "This script assumes certain internal folder structure of input folder.Typically:"
    puts "baseInputFolder:"
    puts "/disk1/model_retraining/patches/production"
    puts "baseOutputFolder:"
    puts "/disk1/model_retraining/staging_area/patches"
    puts " "
    puts "Usage: ./copy_patches_based_on_kheer_patchlist.rb <patchListFile> <baseInputFolder> <baseOutputFolder>"
    exit
  end

  patchListFile = ARGV[0]
  baseInputFolder = ARGV[1]
  baseOutputFolder = ARGV[2]

  FileUtils.rm_rf(baseOutputFolder)
  FileUtils.mkdir_p(baseOutputFolder)

  # format
  # {patchBasename: full_path}
  patchesLocation = {}
  Dir.glob("#{baseInputFolder}/*/patches") do |d|
    if File.directory?(d)
      Dir.glob("#{d}/*/**").each do |f|
        next if File.directory?(f)
        patchesLocation[File.basename(f)] = f
      end
    end
  end

  puts "Start reading JSON file"
  jsonFileHash = JSON.load(File.open(patchListFile))
  puts "Done reading JSON file"

  puts "Start copying files"
  jsonFileHash.each do |clsName, patchList|
    patchOutFolder = File.join(baseOutputFolder, "#{clsName}")
    FileUtils.mkdir_p(patchOutFolder)
    patchList.each do |patchFileName, count|
      # find file
      inFn = patchesLocation[patchFileName]
      raise "Patch not found: #{patchFileName}" if inFn == nil

      # copy
      inFnBase = File.basename(inFn)
      outFn = File.join(patchOutFolder, "#{inFnBase}")
      FileUtils.copy(inFn, outFn)
      if count > 1
        (1..(count - 1)).to_a.each_with_index do |idx|
          outFn = File.join(patchOutFolder, "cpy_#{idx}_#{inFnBase}")
          FileUtils.copy(inFn, outFn)
        end
      end
    end
  end

end
