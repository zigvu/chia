# -*- coding: utf-8 -*-
"""
Created on Tue Jun 10 09:58:56 2014

@author: Amit

Class for handling bounding box annotations
"""

import csv
import os
import numpy as np

class DetectorOutput():
    
    DetectorOutStruct = { };
    FileName = '';
    
    def __init__(self):
        print "Detector (e.g. Caffe) Output Processing"
        
        
    # Load annotation data from file        
    def readFile(self,DetectorOutputFile):
        
        DetectorOutStruct = { }
        with open(DetectorOutputFile, 'rb') as f:
            reader = csv.reader(f)
            header = False
            for row in reader:
              if not header:
                header = True
                continue
              #key = row[ 0 ].split(',')[0]
              #key = row[1].replace('.xml','');
              key = row[1].replace('.png','');
              val = row[2:];
              
              if DetectorOutStruct.get( key ):
                DetectorOutStruct[ key ].append(val) #( DetectorOutStruct( *val ) )
              else:
                DetectorOutStruct[ key ] = [val]; #[ DetectorOutStruct( *val ) ]
                        
        self.DetectorOutStruct = DetectorOutStruct;
        self.FileName = DetectorOutputFile;
        return self;
    
    # Get all the frame names
    def getFramesList(self):
        Frames = self.DetectorOutStruct.keys();
        return Frames;
        
    # Get all patches (with patch id) and scores (in a dictionary)
    def getPatchScores(self,frameName):
        # Initialize empty 
        PatchScores = {};
        # Extract filename without extension
        key = os.path.splitext(frameName)[0];
        # Iterate through the results
        if self.DetectorOutStruct.get(key):
            P = self.DetectorOutStruct.get(key);
            for k in P:
                # k is a list of [jsonfile,frameid,patchname,x,y,width,height,score_1,score_0]
                PatchScores[k[2]] = k[7];
        return PatchScores;
        
    # Get all detector output for specified frame
    def getDetectorOutput(self,frameName,Scale=None):
        # Initialize empty
        Output = [];
        # Extract filename without extension
        key = os.path.splitext(frameName)[0];
        # The key is the framename (with .png)
        if self.DetectorOutStruct.get(key):
            # Return all results (for all scales) belonging to this key
            TotalRecords = len(self.DetectorOutStruct.get(key));
            # Return all detector output for this frame
            Output = np.zeros([TotalRecords, 7]);    #Scale,X,Y,Width,Height,TrueScore,FalseScore
            for a in range(0,TotalRecords):
                Val = self.DetectorOutStruct[key][a];
                Output[a,0] = Val[1];   # Scale
                Output[a,1] = Val[3];   # X
                Output[a,2] = Val[4];   # Y
                Output[a,3] = Val[5];   # Width
                Output[a,4] = Val[6];   # Height
                Output[a,5] = Val[7];   # True score
                Output[a,6] = Val[8];   # False Score
                
        return Output
            
    # Return output from detector for specified frame
    def getBoxes(self,frameName):
        # Initialize empty
        Rects = [];
        # Extract filename without extension
        key = os.path.splitext(frameName)[0];
        # Check if data for this key exists
        if self.DetectorOutStruct.get( key ):
            # Return all bounding boxes in a 2array with each row as [x,y,width,height]
            NoBoxes = len(self.DetectorOutStruct.get( key ));
            Rects = np.zeros([NoBoxes,4]);  #X,Y,Wt,Ht
            for a in range(0,NoBoxes): #np.arange(NoBoxes-1):
                Coords = np.asarray(self.DetectorOutStruct[key][a],dtype='float');
                BoxX    = Coords[0:Coords.size+1:2];
                BoxY    = Coords[1:Coords.size+1:2];
                Rects[a,0]    = BoxX.min();             
                Rects[a,1]    = BoxY.min();
                Rects[a,2]  = BoxX.max() - BoxX.min();
                Rects[a,3]  = BoxY.max() - BoxY.min();
        return Rects;
        
    # Return Patches
    def getPatches(self,frameName):
        # Initialize empty
        PatchesX = []; PatchesY = [];
        # Extract filename without extension
        key = os.path.splitext(frameName)[0];
        # Check if data for this key exists
        if self.DetectorOutStruct.get( key ):
            # Return all patches in a 3d (x,y,PatchNo)
            NoPatches = len(self.DetectorOutStruct.get( key ));
            PatchesX = np.zeros([4,NoPatches]);
            PatchesY = np.zeros([4,NoPatches]);
            for a in range(0,NoPatches): #np.arange(NoBoxes-1):
                Coords = np.asarray(self.DetectorOutStruct[key][a],dtype='float');
                PatchesX[:,a]    = Coords[0:Coords.size+1:2];
                PatchesY[:,a]    = Coords[1:Coords.size+1:2];

        return (PatchesX,PatchesY);        