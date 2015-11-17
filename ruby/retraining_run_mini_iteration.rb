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
  datasetSplitTrain = "#{baseChiaFolder}/ruby/create_dataset_split.rb"
  leveldbCreator = "#{baseChiaFolder}/caffe/build/tools/convert_imageset.bin"
  caffeFineTuner = "#{baseChiaFolder}/caffe/build/tools/finetune_net.bin"

  # configs
  datasetSplitTrainConfig = "#{baseFolder}/configs/ruby_create_train_dataset_config.yaml"
  caffeProtoSolver = "#{baseFolder}/configs/logo_solver.prototxt"
  caffeProtoTrain = "#{baseFolder}/configs/logo_train.prototxt"
  caffeProtoVal = "#{baseFolder}/configs/logo_val.prototxt"
  staticTestPatchFolderLarge = "#{baseFolder}/configs/staticTestPatchesForModelCreation/test_1000"
  staticTestPatchFolderSmall = "#{baseFolder}/configs/staticTestPatchesForModelCreation/test_100"

  numIterationMajorVersion = 5000
  numIterationMinorVersion = 3000

  if ARGV.count != 2
    puts "This script copies relevant patches from kheer and trains a new model."
    puts "Using the newly trained model, it then evaluates all patches for import into kheer."
    puts "It is assumed that this script is run from the following location in GPU1:"
    puts "#{baseFolder}"
    puts " "
    puts "It is assumed that caffe models are stored in:"
    puts "#{baseModelFolder}/chiaVersionId[major.minor]"
    puts "Specify minor version = 0 for finalized versions used in video evaluation"
    puts " "
    puts "If this is the first mini-iteration, ensure that major iteration script"
    puts "has been successfully run for all chia versions prior to this iteration"
    puts " "
    puts "<patchListFile> is exported from kheer and needs to be placed in staging area:"
    puts "#{stagingAreaFolder}/patch_list_file.json"
    puts " "
    puts "Usage: ~/chia/ruby/retraining_run_mini_iteration.rb <patchListFile> <newChiaVersionId[major.minor]> "
    exit
  end

  patchListFile = ARGV[0]
  chiaVersionIdMajor = ARGV[1].split(".")[0].to_i
  chiaVersionIdMinor = ARGV[1].split(".")[1].to_i

  # check if running from right place
  if Dir.pwd != baseFolder
    raise "Need to run this script from #{baseFolder}"
  end

  # model folder and iteration based on major vs. minor difference
  referenceModelFile = nil
  numIteration = numIterationMajorVersion
  if chiaVersionIdMinor != nil and chiaVersionIdMinor != 0
    modelFolder = "#{baseModelFolder}/#{chiaVersionIdMajor}.#{chiaVersionIdMinor}"
    numIteration = numIterationMinorVersion
    if (chiaVersionIdMinor - 1) == 0
      referenceModelFolder = "#{baseModelFolder}/#{chiaVersionIdMajor}"
      referenceModelFile = "#{referenceModelFolder}/caffe_logo_train_iter_#{numIterationMajorVersion}"
    else
      referenceModelFolder = "#{baseModelFolder}/#{chiaVersionIdMajor}.#{chiaVersionIdMinor - 1}"
      referenceModelFile = "#{referenceModelFolder}/caffe_logo_train_iter_#{numIterationMinorVersion}"
    end
    staticTestPatchFolder = staticTestPatchFolderSmall
  else
    modelFolder = "#{baseModelFolder}/#{chiaVersionIdMajor}"
    numIteration = numIterationMajorVersion
    largestMinorCVId = 0
    Dir.glob("#{baseModelFolder}/#{chiaVersionIdMajor - 1}/*").each do |cvId|
      next if not File.directory?(cvId)
      minorCVId = cvId.split(".")[1].to_i
      largestMinorCVId = minorCVId if (minorCVId != nil and minorCVId > largestMinorCVId)
    end
    if largestMinorCVId == 0
      referenceModelFile = "#{baseModelFolder}/#{chiaVersionIdMajor - 1}/caffe_logo_train_iter_#{numIterationMajorVersion}"
    else
      referenceModelFile = "#{baseModelFolder}/#{chiaVersionIdMajor - 1}.#{largestMinorCVId}/caffe_logo_train_iter_#{numIterationMinorVersion}"
    end
    staticTestPatchFolder = staticTestPatchFolderLarge
  end
  modelFileBaseName = "caffe_logo_train_iter_#{numIteration}"

  # don't continue if a model already exists
  raise "Model folder already exists: please delete before continuing: #{modelFolder}" if File.exists?(modelFolder)
  FileUtils.mkdir_p(modelFolder)
  # check model reference file exists
  raise "Reference model doesn't exist at #{referenceModelFile}" if not File.exists?(referenceModelFile)

  puts "Using reference model: #{referenceModelFile}"
  puts "Output model: #{modelFolder}/#{modelFileBaseName}"

  logFolder = "#{stagingAreaFolder}/logs"
  FileUtils.mkdir_p(logFolder)

  stagingRetrainingFolder = "#{stagingAreaFolder}/retraining"
  FileUtils.rm_rf(stagingRetrainingFolder)
  FileUtils.mkdir_p(stagingRetrainingFolder)

  puts "****************************************"
  puts "Copying/linking files to staging area"
  puts "****************************************"
  puts ""
  # modify proto files
  stagingCaffeProtoSolver = "#{stagingRetrainingFolder}/#{File.basename(caffeProtoSolver)}"
  solverPrototxtData = File.read(caffeProtoSolver)
  modifiedSolverPrototxtData = solverPrototxtData.gsub("solverMaxIteration", "#{numIteration}") 
  # open the file for writing
  File.open(stagingCaffeProtoSolver, "w") do |f|
    f.write(modifiedSolverPrototxtData)
  end

  stagingCaffeProtoTrain = "#{stagingRetrainingFolder}/#{File.basename(caffeProtoTrain)}"
  FileUtils.ln_sf(caffeProtoTrain, stagingCaffeProtoTrain)

  stagingCaffeProtoVal = "#{stagingRetrainingFolder}/#{File.basename(caffeProtoVal)}"
  FileUtils.ln_sf(caffeProtoVal, stagingCaffeProtoVal)

  # copy patch list files
  # format
  # {patchBasename: full_path}
  patchesLocation = {}
  Dir.glob("#{basePatchFolder}/*/patches") do |d|
    if File.directory?(d)
      Dir.glob("#{d}/*/**").each do |f|
        next if File.directory?(f)
        patchesLocation[File.basename(f)] = f
      end
    end
  end

  retrainingPatchesOrigFolder = "#{stagingRetrainingFolder}/patches_original"
  retrainingTrainPatchesFolder = "#{retrainingPatchesOrigFolder}/train"
  FileUtils.mkdir_p(retrainingTrainPatchesFolder)
  patchListHash = JSON.load(File.open(patchListFile))
  patchListHash.each do |clsName, patchList|
    patchOutFolder = File.join(retrainingTrainPatchesFolder, "#{clsName}")
    FileUtils.mkdir_p(patchOutFolder)
    patchList.each do |patchFileName, count|
      # find file
      inFn = patchesLocation[patchFileName]
      raise "Patch not found: #{patchFileName}" if inFn == nil

      # link to original - duplicate where necessary
      inFnBase = File.basename(inFn)
      outFn = File.join(patchOutFolder, "#{inFnBase}")
      FileUtils.ln_sf(inFn, outFn)
      if count > 1
        (1..(count - 1)).to_a.each_with_index do |idx|
          outFn = File.join(patchOutFolder, "cpy_#{idx}_#{inFnBase}")
          FileUtils.ln_sf(inFn, outFn)
        end
      end
    end
  end

  retrainingTestPatchesFolder = "#{retrainingPatchesOrigFolder}/test"
  FileUtils.ln_sf(staticTestPatchFolder, retrainingTestPatchesFolder)

  puts "****************************************"
  puts "Creating LevelDb"
  puts "****************************************"
  puts ""

  # split dataset for training
  retrainingPatchesResizedFolder = "#{stagingRetrainingFolder}/patches_resized"
  FileUtils.rm_rf(retrainingPatchesResizedFolder)
  FileUtils.mkdir_p(retrainingPatchesResizedFolder)
  dataSplitTrainLog = "logFolder/dataSplitTrainLog.log"
  cmdOpts = "#{datasetSplitTrain} #{datasetSplitTrainConfig} #{retrainingPatchesOrigFolder} #{retrainingPatchesResizedFolder}   2>&1 | tee #{dataSplitTrainLog}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

  leveldbFolder = "#{stagingRetrainingFolder}/leveldb"
  FileUtils.rm_rf(leveldbFolder)
  FileUtils.mkdir_p(leveldbFolder)

  trainLeveldbFolder = "#{leveldbFolder}/train"
  trainPatchesFolder = "#{retrainingPatchesResizedFolder}/train"
  trainPatchesFileLabels = "#{trainPatchesFolder}/train_labels.txt"
  trainLeveldbLog = "logFolder/trainLeveldbLog.log"
  # need a 1 in the end to create random patches for finetune
  cmdOpts = "#{leveldbCreator} #{trainPatchesFolder}/ #{trainPatchesFileLabels} #{trainLeveldbFolder} 1   2>&1 | tee #{trainLeveldbLog}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal

  testLeveldbFolder = "#{leveldbFolder}/test"
  testPatchesFolder = "#{retrainingPatchesResizedFolder}/test"
  testPatchesFileLabels = "#{testPatchesFolder}/test_labels.txt"
  testLeveldbLog = "logFolder/testLeveldbLog.log"
  # need a 1 in the end to create random patches for finetune
  cmdOpts = "#{leveldbCreator} #{testPatchesFolder}/ #{testPatchesFileLabels} #{testLeveldbFolder} 1   2>&1 | tee #{testLeveldbLog}"
  puts "#{cmdOpts}"
  cmdRetVal = system("#{cmdOpts}")
  raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal


  puts "****************************************"
  puts "Training model"
  puts "****************************************"
  puts ""
  # need to chdir to staging retraining directory
  Dir.chdir("#{stagingRetrainingFolder}") do
    caffeFineTunerLog = "logFolder/caffeFineTunerLog.log"
    cmdOpts = "GLOG_logtostderr=1 #{caffeFineTuner} #{stagingCaffeProtoSolver} #{referenceModelFile}   2>&1 | tee #{caffeFineTunerLog}"
    puts "#{cmdOpts}"
    cmdRetVal = system("#{cmdOpts}")
    raise "Couldn't execute: \n#{cmdOpts}" if not cmdRetVal
  end

  FileUtils.cp("#{stagingRetrainingFolder}/#{modelFileBaseName}", "#{modelFolder}")
  FileUtils.cp("#{retrainingPatchesResizedFolder}/label_mappings.txt", "#{modelFolder}")

  puts "****************************************"
  puts "Done training model - can start patch evaluation now"
  puts "****************************************"
  puts "Run:"
  puts "~/chia/ruby/retraining_evaluate_all_patches_with_chia_version.rb #{ARGV[1]}"
  puts ""
end
