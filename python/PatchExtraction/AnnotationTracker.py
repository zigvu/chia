import os
import json
import logging
from collections import OrderedDict

class AnnotationTracker:
  """Writes tracking information for each annotation"""
  def __init__(self, outputFolder):
    """Initialize"""
    self.outputFolder = outputFolder
    # format:
    # {annotation_id: [patch_file_name, ]}
    self.annotations_to_track = OrderedDict()

  def addPatch(self, annotationId, patchFileName):
    """Add patch to storage"""
    if not annotationId in self.annotations_to_track:
      self.annotations_to_track[annotationId] = []
    self.annotations_to_track[annotationId] += [patchFileName]

  def save(self):
    """Save dict"""
    logging.debug("Saving file")
    for annotationId, patchFileNames in self.annotations_to_track.iteritems():
      # save
      fileToSave = os.path.join(self.outputFolder, annotationId + ".json")
      with open(fileToSave, "w") as fd :
        saveJSON = {'annotation_id': annotationId, 'patches': patchFileNames}
        json.dump( saveJSON, fd, indent=2 )
