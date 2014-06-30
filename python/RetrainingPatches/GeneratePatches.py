#!/usr/bin/python

# -*- coding: utf-8 -*-
"""
Created on Fri Jun 27 10:22:15 2014

@author: amit.bohara
"""

import pdb
import sys, os, glob
import shutil,shelve
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
    try:
        with open(PosFrames,'rb') as f:
            reader = csv.reader(f);
            for row in reader:
                PositiveFrames[row[0].replace('.png','')] = 1;
        print "Positive frame list read"
    except:
        print "Positive file not read"

    
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
    PatchRects = {};
    PatchParentFrame = {};
    for f in frames:
        if PositiveFrames.get(f) != 1:   # If the frame is not in 'annotated' frames
            # Get all 'positive' patches belonging to this frame
            S,P,F = D.getPatchScores(f);
            PatchScores.update(S);
            PatchRects.update(P);
            PatchParentFrame.update(F);
            
    # Deleting patches with low values
    print "Excluding patches belonging to negative set"
    PatchNames = PatchScores.keys();
    print "  " + str(len(PatchNames)) + " to start with"
    for PatchName in PatchNames:
        #pdb.set_trace();
        if float(PatchScores[PatchName]) < DetectorThreshold:
            del PatchScores[PatchName]
            del PatchRects[PatchName]
            del PatchParentFrame[PatchName]
            
    print "  " + str(len(PatchScores)) + " patches aftering filtering for low scores"
    
    # Find any overlapping patches
    # a. Iterate through each of the patches
    PatchNames = PatchScores.keys();
    ParentPatches = {};
    for PatchName in PatchNames:
        # Get all patches in this frame bigger than this patch
        #pdb.set_trace()
        patchscale = PatchRects[PatchName][0];
        patchframe = PatchParentFrame[PatchName];
        AllLargerPatches = D.getLargerPatchesInFrame(patchframe,patchscale);
        # Intersect these with the patches we have so far
        LargerPatches = list(set(AllLargerPatches).intersection(set(PatchNames)));
        # Iterate through the larger patches and find if there are any that encompass this patch
        PatchPos = PatchRects[PatchName][1:]    # x,y,width,height
        
        ParentPatch = PatchName;    # Set itself as the parent patch by default
        ParentPatchArea = PatchPos[2]*PatchPos[3]/(patchscale**2)
        for largerPatch in LargerPatches:
            LPatchPos = PatchRects[largerPatch][1:]   # x,y,width,height
            LPatchScale = PatchRects[largerPatch][0];
            # Does the larger patch contain the smaller patch ?
            if PatchPos[0]/patchscale > LPatchPos[0]/LPatchScale and \
                (PatchPos[0]+PatchPos[2])/patchscale < (LPatchPos[0]+LPatchPos[2])/LPatchScale and \
                PatchPos[1]/patchscale > LPatchPos[1]/LPatchScale and \
                (PatchPos[1]+PatchPos[3])/patchscale < (LPatchPos[1]+LPatchPos[3])/LPatchScale and \
                (LPatchPos[2]*LPatchPos[3]) > ParentPatchArea:
                    ParentPatch = largerPatch;
                    ParentPatchArea = (LPatchPos[2]*LPatchPos[3])/(LPatchScale**2);
        ParentPatches[PatchName] = ParentPatch;
        
        #if PatchName != ParentPatch:
        #    print "Parent: " + ParentPatch + " for " + PatchName
    PatchesToWrite = set(ParentPatches.values());   # Get all the unique parent pathes
    print "After removing overlapping patches, "+ str(len(PatchesToWrite)) +" remain!"
    
    # Write patches to file
    print "Copying "+ str(len(PatchesToWrite))+ " to output folder"
    CopyError = False;
    r = 1;
    for patchName in PatchesToWrite:
        srcFile = PatchDir + "\\" + patchName;
        score = str(int(round(100*PatchScores[patchName])));
        dstFile = OutDir + "\\"  + score +"_"+patchName;        
        if r%1000 == 0:
            print str(r) +" of "+str(len(PatchesToWrite))
        try:
            #pdb.set_trace()            
            shutil.copy(srcFile,dstFile);
            r += 1;
            #print "copied " + s
        except:
            if CopyError == False:  # Show error once
                print "  ** Unable to copy some patches. Likely reason is that patchces stated in the CAFFE output file do not exist in the patches dir"
                CopyError = True;
            
    #pdb.set_trace();

    # Save dictionary objects to file for second run
    FileObj = shelve.open(OutDir+"\\PatchInfo");
    FileObj['ParentPatches'] = ParentPatches;
    FileObj['OutDir'] = OutDir;
    FileObj ['PatchScores'] = PatchScores;
    FileObj['PatchRects'] = PatchRects;
    FileObj['PatchDir'] = PatchDir;
    FileObj.close();

