#!/usr/bin/env python
"""
Get predictions for video using DetectorOutput Class
"""

import matplotlib.pyplot as plt
import numpy as np
import DetectorOutput as DO
import glob
import cv2
import matplotlib.cm as cm
from matplotlib.patches import Rectangle
import os
import time
import csv
import sys

def main(argv):
    if len( argv ) < 6:
        print 'Usage %s <baseFolder> <videoName> <detectorThreshold> <hitThreshold> <showHeatMap>' % argv[ 0 ]
        return -1
    # get params from command line
    baseFolder = argv[1]
    videoName = argv[2]
    detectorThreshold = float(argv[3])
    hitThreshold = int(argv[4])
    showHeatMap = int(argv[5])
    videoFolder = os.path.join(baseFolder, videoName)

    # copy/paste from original Process_Detector_Output.py
    ImagesDir = os.path.join(videoFolder, videoName)

    # CSV file containing the summary of all the json files (in the format Evan sent me)
    ResultsFile = os.path.join(videoFolder, videoName + "_results.csv")

    # OutputDir (By default lets assumed the output is a folder called output within the images directory). Set this to something else if desired
    OutputDir = os.path.join(videoFolder,"combined_patches")

    #Scores saved to this csv
    CSVputFileName = os.path.join(videoFolder, videoName + "_combined_patches_results.csv")

    # Image extension
    ImgExt = '*.png';
    # If the CAFFE detector value is greater than this consider it positive
    DetectorThreshold = detectorThreshold;  # If value is greater than this consider it a positive
    # Hit Threshold: If any given pixel is flagged as 'true' this many times, then consider the frame positive
    HitThreshold = hitThreshold;

    # Show Heatmap option (slower)
    ShowHeatMap = showHeatMap;
    ## Code Below ################################################################
    # Create output directory if needed
    if os.path.exists(OutputDir):   # Delete all files in the directory
        filelist = glob.glob(OutputDir+"//"+ImgExt)
        for f in filelist:
            os.remove(f)        
    else:
        os.makedirs(OutputDir);


    # Parse detector output file
    D = DO.DetectorOutput();
    D = D.readFile(ResultsFile);

    # Iterate through each of the images
    # Gather all image files in the directory
    ImgFiles = [];
    ImgFiles.extend(glob.glob(ImagesDir+"/"+ImgExt))

    # Iterate through each image
    plt.close('all')
    Frames = np.zeros((len(ImgFiles),1),dtype='int8');
    OutputList = [];
    k = 0;
    start_time = time.time();
    for ImgFile in ImgFiles:   
        # Read image
        im1 = cv2.imread(ImgFile);
        im = cv2.cvtColor(im1,cv2.COLOR_BGR2GRAY)

        # Get the detector output for this result
        path, filename = os.path.split(ImgFile)
        S = D.getDetectorOutput(filename);
        imSz = im.shape;
        
        # Iterate through the results and create a map
        imMask = np.zeros(im.shape,dtype='single');
        for s in np.arange(0,S.shape[0]):
            Scale = S[s,0];
            RowStart = np.round(S[s,2]/Scale);
            ColStart = np.round(S[s,1]/Scale);
            RowEnd   = np.floor(RowStart + np.round(S[s,4]/Scale));
            ColEnd   = np.floor(ColStart + np.round(S[s,3]/Scale));
            TrueVal  = np.asarray(S[s,5] > DetectorThreshold)*1.0;
            imMask[RowStart:RowEnd,ColStart:ColEnd] += TrueVal;
            #if TrueVal:
                #print "Found One" + str(Scale) + " @ " + str(RowStart) + " , " + str(ColStart) 
                #Ax = plt.gca();
                #Ax.add_patch(Rectangle((ColStart+1,RowStart+1),ColEnd-ColStart,RowEnd-RowStart, ec="r", fc='none'))
                #plt.draw()
        
        #retval,imMaskThresh = cv2.threshold(imMask,3,1,cv2.THRESH_BINARY);
        
        # Is the frame 'true'/'false'
        OutPrefix = '0';
        if imMask.max() >= HitThreshold:
            Frames[k] = 1;
            OutPrefix = '1';
                
        # Output file with a prefix depending on whether it has a prefix
        path, filename = os.path.split(ImgFile)
        newFileName = os.path.join(OutputDir, OutPrefix+"_"+filename)
        cv2.imwrite(newFileName,im1);
                
        if ShowHeatMap:
            fig=plt.figure(1);
            plt.subplot(1,2,1)
            plt.imshow(im,cmap = cm.gray);
            ax2 = plt.subplot(1,2,2);
            plt.imshow(imMask); 
            #plt.colorbar( orientation='horizontal')
            heatFileName = os.path.join(OutputDir, OutPrefix+"_Heat_"+OutputFileName)
            plt.savefig(heatFileName, bbox_inches='tight');
            # Close all figures
            plt.close('all')
            
        OutputList.append([filename,Frames[k].tolist()[0]])
        # Show progress
        if k%10 == 0:
            print str(k) + "/" + str(len(ImgFiles)) + " in " + str(time.time()-start_time) + " s!"
        k = k+1
        
    # write CSV as well
    with open(CSVputFileName,"wb") as f:
        writer = csv.writer(f);
        writer.writerows(OutputList)


if __name__ == '__main__':
    main(sys.argv)
