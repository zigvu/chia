import logging
import random
from Rectangle import Rectangle

class AnnotationTransformer:
  """Main class for applying the rules for patch generation"""
  def __init__(self, configReader):
    """Initialize class"""
    self.configReader = configReader
    self.validAnnotationCount = 0
    self.imageConstraints = None
    self.transformerType = None # "None", "Scale", "Shear"
    self.annotations = {}

  def is_poly_valid(self, label, poly):
    """Set of rules to determine if the poly with given label is valid
    Returns True if poly is valid for cropping"""
    # ensure poly is larger than min area of given patch size
    patchArea = self.configReader.patch_size.area
    polyArea = poly.area
    if (polyArea / patchArea) < self.configReader.pp_minObjectAreaFraction:
      logging.debug("Invalid: Poly too small: " + str(poly))
      return False
    # ensure poly has acceptable shear angle - skip for non-shearing functions
    if ((self.transformerType == "Shear") and 
      (abs(poly.angle) > abs(self.configReader.pp_tx_maxShearAngle))):
      logging.debug("Invalid: Poly angle " + str(poly.angle) + " for label " + label + " too large")
      return False
    return True

  def is_crop_valid(self, label, poly, crop):
    """Set of rules to determine if the crop for the poly is valid"""
    # ensure the crop falls within the image rectangle
    if not self.imageConstraints.contains(crop):
      logging.debug("Invalid: Poly out of image: " + str(crop))
      return False
    # get padding bounds
    paddedCrop = crop.get_smaller_rectangle(self.configReader.pp_edgePixelPadding)
    # ensure crop contains at least partial_object_fraction of poly
    partialObjectFraction = poly.intersection(paddedCrop).area / poly.area
    if partialObjectFraction < self.configReader.pp_partialObjectFraction:
      logging.debug("Invalid: Poly fraction " + str(partialObjectFraction) + " too small: " + str(paddedCrop))
      return False
    # ensure that another logo doesn't have more than noise_object_fraction area visible
    for i, annotation in self.annotations.iteritems():
      annoLabel = annotation['label']
      annoPoly = annotation['poly']
      if annoLabel != label:
        noiseObjectFraction = annoPoly.intersection(crop).area / annoPoly.area
        if noiseObjectFraction > self.configReader.pp_noiseObjectFraction:
          logging.debug("Invalid: Noise fraction " + str(noiseObjectFraction) + " too high for label: " + annoLabel)
          return False
    logging.debug("Valid  : " + str(crop))
    return True

  def generate_all_jiggles(self):
    """Generate jiggles for all valid polys
    Returns a dict of array containing labels and crops"""
    # initialize all crops
    allCrops = {}
    for i in self.annotations:
      allCrops[self.annotations[i]['label']] = []
    # populate all crops
    for i, annotation in self.annotations.iteritems():
      label = annotation['label']
      poly = annotation['poly']
      logging.debug("Label: " + label + "; Poly: " + str(poly))

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

    logging.debug("Poly center x: " + str(poly.centerX) + ", y: " + str(poly.centerY))
    logging.debug("Minx: " + str(minX) + ", MinY: " + str(minY) + ", MaxX: " + str(maxX) + ", MaxY: " + str(maxY))
    for stepXPixel in range(minX, maxX, self.configReader.pp_tx_minPixelMove):
      for stepYPixel in range(minY, maxY, self.configReader.pp_tx_minPixelMove):
        crop = Rectangle([
          (stepXPixel,              stepYPixel),
          (stepXPixel + patchWidth, stepYPixel),
          (stepXPixel + patchWidth, stepYPixel + patchHeight),
          (stepXPixel,              stepYPixel + patchHeight)])
        if self.is_crop_valid(label, poly, crop):
          jiggleWindows = jiggleWindows + [crop]
    random.shuffle(jiggleWindows)
    if (self.transformerType == "Shear"):
      jiggleWindows = jiggleWindows[0:1]
    else:
      jiggleWindows = jiggleWindows[0:self.configReader.pp_tx_maxNumJiggles]
    return jiggleWindows

  def initialize_from_xml(self, xmlReader):
    """Initialize all bounding boxes and labels from XML file"""
    self.set_image_constraints(xmlReader.get_image_dimensions())
    objNames = xmlReader.get_object_names()
    for objName in objNames:
      bboxes = xmlReader.get_rectangles(objName)
      for bbox in bboxes:
        self.add_annotation(objName, bbox)

  def set_image_constraints(self, imagePoly):
    """Set the outer most limit of image"""
    self.imageConstraints = imagePoly

  def add_annotation(self, label, bbox):
    """Add a new label annotation to dictionary
    Data format: dict[integer] = {label, bbox}
    """
    self.annotations[self.validAnnotationCount] = {'label': label, 'poly': bbox}
    self.validAnnotationCount += 1

  def get_scaled_copy(self, scaleFactor):
    """Generate scaled copy of this class"""
    scaledTransformer = AnnotationTransformer(self.configReader)
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
    shearedTransformer = AnnotationTransformer(self.configReader)
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
    """Return a nice string stresentation of the object."""
    retStr = ""
    for i, annotation in self.annotations.iteritems():
      retStr = retStr + annotation['label'] + ": " + annotation['poly'] + "\n"
    return retStr
