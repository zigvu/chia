import os
import logging, json
from collections import OrderedDict
from JSONReader import JSONReader
from Rectangle import Rectangle

class AnnotationModifier:
	"""Class for modifying existing annotations"""
	def __init__(self, configReader, modificationFile):
		"""Initialize class"""
		self.configReader = configReader
		self.modificationFile = modificationFile
		self.modifications = None
		self.modificationRectCache = OrderedDict()
		if os.path.isfile(self.modificationFile):
			# file exists, read
			logging.info("Modification file exists, reading")
			with open(self.modificationFile) as fd:
				self.modifications = json.load(fd)
		else:
			# file doesn't exist, so empty OrderedDict
			logging.info("Modification file doesn't exist, creating")
			self.modifications = OrderedDict()

	def get_all_base_annotations(self):
		"""Get all base annotations currently present in file"""
		return self.modifications.keys()

	def add_base_annotation(self, baseAnnotation, baseRect):
		"""Add a baseAnnotation to file"""
		if not (baseAnnotation in self.get_all_base_annotations()):
			logging.info("Adding base annotation %s" % baseAnnotation)
			self.modifications[baseAnnotation] = OrderedDict()
			self.modifications[baseAnnotation]['base_rect'] = baseRect.dict_format()
			self.modifications[baseAnnotation]['modifications'] = OrderedDict()
		else:
			raise RuntimeError("Base annotation already exists!")

	def add_modification(self, baseAnnotation, modificationName, modificationRect):
		"""Add a modification to the baseAnnotation"""
		if not (baseAnnotation in self.get_all_base_annotations()):
			raise RuntimeError("Base annotation doesn't exist")
		if modificationName in self.modifications[baseAnnotation]['modifications'].keys():
			raise RuntimeError("Modification class %s already exists" % modificationName)
		logging.info("Adding modification %s" % modificationName)
		self.modifications[baseAnnotation]['modifications'][modificationName] = modificationRect.dict_format()

	def get_base_rect(self, baseAnnotation):
		"""Get base rectangle for the baseAnnotation"""
		return self.modifications[baseAnnotation]['base_rect']

	def get_modifications(self, baseAnnotation):
		"""Return all modifications for the baseAnnotation"""
		return self.modifications[baseAnnotation]['modifications']

	def modify_file(self, inputJsonFileName, outputJsonFileName):
		"""Based on current modification file, modify all annotations in this JSON file"""
		if not os.path.isfile(inputJsonFileName):
			raise RuntimeError("JSON file %s doesn't exist" % inputJsonFileName)
		if len(self.modifications) == 0:
			raise RuntimeError("Modification file is empty")

		# replace rects
		jsonReader = JSONReader(inputJsonFileName, 'none') # no image folder needed
		for baseAnnotation in self.get_all_base_annotations():
			jsonRects = jsonReader.get_rectangles(baseAnnotation)
			if len(jsonRects) > 0:
				baseRect = JSONReader.get_polygon(self.get_base_rect(baseAnnotation))
				modificationRects = self.get_modifications(baseAnnotation)
				# replace each rect with new rectangles
				logging.debug("%s : Found rect for %s - replace with %s" % ( \
					os.path.basename(inputJsonFileName), baseAnnotation, modificationRects.keys()))
				for mrKey, mrRect in modificationRects.iteritems():
					jsonReader.add_object_name(mrKey)
					modifiedRects = []
					for jsonRect in jsonRects:
						mrRectObj = JSONReader.get_polygon(mrRect)
						transformedRect = mrRectObj.get_transformed_rectangle(baseRect, jsonRect)
						jsonReader.add_rectangle(mrKey, transformedRect)
				# remove baseAnnotation object form JSON file
				jsonReader.remove_object(baseAnnotation)
		# save file
		jsonReader.save(outputJsonFileName)

	def save(self):
		"""Save all modifications"""
		logging.info("Saving modification file")
		with open( self.modificationFile, "w" ) as fd :
			json.dump( self.modifications, fd, indent=2 )
