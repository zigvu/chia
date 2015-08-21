""" Class to load configuration file."""
import os, glob, sys, errno
import yaml
import random
import logging
from scipy import arange
from Rectangle import Rectangle

class ConfigReader:
  """Reads YAML config file and allows easy accessor to config attributes"""
  def __init__(self, configFileName):
    """Initlize config from YAML file"""
    self.configFileName = configFileName
    config = yaml.load(open(self.configFileName, "r"))

    width = int(config['output_width'])
    height = int(config['output_height'])
    self.patch_size = Rectangle([(0,0),(width,0),(width,height),(0,height)], None)

    self.numOfProcessors = int(config['number_of_processors'])
    self.randomNumberSeed = int(config['random_seed'])
    self.randomWithSeed = random.Random(self.randomNumberSeed)

    positivePatch = config['positive_patch']
    self.pp_isTest = positivePatch['is_test'] == True
    self.pp_log_level = logging.DEBUG
    if positivePatch['log_level'] == 'INFO':
      self.pp_log_level = logging.INFO
    if positivePatch['log_level'] == 'ERROR':
      self.pp_log_level = logging.ERROR

    self.pp_ImagesFolder = positivePatch['folders']['image_input']
    self.pp_AnnotationsFolder = positivePatch['folders']['annotation_input']

    self.pp_minObjectAreaFraction = float(positivePatch['min_object_area_fraction'])
    self.pp_edgePixelPadding = int(positivePatch['edge_pixel_padding'])
    self.pp_partialObjectFraction = float(positivePatch['partial_object_fraction'])
    self.pp_noiseObjectFraction = float(positivePatch['noise_object_fraction'])
    
    transformations = positivePatch['transformations']
    self.pp_tx_maxNumJiggles = int(transformations['jiggles']['max_num_jiggles'])
    self.pp_tx_minPixelMove = int(transformations['jiggles']['min_pixel_move'])

    self.pp_tx_maxNumShear = int(transformations['shear']['max_num_shear'])
    self.pp_tx_maxShearAngle = int(transformations['shear']['max_shear_angle'])
    minSF = -0.1
    maxSF = 0.1
    incSF = 0.05
    self.pp_tx_shearConfigs = []
    for pt0X in arange(minSF, maxSF + incSF, incSF):
      for pt0Y in arange(minSF, maxSF + incSF, incSF):
        for pt1X in arange(minSF, maxSF + incSF, incSF):
          for pt1Y in arange(minSF, maxSF + incSF, incSF):
            for pt2X in arange(minSF, maxSF + incSF, incSF):
              for pt2Y in arange(minSF, maxSF + incSF, incSF):
                for pt3X in arange(minSF, maxSF + incSF, incSF):
                  for pt3Y in arange(minSF, maxSF + incSF, incSF):
                    # if it just looks like scaling, skip
                    if not ((pt0X == pt0Y) and (pt0X == pt1X) and (pt0X == pt1Y) and 
                      (pt0X == pt2X) and (pt0X == pt2Y) and (pt0X == pt3X) and (pt0X == pt3Y)):
                      self.pp_tx_shearConfigs += [(pt0X, pt0Y, pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y)]
    self.randomWithSeed.shuffle(self.pp_tx_shearConfigs)

    self.pp_tx_scales = []
    pp_tx_scales = transformations['scaling']
    for tx_scale in pp_tx_scales:
      self.pp_tx_scales = self.pp_tx_scales + [float(tx_scale)]

    self.pp_tx_tintIntensity = 0.1
    self.pp_tx_tintFraction = float(transformations['blending']['tint_fraction'])
    self.pp_tx_tintBlendFraction = float(transformations['blending']['blend_fraction'])

    self.extractionLabels = config['extraction_labels']

  def dump_config(self):
    # spit the config first - logging creates problems it seems
    print "Config dump"
    configFile = open(self.configFileName)
    for line in configFile:
      print line.rstrip("\n")
    configFile.close()

  def get_next_color(self):
    """Get next tint color"""
    return (self.randomWithSeed.randint(0,200), \
      self.randomWithSeed.randint(0,200), \
      self.randomWithSeed.randint(0,200))


  @staticmethod
  def mkdir_p(start_path):
    """Util to make path"""
    try:
      os.makedirs(start_path)
    except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST and os.path.isdir(start_path):
        pass

  @staticmethod
  def rm_rf(start_path):
    """Util to delete path"""
    try:
      if os.path.isdir(start_path):
        shutil.rmtree(start_path, ignore_errors=True)
      elif os.path.exists(start_path):
        os.remove(start_path)
    except:
      # do nothing
      pass
