require 'json'
require 'fileutils'
require 'shellwords'

require_relative 'Rectangle.rb'

class ImageMagick
	def initialize
	end

	def resize(inputFileName, rectangle, outputFileName)
		r = rectangle
		bash("convert #{inputFileName} \
			-resize #{r.width}x#{r.height} \
			#{outputFileName}")
	end

	def resize_exact(inputFileName, rectangle, outputFileName)
		r = rectangle
		bash("convert #{inputFileName} \
			-resize #{r.width}x#{r.height}\! \
			#{outputFileName}")
	end

	def crop(inputFileName, rectangle, outputFileName)
		r = rectangle
		bash("convert #{inputFileName} -crop \
			#{r.width}x#{r.height}+#{r.x0}+#{r.y0}\! \
			#{outputFileName}")
		# sometimes crop misses a few pixels, so need to resize
		resize_exact(outputFileName, rectangle, outputFileName)
	end

	def draw_poly(inputFileName, rectangle, outputFileName, text = '')
		r = rectangle
		# draw each line of rectangle by joining two consecutive points counter-clockwise
		bash("convert #{inputFileName} -fill transparent -stroke #{next_color} \
			-draw \"polygon \
			#{r.x0},#{r.y0} #{r.x1},#{r.y1} \
			#{r.x3},#{r.y3} #{r.x2},#{r.y2} \" \
			-font Bookman-Light -pointsize 20 -gravity North-West \
			-draw \"text #{r.x0},#{r.y0} '#{text}' \" \
		 #{outputFileName}")
	end

	def draw_center(inputFileName, rectangle, outputFileName)
		radius = 3
		center_x = rectangle.x0 + rectangle.width / 2
		center_y = rectangle.y0 + rectangle.height / 2
		bash("convert #{inputFileName} -fill red \
		 -draw \"circle #{center_x},#{center_y} #{center_x + radius},#{center_y}\" \
		 #{outputFileName}")
	end

	# return Rectangle
	def identify(inputFileName)
		imgWidth = bash("identify -format '%w' #{inputFileName}")
		imgHeight = bash("identify -format '%h' #{inputFileName}")
		rectangle = Rectangle.new
		rectangle.from_dimension(0, 0, Integer(imgWidth), Integer(imgHeight))
		return rectangle
	end

	def bash(command)
	  escaped_command = Shellwords.escape(command)
	  return `bash -c #{escaped_command}`
	end

	private
		def next_color
			colors = ['red', 'blue', 'black', 'green', 'white']
			@colorIndex = @colorIndex || 0
			color = colors[@colorIndex]
			@colorIndex = @colorIndex + 1
			@colorIndex = 0 if @colorIndex >= colors.count
			return color
		end
end
