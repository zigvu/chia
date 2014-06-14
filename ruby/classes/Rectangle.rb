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
		@width = x2 - x0
		@height = y1 - y0
		return self
	end

	def from_dimension(x0, y0, width, height)
		@x0 = x0;					@y0 = y0
		@x1 = x0;					@y1 = y0 + height
		@x2 = x0 + width; @y2 = y0
		@x3 = x0 + width; @y3 = y0 + height
		@width = width; 	@height = height
		return self
	end

	def equals?(anotherRectangle)
		r = anotherRectangle
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

	def has_larger_dimensions_than?(anotherRectangle)
		r = anotherRectangle
		return ((@width >=  r.width) && (@height >= r.height))
	end

	# what fraction of this rectangle overlaps with another rectangle
	def overlap_fraction(anotherRectangle)
		r = anotherRectangle
		xOverlap = [0, ([@x2, r.x2].min - [@x0, r.x0].max)].max
		yOverlap = [0, ([@y1, r.y1].min - [@y0, r.y0].max)].max
		return (1.0 * xOverlap * yOverlap / (@width * @height)).round(1)
	end

	def get_distance(anotherRectangle)
		aXC, aYC = anotherRectangle.get_center
		bXC, bYC = get_center
		return Math.sqrt(((aXC - bXC) * (aXC - bXC)) + ((aYC - bYC) * (aYC - bYC)))
	end

	def is_square?
		return @width == @height
	end

	def get_center
		xCenter = Integer(@x0 + @width * 0.5)
		yCenter = Integer(@y0 + @height * 0.5)
		return xCenter, yCenter
	end

	def get_area
		return @width * @height
	end

	# round dimension to first decimal place
	def smallest_proportional_dimensions
		if @width == @height
			smallWidth = 1
			smallHeight = 1
		else
			lc = Integer(@width).lcm(Integer(@height))
			smallWidth = lc / Integer(@height)
			smallHeight = lc / Integer(@width)
		end
		return smallWidth, smallHeight
	end

	# apply the same transformation to self as that which
	# took originalRect to transformedRect
	def get_rectangular_transform(originalRect, transformedRect)
		widthScale = 1.0 * transformedRect.width / originalRect.width 
		heightScale = 1.0 * transformedRect.height / originalRect.height
		r = Rectangle.new
		r.from_points(
			Integer(widthScale * @x0),    Integer(heightScale * @y0), 
			Integer(widthScale * @x1),    Integer(heightScale * @y1), 
			Integer(widthScale * @x2),    Integer(heightScale * @y2), 
			Integer(widthScale * @x3),    Integer(heightScale * @y3))
		return r
	end

	def to_hash
		return {x: @x0, y: @y0, width: @width, height: @height}
	end

	def print
		puts "#{@x0},#{@y0}   #{@x1},#{@y1}   #{@x2},#{@y2}   #{@x3},#{@y3}; w:#{@width} h:#{@height}"
	end

	def to_csv
		return "#{@x0},#{@y0},#{@x1},#{@y1},#{@x2},#{@y2},#{@x3},#{@y3}"
	end
end
