import logging
from Rectangle import Rectangle

class AnnotationTransformer:
  """Main class for applying the rules for patch generation"""
  def __init__(self, configReader, randomNumberGenerator):
    """Initialize class"""
    self.configReader = configReader
    self.randomNumberGenerator = randomNumberGenerator
    self.validPolyCount = 0
    self.invalidPolyCount = 0
    self.validCropCount = 0
    self.invalidCropCount = 0
    self.imageConstraints = None
    self.annotationFileName = None
    self.transformerType = None # "None", "Scale", "Shear"
    self.annotations = {}

  def is_poly_valid(self, label, poly):
    """Set of rules to determine if the poly with given label is valid
    Returns True if poly is valid for cropping"""
    # ensure poly is larger than min area of given patch size
    patchArea = self.configReader.patch_size.area
    polyArea = poly.area
    if (polyArea / patchArea) < self.configReader.pp_minObjectAreaFraction:
      self.invalidPolyCount += 1
      logging.debug(self.annotationFileName + ": Invalid: Poly too small: " + str(poly))
      return False
    # ensure poly has acceptable shear angle - skip for non-shearing functions
    if ((self.transformerType == "Shear") and 
      (abs(poly.angle) > abs(self.configReader.pp_tx_maxShearAngle))):
      self.invalidPolyCount += 1
      logStr = (self.annotationFileName + ": Invalid: Poly angle %.2f for label " + label + " too large") % (poly.angle)
      logging.debug(logStr)
      return False
    self.validPolyCount += 1
    return True

  def is_crop_valid(self, label, poly, crop):
    """Set of rules to determine if the crop for the poly is valid"""
    # ensure the crop falls within the image rectangle
    if not self.imageConstraints.contains(crop):
      self.invalidCropCount += 1
      logging.debug(self.annotationFileName + ": Invalid: Poly out of image: " + str(crop))
      return False
    # get padding bounds
    paddedCrop = crop.get_smaller_rectangle(self.configReader.pp_edgePixelPadding)
    # ensure crop contains at least partial_object_fraction of poly
    partialObjectFraction = poly.intersection(paddedCrop).area / poly.area
    if partialObjectFraction < self.configReader.pp_partialObjectFraction:
      self.invalidCropCount += 1
      logStr = (self.annotationFileName + ": Invalid: Poly fraction %.2f too small: " + str(paddedCrop)) % (partialObjectFraction)
      logging.debug(logStr)
      return False
    # ensure that another logo doesn't have more than noise_object_fraction area visible
    for i, annotation in self.annotations.iteritems():
      annoLabel = annotation['label']
      annoPoly = annotation['poly']
      if annoLabel != label:
        noiseObjectFraction = annoPoly.intersection(crop).area / annoPoly.area
        if noiseObjectFraction > self.configReader.pp_noiseObjectFraction:
          logStr = (self.annotationFileName + ": Invalid: Noise fraction %.2f too high for label: " + annoLabel) % (noiseObjectFraction)
          logging.debug(logStr)
          self.invalidCropCount += 1
          return False
    logging.debug(self.annotationFileName + ": Valid  : " + str(crop))
    # Note: self.validCropCount is incremented when crop is added in add_annotations
    return True

  def generate_all_jiggles(self):
    """Generate jiggles for all valid polys
    Returns a dict of array containing labels and crops"""
    # initialize all crops
    allCrops = {}
    for i, annotation in self.annotations.iteritems():
      label = annotation['label']
      allCrops[label] = []
    # populate all crops
    for i, annotation in self.annotations.iteritems():
      label = annotation['label']
      poly = annotation['poly']
      logging.debug(self.annotationFileName + ": Label: " + label + "; Poly: " + str(poly))

      if self.is_poly_valid(label, poly):
        jiggleWindows = self.generate_poly_jiggle(label, poly)
        allCrops[label] = allCrops[label] + jiggleWindows
    return allCrops
      
  def generate_poly_jiggle(self, label, poly):
    """Generate all valid jiggles for this poly"""
    jiggleWindows = []

    patchWidth = self.configReader.patch_size.width
    patchHeight = self.configReader.patch_size.height
    minX = poly.centerX - patchWidth
    maxX = poly.centerX
    minY = poly.centerY - patchHeight
    maxY = poly.centerY
    minX = 0 if minX < 0 else minX
    minY = 0 if minY < 0 else minY

    #logging.debug(self.annotationFileName + ": Poly center x: " + str(poly.centerX) + ", y: " + str(poly.centerY))
    #logging.debug(self.annotationFileName + ": Minx: " + str(minX) + ", MinY: " + str(minY) + ", MaxX: " + str(maxX) + ", MaxY: " + str(maxY))
    for stepXPixel in range(minX, maxX, self.configReader.pp_tx_minPixelMove):
      for stepYPixel in range(minY, maxY, self.configReader.pp_tx_minPixelMove):
        crop = Rectangle([
          (stepXPixel,              stepYPixel),
          (stepXPixel + patchWidth, stepYPixel),
          (stepXPixel + patchWidth, stepYPixel + patchHeight),
          (stepXPixel,              stepYPixel + patchHeight)])
        if self.is_crop_valid(label, poly, crop):
          jiggleWindows = jiggleWindows + [crop]
    self.randomNumberGenerator.shuffle(jiggleWindows)
    if (self.transformerType == "Shear"):
      jiggleWindows = jiggleWindows[0:1]
    else:
      jiggleWindows = jiggleWindows[0:self.configReader.pp_tx_maxNumJiggles]
    return jiggleWindows

  def initialize_from_file(self, annotationReader):
    """Initialize all bounding boxes and labels from XML file"""
    self.set_image_constraints(annotationReader.get_image_dimensions())
    self.annotationFileName = annotationReader.annotationFileName
    objNames = annotationReader.get_object_names()
    for objName in objNames:
      bboxes = annotationReader.get_rectangles(objName)
      for bbox in bboxes:
        self.add_annotation(objName, bbox)

  def set_image_constraints(self, imagePoly):
    """Set the outer most limit of image"""
    self.imageConstraints = imagePoly

  def add_annotation(self, label, bbox):
    """Add a new label annotation to dictionary
    Data format: dict[integer] = {label, bbox}
    """
    self.annotations[self.validCropCount] = {'label': label, 'poly': bbox}
    self.validCropCount += 1

  def get_scaled_copy(self, scaleFactor):
    """Generate scaled copy of this class"""
    scaledTransformer = AnnotationTransformer(self.configReader, self.randomNumberGenerator)
    scaledTransformer.annotationFileName = self.annotationFileName
    scaledTransformer.transformerType = "Scale"
    # scale image
    scaledImageSize = self.imageConstraints.get_scaled_rectangle(scaleFactor)
    scaledTransformer.set_image_constraints(scaledImageSize)
    # put in all scaled annotations
    for i, annotation in self.annotations.iteritems():
      label = annotation['label']
      bbox = annotation['poly'].get_scaled_rectangle(scaleFactor)
      scaledTransformer.add_annotation(label, bbox)
    return scaledTransformer

  def get_sheared_copy(self, pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD):
    """Generate sheared copy of this class"""
    shearedTransformer = AnnotationTransformer(self.configReader, self.randomNumberGenerator)
    shearedTransformer.annotationFileName = self.annotationFileName
    shearedTransformer.transformerType = "Shear"
    # shear image
    shearedImageSize = self.imageConstraints.get_sheared_rectangle(pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD)
    translateX, translateY = shearedImageSize.get_linear_transform()
    shearedImageSize = shearedImageSize.apply_linear_transform(translateX, translateY)
    shearedTransformer.set_image_constraints(shearedImageSize)
    # put in all scaled annotations
    for i, annotation in self.annotations.iteritems():
      label = annotation['label']
      bbox = annotation['poly'].get_sheared_rectangle(pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD)
      bbox = bbox.apply_linear_transform(translateX, translateY)
      shearedTransformer.add_annotation(label, bbox)
    return shearedTransformer

  def __str__(self):
    """Return a nice string representation of the object."""
    retStr = ""
    for i, annotation in self.annotations.iteritems():
      retStr = retStr + annotation['label'] + ": " + annotation['poly'] + "\n"
    return retStr
