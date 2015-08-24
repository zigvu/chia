import os, errno, sys
import cv2
import logging
import numpy as np
import random
from AnnotationTransformer import AnnotationTransformer
from AnnotationTracker import AnnotationTracker
from Rectangle import Rectangle

class AnnotatedImage:
  """Processing single image for patch extraction"""
  def __init__(self, configReader, annotationReader, outputFolder):
    """Initialize class"""
    self.configReader = configReader
    self.randomNumberGenerator = random.Random(configReader.randomNumberSeed)
    self.baseTransformer = AnnotationTransformer(configReader, self.randomNumberGenerator)
    self.baseTransformer.initialize_from_file(annotationReader)
    self.annotationReader = annotationReader
    self.annotationFileName = annotationReader.annotationFileName
    self.patchOutputFolder = os.path.join(outputFolder, 'patches')
    self.trackOutputFolder = os.path.join(outputFolder, 'annotation_trackers')

    # if test, spit out large files, else patches
    self.isTest = self.configReader.pp_isTest
    # file name prefix helpers
    self.baseFileName = os.path.splitext(os.path.basename(self.annotationReader.imageFileName))[0]
    self.baseFileExt = os.path.splitext(os.path.basename(self.annotationReader.imageFileName))[1]
    # counter for shear
    self.shearCounter = 0

    if not self.isTest:
      self.mkdir_p(self.trackOutputFolder)
      self.annotationTracker = AnnotationTracker(self.trackOutputFolder)

    # count valid/invalid poly/crops
    self.validCropCount = 0
    self.invalidCropCount = 0

    self.generate_scaled_all()
    self.generate_sheared_all()

    if not self.isTest:
      self.annotationTracker.save()
    # log
    logging.info(self.annotationFileName + ": Crop count: Valid: " + str(self.validCropCount) + ", Invalid: " + \
      str(self.invalidCropCount))

  def generate_sheared_all(self):
    """Save all sheared images/patches"""
    self.shearCounter = 0
    img = cv2.imread(self.annotationReader.imageFileName)
    loopCounter = 0
    for pt0X, pt0Y, pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y in self.configReader.pp_tx_shearConfigs:
      outputFilename = os.path.join(
        self.patchOutputFolder, 
        self.baseFileName + "_shr_" + repr(self.shearCounter) + self.baseFileExt)
      logging.debug(self.annotationFileName + ": Shearing: " + str(self.shearCounter) + ": " + \
        str(pt0X) + "," + str(pt0Y) + "; " + \
        str(pt1X) + "," + str(pt1Y) + "; " + \
        str(pt2X) + "," + str(pt2Y) + "; " + \
        str(pt3X) + "," + str(pt3Y))
      self.generate_sheared_single(img, self.patchOutputFolder, outputFilename, 
        pt0X, pt0Y, pt1X, pt1Y, pt2X, pt2Y, pt3X, pt3Y)
      loopCounter += 1
      # prevent long searches which look like freezes
      if (self.shearCounter > self.configReader.pp_tx_maxNumShear) or \
        (loopCounter > self.configReader.pp_tx_maxNumShear * 10):
        break

  def generate_sheared_single(self, img, patchOutputFolder, outputFilename, pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD):
    """Save single sheared image/patches"""
    shearedTransformer = self.baseTransformer.get_sheared_copy(pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD)
    shearMat = Rectangle.get_perspective_transform_matrix(
      self.baseTransformer.imageConstraints, shearedTransformer.imageConstraints)
    shearedImage = np.zeros(
      shape=(shearedTransformer.imageConstraints.width, shearedTransformer.imageConstraints.height), 
      dtype="uint8")
    shearedImage = cv2.warpPerspective(img, shearMat, 
      (shearedTransformer.imageConstraints.width, shearedTransformer.imageConstraints.height), 
      shearedImage, cv2.INTER_CUBIC)
    self.draw_annotated_bboxes(shearedTransformer, shearedImage, patchOutputFolder, outputFilename)
    # update counts
    # NOTE: self.validCropCount is incremented when a crop is written
    self.invalidCropCount += shearedTransformer.invalidCropCount

  def generate_scaled_all(self):
    """Save all scaled images/patches"""
    img = cv2.imread(self.annotationReader.imageFileName)
    for scaleFactor in self.configReader.pp_tx_scales:
      outputFilename = os.path.join(
        self.patchOutputFolder, 
        self.baseFileName + "_scl_" + repr(scaleFactor) + self.baseFileExt)
      logging.debug(self.annotationFileName + ": Scaling: " + str(scaleFactor))
      self.generate_scaled_single(img, self.patchOutputFolder, outputFilename, scaleFactor)

  def generate_scaled_single(self, img, patchOutputFolder, outputFilename, scaleFactor):
    """Save single scaled image/patches"""
    scaledTransformer = self.baseTransformer.get_scaled_copy(scaleFactor)
    scaledImage = cv2.resize(img, 
      (scaledTransformer.imageConstraints.width, scaledTransformer.imageConstraints.height), 
      interpolation = cv2.INTER_CUBIC)
    self.draw_annotated_bboxes(scaledTransformer, scaledImage, patchOutputFolder, outputFilename)
    # update counts
    # NOTE: self.validCropCount is incremented when a crop is written
    self.invalidCropCount += scaledTransformer.invalidCropCount

  def show_image(self, annotationTransformer, img):
    """Show image for quick feedback
    NOTE: Works only in test mode"""
    self.draw_annotated_bboxes(annotationTransformer, img, None, None)
    cv2.imshow('image', img)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

  def draw_annotated_bboxes(self, annotationTransformer, img, patchOutputFolder, outputFilename):
    """Draw all annotated bounding boxes in image"""
    outputPatchname = None
    if self.isTest:
      # draw original annotations rectangles
      color = (0,0,0)
      for i, annotation in annotationTransformer.annotations.iteritems():
        self.draw_bbox(img, annotation['label'], annotation['poly'], color, outputPatchname)
    # generate all jiggles and draw/save
    allCrops = annotationTransformer.generate_all_jiggles()
    for label, crops in allCrops.iteritems():
      if label not in self.configReader.extractionLabels:
        continue
      # extract patch
      labelCounter = 0
      for crop in crops:
        if not self.isTest:
          self.mkdir_p(os.path.join(patchOutputFolder, label))
          baseFileName = os.path.splitext(os.path.basename(outputFilename))[0]
          outputPatchname = os.path.join(patchOutputFolder, label, 
            baseFileName + "_" + repr(labelCounter) + self.baseFileExt)
        color = self.configReader.get_next_color()
        self.draw_bbox(img, label + ":" + str(labelCounter), crop, color, outputPatchname)
        labelCounter += 1
        self.validCropCount += 1
    if self.isTest:
      cv2.imwrite(outputFilename, img)

  def draw_bbox(self, img, label, bbox, color, outputPatchname):
    """Draw a bounding box and text label on image"""
    # for shear, count one more only if file is written
    self.shearCounter += 1

    pts = bbox.cv2_format()
    tX0 = pts[0][0][0]
    tY0 = pts[0][0][1]
    tW = pts[2][0][0]
    tH = pts[2][0][1]
    patch = img[tY0:tH, tX0:tW].copy()
    # tint
    if self.configReader.pp_tx_tintFraction > self.randomNumberGenerator.random():
      tintForeground = img[tY0:tH, tX0:tW].copy()
      tintForeground[:] = tuple(reversed(color))
      tintBackground = img[tY0:tH, tX0:tW].copy()
      patch = cv2.addWeighted(
        tintForeground, self.configReader.pp_tx_tintIntensity, 
        tintBackground, 1 - self.configReader.pp_tx_tintIntensity, 0)
      # update patch file name
      if not self.isTest:
        baseFileName = os.path.splitext(outputPatchname)[0]
        outputPatchname = baseFileName + "_tnt" + self.baseFileExt
    if self.isTest:
      img[tY0:tH, tX0:tW] = patch
      cv2.polylines(img, [pts], True, color)
      font = cv2.FONT_HERSHEY_SIMPLEX
      cv2.putText(img, label, (pts[0][0][0] + 2, pts[0][0][1] + 15), font, 0.5, color, 1)
    else:
      # include annotation id in filename
      baseFileName = os.path.splitext(outputPatchname)[0]
      outputPatchname = baseFileName + "_" + bbox.annotationId + self.baseFileExt
      cv2.imwrite(outputPatchname, patch)
      self.annotationTracker.addPatch(bbox.annotationId, os.path.basename(outputPatchname))

  def mkdir_p(self, path):
    """Util to make path"""
    try:
      os.makedirs(path)
    except OSError as exc: # Python >2.5
      if exc.errno == errno.EEXIST and os.path.isdir(path):
        pass
