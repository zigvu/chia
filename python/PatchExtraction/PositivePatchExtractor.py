import os, glob, sys
import logging
from multiprocessing import Pool
from ConfigReader import ConfigReader
from XMLReader import XMLReader
from JSONReader import JSONReader
from AnnotatedImage import AnnotatedImage

def process_single_xml((xmlFileName, configFileName, baseImageFolder, outputFolder)):
  """Process single annotation xml file"""
  logging.info("Start working on: " + os.path.basename(xmlFileName))
  xmlReader = XMLReader(xmlFileName, baseImageFolder)
  configReader = ConfigReader(configFileName)
  annotatedImage = AnnotatedImage(configReader, xmlReader, outputFolder)
  logging.info("Done  working on: " + os.path.basename(xmlFileName))

def process_single_json((jsonFileName, configFileName, baseImageFolder, outputFolder)):
  """Process single annotation xml file"""
  logging.info("Start working on: " + os.path.basename(jsonFileName))
  jsonReader = JSONReader(jsonFileName, baseImageFolder)
  configReader = ConfigReader(configFileName)
  annotatedImage = AnnotatedImage(configReader, jsonReader, outputFolder)
  logging.info("Done  working on: " + os.path.basename(jsonFileName))

class PositivePatchExtractor:
  """Converts a folder of positive annotations into patches"""
  def __init__(self, configFileName, baseFolder, outputFolder):
    configReader = ConfigReader(configFileName)
    configReader.dump_config()
    logging.basicConfig(format='{%(filename)s:%(lineno)d} %(levelname)s - %(message)s', 
      level=configReader.pp_log_level)
    baseAnnotationFolder = os.path.join(baseFolder, configReader.pp_AnnotationsFolder)
    baseImageFolder = os.path.join(baseFolder, configReader.pp_ImagesFolder)

    xmlArgsArray = []
    for xmlFileName in glob.glob(baseAnnotationFolder + "/*.xml"):
      # process_single_xml(xmlFileName, configFileName, baseImageFolder, outputFolder)
      ar = (xmlFileName, configFileName, baseImageFolder, outputFolder,)
      xmlArgsArray += [ar]

    jsonArgsArray = []
    for jsonFileName in glob.glob(baseAnnotationFolder + "/*.json"):
      # process_single_json(jsonFileName, configFileName, baseImageFolder, outputFolder)      
      ar = (jsonFileName, configFileName, baseImageFolder, outputFolder,)
      jsonArgsArray += [ar]

    # use process pool to manage tasks in queue
    pool = Pool(processes = configReader.numOfProcessors)
    if len(xmlArgsArray) > 0:
      pool.map(process_single_xml, xmlArgsArray)
    if len(jsonArgsArray) > 0:
      pool.map(process_single_json, jsonArgsArray)
    pool.close()
    pool.join()
