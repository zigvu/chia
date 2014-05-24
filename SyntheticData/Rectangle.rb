class Rectangle
	# use imagemagick conventions:
	# x0, y0: left top corner
	# x1, y1: left bottom corner
	# x2, y2: right top corner
	# x3, y3: right bottom corner
	attr_accessor :x0, :y0, :x1, :y1, :x2, :y2, :x3, :y3
	attr_accessor :width, :height

	def from_points(x0, y0, x1, y1, x2, y2, x3, y3)
		@x0 = x0; @y0 = y0; @x1 = x1; @y1 = y1
		@x2 = x2; @y2 = y2; @x3 = x3; @y3 = y3
		@width = x3 - x0
		@height = y3 - y0
	end

	def from_dimension(x0, y0, width, height)
		@x0 = x0;					@y0 = y0
		@x1 = x0;					@y1 = y0 + height
		@x2 = x0 + width; @y2 = y0
		@x3 = x0 + width; @y3 = y0 + width
		@width = width; 	@height = height
	end

	def equals(newRectangle)
		r = newRectangle
		return (
			(@x0 == r.x0) && (@y0 == r.y0) &&
			(@x1 == r.x1) && (@y1 == r.y1) &&
			(@x2 == r.x2) && (@y2 == r.y2) &&
			(@x3 == r.x3) && (@y3 == r.y3))
	end

	# if this rectangle fits inside outsideRectangle
	def inside_of?(outsideRectangle)
		r = outsideRectangle
		return (
			(@x0 >= r.x0) && (@y0 >= r.y0) &&
			(@x1 >= r.x1) && (@y1 <= r.y1) &&
			(@x2 <= r.x2) && (@y2 >= r.y2) &&
			(@x3 <= r.x3) && (@y3 <= r.y3))
	end

	# if this rectangle has lareger area than another rectangle
	def has_larger_area_than?(anotherRectangle)
		r = anotherRectangle
		return (@width * @height >=  r.width * r.height)
	end

	def is_square?
		return @width == @height
	end

	def print
		puts "#{@x0},#{@y0}   #{@x1},#{@y1}   #{@x2},#{@y2}   #{@x3},#{@y3}; w:#{@width} h:#{@height}"
	end
end
