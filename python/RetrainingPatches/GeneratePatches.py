#!/usr/bin/python

# -*- coding: utf-8 -*-
"""
Created on Fri Jun 27 10:22:15 2014

@author: amit.bohara
"""

import pdb
import sys, os, glob
import shutil
import csv
import DetectorOutput as DO

def ProcessOutput(OutputCSV,PosFramesFile,PatchDir,OutDir):
    DetectorThreshold = 0.5;
    
    # Read file containing csv file generated from CAFFE
    print "Reading CAFFE output"
    D = DO.DetectorOutput();
    D = D.readFile(OutputCSV);
    print " ... done!"
    
    # Read Positive Frames File
    PositiveFrames = {};
    with open(PosFrames,'rb') as f:
        reader = csv.reader(f);
        for row in reader:
            PositiveFrames[row[0].replace('.png','')] = 1;
    print "Positive frame list read"
    
    # Create output directory if needed
    if os.path.exists(OutDir):   # Delete all files in the directory
        filelist = glob.glob(OutDir+"//*.png")
        for f in filelist:
            os.remove(f)        
    else:
        os.makedirs(OutDir);
        
    # Find all the patches belonging to frames that do not belong in the positive patch list
    print "Accumulating output patches"
    frames = D.getFramesList();

    PatchScores = {};
    for f in frames:
        if PositiveFrames.get(f) != 1:   # If the frame is not in 'annotated' frames
            # Get all 'positive' patches belonging to this frame
            S = D.getPatchScores(f);
            PatchScores.update(S);
    
    # Deleting patches with low values
    print "Excluding patches belonging to negative set"
    Keys = PatchScores.keys();
    print "  " + str(len(Keys)) + " to start with"
    for key in Keys:
        #pdb.set_trace();
        if float(PatchScores[key]) < DetectorThreshold:
            del PatchScores[key]
    print "  " + str(len(PatchScores)) + " after filtering"
    # Sorting Patches 
    print "Sorting patches"
    SortedKeys = sorted(PatchScores,key=PatchScores.get,reverse=True);
    print "Found %s patches to export " %len(SortedKeys)
    # Copy patches to output folder
    rank = 1;
    for s in SortedKeys:    # s is the patchname with extension i.e. .png
        srcFile = PatchDir + "\\" + s;
        dstFile = OutDir + "\\" + str(rank) +"_"+s        
        if rank%1000 == 0:
            print str(rank) +" of "+str(len(SortedKeys))
        try:
            #pdb.set_trace()
            rank += 1;
            shutil.copy(srcFile,dstFile);
            #print "copied " + s
        except:
            rank;
            #print "copying error on " + s
    
if __name__ == '__main__':
  if len( sys.argv ) != 5:
      print 'Usage %s <Output_CSV_File> <File containing names of positive frames> <Directory containing Patches> <OutputDirectory>' % sys.argv[ 0 ]
      print 'Dont include trailing "\\" slash in directory names'
      BaseDir = "C:\Users\amit.bohara\Documents\Logo\S3\VxOQWgcLNSk";
      PosFrames = 'C:\Users\\amit.bohara\Documents\Logo\S3\\gHUp_cT3t30\Output\curated\\adidas-positives.txt';
      OutputCSV = 'C:\Users\\amit.bohara\Documents\Logo\S3\gHUp_cT3t30\Output\gHUp_cT3t3o_results.csv';
      PatchDir = 'C:\Users\\amit.bohara\Documents\Logo\S3\\gHUp_cT3t30\Output\Patches';
      OutDir = 'C:\Users\\amit.bohara\Documents\Logo\S3\gHUp_cT3t30\Output\PatchesToProcess';
  
      ProcessOutput(OutputCSV,PosFrames,PatchDir,OutDir)
  else:
      print 'Ok'
      OutputCSV = sys.argv[1];
      PosFrames = sys.argv[2];
      PatchDir  = sys.argv[3];
      OutDir    = sys.argv[4];