require 'active_support/core_ext/hash'
require 'nokogiri'

require_relative 'Rectangle.rb'
require_relative 'XMLReader.rb'

class XMLToCSV

	def initialize(xmlFolder, outputFilename)
		array = folder_to_csv(xmlFolder)
		write_arr_to_file(outputFilename, array)
	end

	def write_arr_to_file(filename, array)
		File.open(filename, 'w') do |file|
			file.puts "FileName,ObjectLabel,X0,Y0,X1,Y1,X2,Y2,X3,Y3"
			array.each do |ta|
				file.puts "#{ta}"
			end
		end
	end

	def folder_to_csv(xmlFolder)
		strs = []
		Dir["#{xmlFolder}/*.xml"].each do |xmlFileName|
			begin
				strs << single_xml_to_csv(xmlFileName)
			rescue Exception => e
				puts "Error: #{File.basename(xmlFileName)}: #{e.message}"
			end
		end
		strs.flatten!
		return strs
	end

	def single_xml_to_csv(xmlFileName)
		strs = []
		xmlReader = XMLReader.new(xmlFileName, '/tmp')
		allObjects = xmlReader.get_object_names
		allObjects.each do |obj|
			rectangles = xmlReader.get_rectangles(obj)
			rectangles.each do |rectangle|
				strs << "#{File.basename(xmlFileName)},#{obj},#{rectangle.to_csv}"
			end
		end
		return strs
	end
end
