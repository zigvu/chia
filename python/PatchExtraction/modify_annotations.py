#!/usr/bin/python
import os, glob, sys
import logging
from multiprocessing import Pool

from ConfigReader import ConfigReader
from AnnotationModifier import AnnotationModifier
from JSONReader import JSONReader


def process_single_json((inputJsonFileName, configFileName, modificationFile, outputFolder)):
	"""Process single annotation json file"""
	inputJsonBaseName = os.path.basename(inputJsonFileName)
	outputJsonFileName = os.path.join(outputFolder, inputJsonBaseName)
	logging.info("Start working on: " + inputJsonBaseName)
	configReader = ConfigReader(configFileName)
	annotationModifier = AnnotationModifier(configReader, modificationFile)
	annotationModifier.modify_file(inputJsonFileName, outputJsonFileName)

if __name__ == '__main__':
	if len( sys.argv ) < 5:
		print 'Usage %s <configFile> <modificationFile> <inputAnnotationFolder> <outputFolder>' % sys.argv[ 0 ]
		print '\n\n'
		print '<configFile> config.yaml for settings'
		print '<modificationFile> File that has all modifications'
		print '<inputAnnotationFolder> Folder of JSON for which to modify annotations'
		print '<outputFolder> Output annotations - all JSON files in input folder will be present here'
		sys.exit( 1 )

	configFileName = sys.argv[1]
	modificationFile = sys.argv[2]
	inputAnnotationFolder = sys.argv[3]
	outputFolder = sys.argv[4]

	ConfigReader.mkdir_p(outputFolder)

	configReader = ConfigReader(configFileName)
	logging.basicConfig(format='{%(filename)s:%(lineno)d} %(levelname)s - %(message)s', 
			level=configReader.pp_log_level)

	jsonArgsArray = []
	for inputJsonFileName in glob.glob(inputAnnotationFolder + "/*.json"):
		ar = (inputJsonFileName, configFileName, modificationFile, outputFolder,)
		jsonArgsArray += [ar]

	# use process pool to manage tasks in queue
	pool = Pool(processes = configReader.numOfProcessors)
	if len(jsonArgsArray) > 0:
		pool.map(process_single_json, jsonArgsArray)
	pool.close()
	pool.join()

