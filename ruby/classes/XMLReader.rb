require 'active_support/core_ext/hash'
require 'nokogiri'

require_relative 'Rectangle.rb'

class XMLReader
	attr_accessor :imageFileName, :imageDimension

	def initialize(xmlFileName, baseImageFolder)
		@xmlFileName = xmlFileName

		xml = Nokogiri::XML(File.read(@xmlFileName))
		h  = Hash.from_xml(xml.to_s)
		@imageFileName = "#{baseImageFolder}/#{h['annotation']['filename']}"

		@imageDimension = Rectangle.new
		imageWidth = Integer(Float("#{h['annotation']['imageWidth']}"))
		imageHeight = Integer(Float("#{h['annotation']['imageHeight']}"))
		@imageDimension.from_dimension(0, 0, imageWidth, imageHeight)

		# file can have one or more objects
		@annotatedObjects = {}
		annoObj = h['annotation']['object']
		if annoObj.kind_of? Hash
			name = h['annotation']['object']['name']
			poly = h['annotation']['object']['polygon']['pt']
			rectangles = [get_polygon(poly)]
			@annotatedObjects.merge!({:"#{name}" => rectangles})
		elsif annoObj.kind_of? Array
			annoObj.each do |aObj|
				name = aObj['name']
				poly = aObj['polygon']['pt']
				rectangles = @annotatedObjects[:"#{name}"]
				if rectangles == nil
					rectangles = [get_polygon(poly)]
				else
					rectangles = rectangles + [get_polygon(poly)]
				end
				@annotatedObjects.merge!({:"#{name}" => rectangles})
			end
		else
			raise RuntimeError, "XMLReader: No objects found in XML file"
		end
	end

	def get_rectangles(name)
		return @annotatedObjects[:"#{name}"]
	end

	def get_object_names
		objectNames = []
		@annotatedObjects.each do |k,v|
			objectNames << k.to_s
		end
		return objectNames
	end

	private
		def get_polygon(poly)
			# get square coordinates
			if poly.count != 4
				poly.each_with_index do |p, index|
					puts "#{index} : #{p}"
				end
				raise RuntimeError, "XMLReader: Polygon in XML file not quadrilateral"
			end

			polygon = Rectangle.new
			polygon.from_points(
				Integer(Float(poly[0]['x'])), Integer(Float(poly[0]['y'])),
				Integer(Float(poly[1]['x'])),	Integer(Float(poly[1]['y'])),
				Integer(Float(poly[2]['x'])),	Integer(Float(poly[2]['y'])),
				Integer(Float(poly[3]['x'])),	Integer(Float(poly[3]['y'])))
			return polygon
		end
end
