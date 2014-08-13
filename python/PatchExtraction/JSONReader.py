import os
import json
import logging
from shapely.geometry import Polygon
from Rectangle import Rectangle

class JSONReader:
  """Reads JSON file that contains the annotation"""
  def __init__(self, jsonFileName, baseImageFolder):
    """Load json file"""
    with open(jsonFileName) as fd:
      jsonDict = json.load(fd)
    # copy to class variables
    self.imageFileName = baseImageFolder + "/" + str(jsonDict['frame_filename'])
    self.annotationFileName = os.path.basename(jsonFileName)

    width = int(jsonDict['width'])
    height = int(jsonDict['height'])
    self.imageDimension = Rectangle([(0,0),(width,0),(width,height),(0,height)])

    # get all rectangles
    self.annotated_objects = {}
    annoObjs = jsonDict['annotations']
    for name, polys in annoObjs.iteritems():
      for poly in polys:
        vettedPoly = self.get_polygon(poly)
        if vettedPoly != None:
          if self.annotated_objects.has_key(name):
            rectangles = self.annotated_objects[name] + [vettedPoly]
          else:
            rectangles = [vettedPoly]
          # update list
          self.annotated_objects[name] = rectangles

  def get_rectangles(self, objName):
    """Get all rectangles for objName"""
    return self.annotated_objects[objName]

  def get_object_names(self):
    """Get all object names in this annotation file"""
    return self.annotated_objects.keys()

  def get_image_dimensions(self):
    """Get the width, height of image"""
    return self.imageDimension

  def get_polygon(self, poly):
    """Convert coordinates into polygons"""
    if len(poly) != 8:
      for p, v in poly.iteritems():
        logging.error("%s : %d" % (str(p), int(v)))
      logging.error("Polygon in JSON file not quadrilateral")
      return None
    else:
      poly = Polygon([
        (int(poly['x0']), int(poly['y0'])),
        (int(poly['x1']), int(poly['y1'])),
        (int(poly['x2']), int(poly['y2'])),
        (int(poly['x3']), int(poly['y3']))])
      rectangle = Rectangle.get_correctly_rotated_rectangle(poly)
      return rectangle
