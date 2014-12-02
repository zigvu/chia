import os
import json
import logging
from collections import OrderedDict
from shapely.geometry import Polygon
from Rectangle import Rectangle

class JSONReader:
  """Reads JSON file that contains the annotation"""
  def __init__(self, jsonFileName, baseImageFolder):
    """Load json file"""
    self.jsonFileName = jsonFileName
    with open(jsonFileName) as fd:
      self.jsonDict = json.load(fd)
    # copy to class variables
    self.imageFileName = baseImageFolder + "/" + str(self.jsonDict['frame_filename'])
    self.annotationFileName = os.path.basename(jsonFileName)

    width = int(self.jsonDict['width'])
    height = int(self.jsonDict['height'])
    self.imageDimension = Rectangle([(0,0),(width,0),(width,height),(0,height)])

    # get all rectangles
    self.annotated_objects = {}
    annoObjs = self.jsonDict['annotations']
    for name, polys in annoObjs.iteritems():
      for poly in polys:
        vettedPoly = JSONReader.get_polygon(poly)
        if vettedPoly != None:
          if self.annotated_objects.has_key(name):
            rectangles = self.annotated_objects[name] + [vettedPoly]
          else:
            rectangles = [vettedPoly]
          # update list
          self.annotated_objects[name] = rectangles

  def get_rectangles(self, objName):
    """Get all rectangles for objName"""
    if objName in self.annotated_objects.keys():
      return self.annotated_objects[objName]
    return []

  def add_rectangle(self, objName, rectangle):
    """Add object to dict"""
    if not objName in self.annotated_objects.keys():
      raise RuntimeError("Object %s doesn't exist" % objName)
    self.annotated_objects[objName] += [rectangle]

  def remove_object(self, objName):
    """Remove an object from this annotation"""
    self.annotated_objects.pop(objName, None)

  def add_object_name(self, objName):
    """Add object to dict"""
    if objName in self.annotated_objects.keys():
      raise RuntimeError("Object %s already exists" % objName)
    self.annotated_objects[objName] = []

  def get_object_names(self):
    """Get all object names in this annotation file"""
    return self.annotated_objects.keys()

  def get_image_dimensions(self):
    """Get the width, height of image"""
    return self.imageDimension

  @staticmethod
  def get_polygon(poly):
    """Convert coordinates into polygons"""
    if len(poly) != 8:
      for p, v in poly.iteritems():
        logging.error("%s : %d" % (str(p), int(v)))
      logging.error("Polygon in JSON file not quadrilateral")
      return None
    else:
      rectangle = Rectangle([
        (int(poly['x0']), int(poly['y0'])),
        (int(poly['x1']), int(poly['y1'])),
        (int(poly['x2']), int(poly['y2'])),
        (int(poly['x3']), int(poly['y3']))])
      return rectangle

  def save(self, outputJsonFileName = None):
    """Save dict - if outputJsonFileName is not provided, overwrites original file"""
    logging.debug("Saving file")
    # the most current state of rect
    self.jsonDict['annotations'] = OrderedDict()
    for name, polys in self.annotated_objects.iteritems():
      self.jsonDict['annotations'][name] = []
      for poly in polys:
        self.jsonDict['annotations'][name] += [poly.dict_format()]
    # save
    fileToSave = self.jsonFileName
    if outputJsonFileName != None:
      fileToSave = outputJsonFileName
    with open(fileToSave, "w") as fd :
      json.dump( self.jsonDict, fd, indent=2 )
