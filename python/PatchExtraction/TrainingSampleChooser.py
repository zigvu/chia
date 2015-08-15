#!/usr/bin/env python

from ClassBuckets import ClassBuckets
import sys, random, shutil, os

class SampleChooser( object ):
  def __init__( self, classBucketsFileName ):
    self.classBuckets = ClassBuckets()
    self.classBuckets.load( classBucketsFileName )
    self.minCount = sys.maxint
    self.minClsName = None
    self.maxCount = 0
    self.maxClsName = None

  def classCount( self ):
    classCount = {}
    for cls, annotationsSets in self.classBuckets.annotationsSets.iteritems():
      classCount[ cls ] = 0
      for annotationId, annotationSet in annotationsSets.iteritems():
        classCount[ cls ] += len( annotationSet.derivedAnnotations )
      if classCount[ cls ] < self.minCount:
        self.minCount = classCount[ cls ]
        self.minClsName = cls
      if classCount[ cls ] > self.maxCount:
        self.maxCount = classCount[ cls ]
        self.maxClsName = cls
    return classCount

  def randomSample( self ):
    classCount = self.classCount()
    chosenByClass = {}
    for cls, annotationsSets in self.classBuckets.annotationsSets.iteritems():
      chosenByClass[ cls ] = []
      sampleAmount = max( self.minCount, 1 )
      while sampleAmount > 0 and classCount[ cls ]:
        for annotationId, annotationSet in annotationsSets.iteritems():
          if len( annotationSet.derivedAnnotations ):
            a = random.choice( annotationSet.derivedAnnotations )
            annotationSet.derivedAnnotations.remove( a )
            chosenByClass[ cls ].append( a )
            sampleAmount -= 1 
            if sampleAmount <= 0:
              break
    return chosenByClass

  def saveRandomSample( self, folderName ):
    chosenByClass = self.randomSample()
    for clsName, fileNames in chosenByClass.iteritems():
      os.makedirs( os.path.join( folderName, clsName ) )
      for f in fileNames:
        fileCounter = 0
        dstFileName = os.path.join( folderName, clsName,
            os.path.basename( f ) ) 
        dstFileName = dstFileName.replace( ".png", "_%s.png" % fileCounter )
        while os.path.exists( dstFileName ):
          fileCounter += 1
          dstFileName = dstFileName.replace( ".png", "_%s.png" % fileCounter )
        shutil.copyfile( f, dstFileName )

if __name__ == '__main__':
  if len( sys.argv ) < 3:
    print 'Usage %s <bucketsFileName> <outputFolderName>' % sys.argv[ 0 ]
    sys.exit( 1 )
  chooser = SampleChooser( sys.argv[ 1 ] )
  chooser.saveRandomSample( sys.argv[ 2 ] )
