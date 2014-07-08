import os
import xmltodict
import logging
from shapely.geometry import Polygon
from Rectangle import Rectangle

class XMLReader:
  """Reads XML file that contains the annotation"""
  def __init__(self, xmlFileName, baseImageFolder):
    """Load xml file"""
    with open(xmlFileName) as fd:
      xml = xmltodict.parse(fd.read())
    # copy to class variables
    self.imageFileName = baseImageFolder + "/" + str(xml['annotation']['filename'])
    self.xmlFileName = os.path.basename(xmlFileName)

    width = int(xml['annotation']['imageWidth'])
    height = int(xml['annotation']['imageHeight'])
    self.imageDimension = Rectangle([(0,0),(width,0),(width,height),(0,height)])

    # get all rectangles
    self.annotated_objects = {}
    annoObjs = xml['annotation']['object']
    if isinstance(annoObjs, list):
      for annoObj in annoObjs:
        name = str(annoObj['name'])
        poly = annoObj['polygon']['pt']
        vettedPoly = self.get_polygon(poly)
        if vettedPoly != None:
          if self.annotated_objects.has_key(name):
            rectangles = self.annotated_objects[name] + [vettedPoly]
          else:
            rectangles = [vettedPoly]
          # update list
          self.annotated_objects[name] = rectangles
    elif isinstance(annoObjs, dict):
      name = str(annoObjs['name'])
      poly = annoObjs['polygon']['pt']
      vettedPoly = self.get_polygon(poly)
      if vettedPoly != None:
        rectangles = [vettedPoly]
        self.annotated_objects[name] = rectangles
    else:
      raise RuntimeError("XMLReader: No objects found in XML file")

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
    if len(poly) != 4:
      for p in poly:
        logging.error(str(int(float(p['x']))) + "," + str(int(float(p['y']))))
      logging.error("Polygon in XML file not quadrilateral")
      return None
    else:
      poly = Polygon([
        (int(float(poly[0]['x'])), int(float(poly[0]['y']))),
        (int(float(poly[1]['x'])), int(float(poly[1]['y']))),
        (int(float(poly[2]['x'])), int(float(poly[2]['y']))),
        (int(float(poly[3]['x'])), int(float(poly[3]['y'])))])
      rectangle = Rectangle.get_correctly_rotated_rectangle(poly)
      return rectangle