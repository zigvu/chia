#!/usr/bin/env python

import os, glob, sys
import logging
from multiprocessing import Pool
from ConfigReader import ConfigReader
from XMLReader import XMLReader
from JSONReader import JSONReader
from JSONReader import AnnotationSet
from AnnotatedImage import AnnotatedImage
from ClassBuckets import ClassBuckets

from postprocessing.task.Task import Task
from infra.Pipeline import Pipeline
import multiprocessing, time
import cPickle as pickle

class GenerateSamplesTask( Task ):
  def __call__( self, obj ):
    logging.info( '%s Processing %s' % ( self, obj ) )
    jsonReader = JSONReader( self.config, obj, self.config.imagesFolder )
    annotatedImage = AnnotatedImage( self.config, jsonReader, self.config.outputFolder)
    logging.info( '%s Done Processing %s' % ( self, obj ) )
    return self.config.classBuckets

class TrainingSampleGenerator( object ):
  def __init__( self, configFile, baseFolder, outputFolder ):
    self.config = ConfigReader(configFile)
    self.annotationsFolder = os.path.join( baseFolder, self.config.pp_AnnotationsFolder )
    self.config.imagesFolder = os.path.join( baseFolder, self.config.pp_ImagesFolder )
    self.config.outputFolder = outputFolder
    self.jsonFiles = []
    for jsonFileName in glob.glob(self.annotationsFolder + "/*.json"):
      self.jsonFiles.append( jsonFileName )
    self.classBuckets = ClassBuckets()
    self.config.classBuckets = self.classBuckets
    logging.basicConfig(format='{%(filename)s:%(lineno)d} %(levelname)s - %(message)s', 
      level=self.config.pp_log_level)

  def generateSamplesSingle( self ):
    for j in self.jsonFiles:
      jsonReader = JSONReader( self.config, j, self.config.imagesFolder )
      annotatedImage = AnnotatedImage( self.config,
          jsonReader, self.outputFolder)
    print self.classBuckets

  def generateSamples( self ):
    inputs = multiprocessing.JoinableQueue()
    results = multiprocessing.Queue()
    myPipeline = Pipeline([
      GenerateSamplesTask(self.config, None),
      ],
        inputs, results)
    startTime = time.time()
    myPipeline.start()

    for j in self.jsonFiles:
      inputs.put( j )

    num_consumers = multiprocessing.cpu_count()
    for i in xrange(num_consumers):
      inputs.put(None)
    # Get the results into a list
    resultList = []
    while len( resultList ) != len( self.jsonFiles ):
      classBucket = results.get()
      if classBucket:
        resultList.append( classBucket )

    # Merge the list
    mergedClassBuckets = ClassBuckets()
    for classBuckets in resultList:
      for cls, annotations in classBuckets.annotationsSets.iteritems():
        for annotationId, annotationSet in annotations.iteritems():
          mergedClassBuckets.addAnnotationSet( annotationSet )

    myPipeline.join()
    mergedClassBuckets.dump( 'classBuckets.p' )
    endTime = time.time()
    logging.info('Took %s seconds' % (endTime - startTime))


if __name__ == '__main__':
  if len( sys.argv ) < 4:
    print 'Usage %s <configFile> <baseInputFolder> <outputFolder>' % sys.argv[ 0 ]
    sys.exit( 1 )
  gen = TrainingSampleGenerator( sys.argv[ 1 ], sys.argv[ 2 ], sys.argv[ 3 ] )
  gen.generateSamples()