def OutputFinalPatches(StartDir):
    # Load intermediate files
    FileObj = shelve.open(StartDir+"\\PatchInfo");
    ParentPatches = FileObj['ParentPatches'];
    OutDir = FileObj['OutDir'];
    PatchScores = FileObj ['PatchScores'];
    PatchRects = FileObj['PatchRects'];
    PatchDir = FileObj['PatchDir'];
    FileObj.close();

    # Get a list of all patchnames in the directory. These are assumbed to 'negatives'
    ImgFiles = [];
    ImgFiles.extend(glob.glob(StartDir+"/*.png"))
    
    # Create a final directory
    FinalDir = StartDir + "\\FPForRetraining";
    # Create output directory if needed
    if os.path.exists(FinalDir):   # Delete all files in the directory
        filelist = glob.glob(FinalDir+"//*.png")
        for f in filelist:
            os.remove(f)        
    else:
        os.makedirs(FinalDir);
    
    # Output patches to Final direcotyr only If their parent is the ImgFiles list , which makes them false positives
    PatchNames = PatchScores.keys();
    r = 1; CopyError = False;
    for PatchName in PatchNames:
        PatchParent = ParentPatches[PatchName];
        # Check if the patchparent is in any of the image files
        OutputPatch = False;
        for imgFileName in ImgFiles:
            if PatchParent in imgFileName:
                OutputPatch = True;
        # Output patch
        if OutputPatch:
            srcFile = PatchDir + "\\" + PatchName;
            dstFile = FinalDir + "\\"  +PatchName;        
        if r%1000 == 0:
            print str(r) +" patches copied "
        try:
            #pdb.set_trace()            
            shutil.copy(srcFile,dstFile);
            r += 1;
            #print "copied " + s
        except:
            if CopyError == False:
                print "  ** Unable to copy some patches. Likely reason is that patchces stated in the CAFFE output file do not exist in the patches dir"
                CopyError = True;

    
    
if __name__ == '__main__':
  #print len(sys.argv)
  #print sys.argv;
  if len(sys.argv) == 2:   # Called the second time with just the patch directory
      print "Running final patch generation"
  elif len(sys.argv) == 5:
      print 'Ok'
      OutputCSV = sys.argv[1];
      PosFrames = sys.argv[2];
      PatchDir  = sys.argv[3];
      OutDir    = sys.argv[4];
      ProcessOutput(OutputCSV,PosFrames,PatchDir,OutDir)
  else:
      print 'Usage %s <Output_CSV_File> <File containing names of positive frames> <Directory containing Patches> <OutputDirectory>' % sys.argv[ 0 ]
      print 'Dont include trailing "\\" slash in directory names'
      BaseDir = "C:\Users\amit.bohara\Documents\Logo\S3\VxOQWgcLNSk";
      
#      PosFrames = 'C:\Users\\amit.bohara\Documents\Logo\S3\\gHUp_cT3t30\Output\curated\\adidas-positives.txt';
#      OutputCSV = 'C:\Users\\amit.bohara\Documents\Logo\S3\gHUp_cT3t30\Output\gHUp_cT3t3o_results.csv';
#      PatchDir = 'C:\Users\\amit.bohara\Documents\Logo\S3\\gHUp_cT3t30\Output\Patches';
#      OutDir = 'C:\Users\\amit.bohara\Documents\Logo\S3\gHUp_cT3t30\Output\PatchesToProcess';
      #PosFrames = PosFrames.replace('gHUp_cT3t30','ox3-VmNVD9w')
      #ProcessOutput(OutputCSV,PosFrames,PatchDir,OutDir)
      #OutputFinalPatches(OutDir);
      
""" Unused code below:
No need to sort patches
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
"""