from multiprocessing import Process, Manager
import json
import cPickle as pickle

class ClassBuckets( object ):
  def __init__( self ):
    self.annotationsSets = {}

  def addAnnotationSet( self, annotationSet ):
    classId = annotationSet.classId
    annotationId = annotationSet.annotationId
    if not self.annotationsSets.get( classId ):
      self.annotationsSets[ classId ] = {}
    if not self.annotationsSets[ classId ].get( annotationId ):
      self.annotationsSets[ classId ][ annotationId ] = {}
    self.annotationsSets[ classId ][ annotationId ] = annotationSet
 
  def __str__( self ):
    myRepr = ''
    for key, annotationSets in self.annotationsSets.iteritems():
      myRepr += '\nClass %s Details' % key
      myRepr += '\n================================'
      for annotationId, annotationSet in annotationSets.iteritems():
        myRepr += '\nAnnotation Set %s, %s, %s' % annotationId
        myRepr += '\nNumber of derived annotations %s' % len( annotationSet.derivedAnnotations )
    return myRepr

  def dump( self, fileName ):
    return pickle.dump( self.annotationsSets, open( fileName, 'wb' ) )

  def load( self, fileName ):
    self.annotationsSets = pickle.load( open( fileName, 'rb' ) )

