class AnnotationSet( object ):
  def __init__( self, annotationId, rectangle ):
    # ( frameId, classId, index )
    self.annotationId = annotationId
    self.classId = annotationId[ 1 ]
    self.derivedAnnotations = []

  def addDerivedAnnotation( self, derivedAnnotation ):
    self.derivedAnnotations.append( derivedAnnotation )
