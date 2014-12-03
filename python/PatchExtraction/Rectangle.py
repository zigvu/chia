import cv2
import numpy as np
import shapely
from collections import OrderedDict
from shapely.geometry import Polygon
from shapely.geometry import Point

class Rectangle(Polygon):
  """Treat rectangle as a special polygon"""
  def __init__(self, polyArray):
    """Initialize class"""
    Polygon.__init__(self, polyArray)
    self.width = int(self.bounds[2] - self.bounds[0])
    self.height = int(self.bounds[3] - self.bounds[1])
    polyCenter = self.centroid
    self.centerX = int(polyCenter.x)
    self.centerY = int(polyCenter.y)
    b = np.asarray(self.exterior)
    self.angle = 0
    if (b[1][0] - b[0][0]) != 0:
      self.angle = np.rad2deg(np.arctan((b[1][1] - b[0][1])/(b[1][0] - b[0][0])))

  def get_smaller_rectangle(self, pixelPadding):
    """Get a new rectangle with pixelPadding smaller dimension
    Returns new rectangle
    """
    b = np.asarray(self.exterior)
    return Rectangle([
      (b[0][0] + pixelPadding, b[0][1] + pixelPadding),
      (b[1][0] - pixelPadding, b[1][1] + pixelPadding),
      (b[2][0] - pixelPadding, b[2][1] - pixelPadding),
      (b[3][0] + pixelPadding, b[2][1] - pixelPadding)])

  def get_scaled_rectangle(self, scaleFactor):
    """Get a new rectangle scaled according to given scale factor
    Returns new rectangle
    """
    origRect = Rectangle([(0,0),(1000,0),(1000,1000),(0,1000)])
    scaledRect = Rectangle([
      (0,                       0),
      (int(1000 * scaleFactor), 0),
      (int(1000 * scaleFactor), int(1000 * scaleFactor)),
      (0,                       int(1000 * scaleFactor))])
    mat = Rectangle.get_perspective_transform_matrix(origRect, scaledRect)
    return Rectangle.apply_perspective_transform_matrix(self, mat)

  def get_sheared_rectangle(self, pt1LR, pt1UD, pt2LR, pt2UD, pt3LR, pt3UD, pt4LR, pt4UD):
    """Get a new rectangle sheared according to given shear angle
    Returns new rectangle
    """
    if (pt1LR >= 1) or (pt1UD >= 1) or (pt2LR >= 1) or (pt2UD >= 1) or \
      (pt3LR >= 1) or (pt3UD >= 1) or (pt4LR >= 1) or (pt4UD >= 1):
      raise RuntimeError("Rectangle: Incoorrect shear request")
    origRect = Rectangle([(0,0),(1000,0),(1000,1000),(0,1000)])
    shearedRect = Rectangle([
      (int(0 + 1000 * pt1LR),    int(0 + 1000 * pt1UD)),
      (int(1000 + 1000 * pt2LR), int(0 + 1000 * pt2UD)),
      (int(1000 + 1000 * pt3LR), int(1000 + 1000 * pt3UD)),
      (int(0 + 1000 * pt4LR),    int(1000 + 1000 * pt4UD))])
    mat = Rectangle.get_perspective_transform_matrix(origRect, shearedRect)
    return Rectangle.apply_perspective_transform_matrix(self, mat)

  def get_transformed_rectangle(self, baseOrigAnnoRect, newOrigAnnoRect):
    """Get a new rectangle that effectively transforms this rectangle with the same
    transformation as is required to take baseOrigAnnoRect to newOrigAnnoRect"""
    mat = Rectangle.get_perspective_transform_matrix(baseOrigAnnoRect, newOrigAnnoRect)
    return Rectangle.apply_perspective_transform_matrix(self, mat)

  def numpy_format(self):
    """Convert shapely polygon to numpy array"""
    ext = np.asarray(self.exterior)
    return np.array(ext[0:4, :], np.float32)

  def cv2_format(self):
    """Convert shapely polygon to cv2 polygon points"""
    ext = np.asarray(self.exterior)
    b = np.array(ext[0:4, :], np.int32)
    return b.reshape((-1,1,2))

  def dict_format(self):
    """Convert to json to save back to file"""
    ext = np.asarray(self.exterior)
    js = OrderedDict()
    js['x0'] = ext[0,0]
    js['y0'] = ext[0,1]
    js['x1'] = ext[1,0]
    js['y1'] = ext[1,1]
    js['x2'] = ext[2,0]
    js['y2'] = ext[2,1]
    js['x3'] = ext[3,0]
    js['y3'] = ext[3,1]
    return js

  @staticmethod
  def apply_perspective_transform_matrix(srcShape, transformMatrix):
    """Apply transformation matrix to srcShape.
    Return new rectangle
    """
    src = np.array([srcShape.numpy_format()])
    dst = cv2.perspectiveTransform(src, transformMatrix)
    numpyBox = dst[0]
    bbox = Rectangle([
      (numpyBox[0][0], numpyBox[0][1]),
      (numpyBox[1][0], numpyBox[1][1]),
      (numpyBox[2][0], numpyBox[2][1]),
      (numpyBox[3][0], numpyBox[3][1])])
    return bbox

  @staticmethod
  def get_perspective_transform_matrix(srcShape, dstShape):
    """Get transformation matrix to take srcShape to dstShape.
    Return transformMatrix
    """
    src = srcShape.numpy_format()
    dst = dstShape.numpy_format()
    return cv2.getPerspectiveTransform(src, dst)

  def apply_linear_transform(self, translateX, translateY):
    """Add translateX and translateY to self
    Return new rectangle"""
    b = np.asarray(self.exterior)
    bbox = Rectangle([
      (b[0][0] + translateX, b[0][1] + translateY),
      (b[1][0] + translateX, b[1][1] + translateY),
      (b[2][0] + translateX, b[2][1] + translateY),
      (b[3][0] + translateX, b[3][1] + translateY)])
    return bbox

  def get_linear_transform(self):
    """If self is out of bounds, i.e., has negative coordinates, give translation coordinates.
    Return translateX, translateY
    """
    b = np.asarray(self.exterior)
    translateX = 0
    translateY = 0
    
    # check for negative indices
    if b[0][0] < 0:
      translateX += abs(b[0][0])
    if b[0][1] < 0:
      translateY += abs(b[0][1])
    if b[3][0] < 0:
      translateX += abs(b[3][0])
    if b[1][1] < 0:
      translateY += abs(b[1][1])

    # check for over-compensation
    newR = self.apply_linear_transform(translateX, translateY)
    b = newR.bounds
    if int(b[0]) > 0:
      translateX -= abs(int(b[0]))
    if int(b[1]) > 0:
      translateY -= abs(int(b[1]))
    return translateX, translateY

  @staticmethod
  def rotate_rectangle_for_width_on_xaxis(srcShape):
    """Rotates the rectangle such that the longer edge fall in x-axis"""
    # first rotate to counter-clockwise
    ring = srcShape.exterior
    if not ring.is_ccw:
      ring.coords = list(ring.coords)[::-1]
    b = list(ring.coords)[0:4]

    longestLengthIdx = 0
    longestLength = -1
    # find the longest length
    for i, pt in enumerate(b):
      dist = Point(pt).distance(Point(b[(i + 1) % 4]))
      if dist > longestLength:
        longestLengthIdx = i
        longestLength = dist

    # we know which side is longest - now, figure out which
    # corner should go on left
    if b[longestLengthIdx][0] > b[(longestLengthIdx + 2) % 4][0]:
      longestLengthIdx = (longestLengthIdx + 2) % 4

    # if this is the top
    if ((b[longestLengthIdx][1] > b[(longestLengthIdx + 1) % 4][1]) and
      (b[longestLengthIdx][0] > b[(longestLengthIdx + 1) % 4][0])):
      longestLengthIdx = (longestLengthIdx + 1) % 4
    elif ((b[longestLengthIdx][1] > b[(longestLengthIdx + 3) % 4][1]) and
      (b[longestLengthIdx][0] > b[(longestLengthIdx + 3) % 4][0])):
      longestLengthIdx = (longestLengthIdx + 3) % 4

    # now longestLengthIdx represents the top right corner in the rect

    # create polygon with correct orientation
    poly = shapely.geometry.polygon.orient(Polygon([
      b[longestLengthIdx], 
      b[(longestLengthIdx + 1) % len(b)],
      b[(longestLengthIdx + 2) % len(b)],
      b[(longestLengthIdx + 3) % len(b)]]), 1)
    # convert to rectangle and return
    b = np.asarray(poly.exterior)
    bbox = Rectangle([
      (b[0][0], b[0][1]),
      (b[1][0], b[1][1]),
      (b[2][0], b[2][1]),
      (b[3][0], b[3][1])])
    return bbox
  
  @staticmethod
  def get_correctly_rotated_rectangle(srcShape):
    """If XML notation doesn't have polygon rotated such that, 
    X0,Y0 - top upper corner and vertices - in clockwise direction,
    then realign coordinates so that it is correctly rotated"""
    bound = srcShape.bounds
    topLeftPt = Point(bound[0], bound[1])
    b = list(srcShape.exterior.coords)[0:4]
    closestPtIndex = 0
    leastDist = float("inf")
    # first find the closest point to the XY bounds and call it X0,Y0
    for i, pt in enumerate(b):
      dist = topLeftPt.distance(Point(pt))
      if dist < leastDist:
        closestPtIndex = i
        leastDist = dist
    # create polygon with correct orientation
    poly = shapely.geometry.polygon.orient(Polygon([
      b[closestPtIndex], 
      b[(closestPtIndex + 1) % len(b)],
      b[(closestPtIndex + 2) % len(b)],
      b[(closestPtIndex + 3) % len(b)]]), 1)
    # convert to rectangle and return
    b = np.asarray(poly.exterior)
    bbox = Rectangle([
      (b[0][0], b[0][1]),
      (b[1][0], b[1][1]),
      (b[2][0], b[2][1]),
      (b[3][0], b[3][1])])
    return bbox

  def __str__(self):
    b = self.bounds
    return "X: " + str(int(b[0])) + \
      ", Y: " + str(int(b[1])) + \
      ", W: " + str(int(b[2] - b[0])) + \
      ", H: " + str(int(b[3] - b[1]))