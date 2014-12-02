#!/usr/bin/python
import sys, logging
from ConfigReader import ConfigReader
from AnnotationModifier import AnnotationModifier
from JSONReader import JSONReader

if __name__ == '__main__':
	if len( sys.argv ) < 6:
		print 'Usage %s <configFile> <annotationFile> <modificationFile> <baseAnnotation> [<modifiedAnnotation>]' % sys.argv[ 0 ]
		print '\n\n'
		print '<configFile> config.yaml for settings'
		print '<annotationFile> File that describes both the original annotation and the modified annotation'
		print '<modificationFile> File that consolidates all modifications'
		print '<baseAnnotation> Annotation in annotationFile which needs to be modified'
		print '<modifiedAnnotation> One or more modifications - if splitting an annotation into multiple'
		print '  annotations, supply each of them separating them with spaces'
		print '\nNote: For bash to not get confused, always enclose annotation strings in "quotes"'
		sys.exit( 1 )

	configFileName = sys.argv[1]
	annotationFile = sys.argv[2]
	modificationFile = sys.argv[3]
	baseAnnotation = str(sys.argv[4])
	modifiedAnnotations = []
	for i in range(5,len(sys.argv)):
		modifiedAnnotations += [str(sys.argv[i])]

	configReader = ConfigReader(configFileName)
	logging.basicConfig(format='{%(filename)s:%(lineno)d} %(levelname)s - %(message)s', 
			level=configReader.pp_log_level)

	annotationModifier = AnnotationModifier(configReader, modificationFile)

	jsonReader = JSONReader(annotationFile, 'none') # no image folder needed

	# add the base to file
	baseAnnotationRects = jsonReader.get_rectangles(baseAnnotation)
	if len(baseAnnotationRects) != 1:
		raise RuntimeError("Only 1 annotation allowed for baseAnnotation")	
	baseRect = baseAnnotationRects[0]
	annotationModifier.add_base_annotation(baseAnnotation, baseRect)

	# for each modification, add to file
	for modificationName in modifiedAnnotations:
		modificationRects = jsonReader.get_rectangles(modificationName)
		if len(modificationRects) != 1:
			raise RuntimeError("Only 1 annotation allowed for %s" % modificationRects)	
		modificationRect = modificationRects[0]
		annotationModifier.add_modification(baseAnnotation, modificationName, modificationRect)

	# save file
	annotationModifier.save()
