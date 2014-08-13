import os, glob, sys
import logging
from multiprocessing import Process
from ConfigReader import ConfigReader
from XMLReader import XMLReader
from JSONReader import JSONReader
from AnnotatedImage import AnnotatedImage

class PositivePatchExtractor:
  """Converts a folder of positive annotations into patches"""
  def __init__(self, configFileName, baseFolder, outputFolder):
    configReader = ConfigReader(configFileName)
    logging.basicConfig(format='{%(filename)s:%(lineno)d} %(levelname)s - %(message)s', 
      level=configReader.pp_log_level)
    baseAnnotationFolder = os.path.join(baseFolder, configReader.pp_AnnotationsFolder)
    baseImageFolder = os.path.join(baseFolder, configReader.pp_ImagesFolder)

    multipleProcesses = []
    # iterate through all files in annotation folder
    for xmlFileName in glob.glob(baseAnnotationFolder + "/*.xml"):
      #self.process_single_xml(xmlFileName, configReader, baseImageFolder, outputFolder)      
      p = Process(target=self.process_single_xml, args=(xmlFileName, configReader, baseImageFolder, outputFolder,))
      multipleProcesses += [p]
    for jsonFileName in glob.glob(baseAnnotationFolder + "/*.json"):
      #self.process_single_json(jsonFileName, configReader, baseImageFolder, outputFolder)      
      p = Process(target=self.process_single_json, args=(jsonFileName, configReader, baseImageFolder, outputFolder,))
      multipleProcesses += [p]

    numOfThreads = configReader.numOfProcessors
    for i in xrange(0, len(multipleProcesses), numOfThreads):
      processArr = multipleProcesses[i:(i + numOfThreads)]
      for p in processArr:
        p.start()
      for p in processArr:
        p.join()

    # DO NOT DELETE: easy to test out individual failing files
    # xmlFileName = '/home/evan/Vision/Scripts/TextGeneration/temp/annotation_matlab/multiClass/annotations/IAyuiE41Kcc_frame_115.xml'
    # self.process_single_xml(xmlFileName, configReader, baseImageFolder, outputFolder)

  def process_single_xml(self, xmlFileName, configReader, baseImageFolder, outputFolder):
    """Process single annotation xml file"""
    logging.info("Start working on: " + os.path.basename(xmlFileName))
    xmlReader = XMLReader(xmlFileName, baseImageFolder)
    annotatedImage = AnnotatedImage(configReader, xmlReader, outputFolder)
    logging.info("Done  working on: " + os.path.basename(xmlFileName))

  def process_single_json(self, jsonFileName, configReader, baseImageFolder, outputFolder):
    """Process single annotation xml file"""
    logging.info("Start working on: " + os.path.basename(jsonFileName))
    jsonReader = JSONReader(jsonFileName, baseImageFolder)
    annotatedImage = AnnotatedImage(configReader, jsonReader, outputFolder)
    logging.info("Done  working on: " + os.path.basename(jsonFileName))
