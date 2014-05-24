require_relative 'Rectangle.rb'

class CoordinateMath
	def poly_to_square(imageConstraintRect, polygon)
		p = polygon
		# for now, center the square around the center of the polygon
		xMinMax = [p.x0, p.x1, p.x2, p.x3].minmax
		yMinMax = [p.y0, p.y1, p.y2, p.y3].minmax
		widthHeight = [xMinMax[1] - xMinMax[0], yMinMax[1] - yMinMax[0]].max
		xNew = Integer(xMinMax[0] + (xMinMax[1] - xMinMax[0])/2 - widthHeight/2)
		yNew = Integer(yMinMax[0] + (yMinMax[1] - yMinMax[0])/2 - widthHeight/2)

		xNew = 0 if xNew < 0; xNew = imageConstraintRect.x2 if xNew > imageConstraintRect.x2
		yNew = 0 if yNew < 0; yNew = imageConstraintRect.y1 if yNew > imageConstraintRect.y1

		minSquare = Rectangle.new
		minSquare.from_dimension(xNew, yNew, widthHeight, widthHeight)
		squareDimension = Rectangle.new
		squareDimension.from_dimension(0, 0, widthHeight, widthHeight)
		square = resize_to_match(imageConstraintRect, minSquare, squareDimension)
		if not square.is_square?
			raise RuntimeError, "CoordinateMath: Couldn't construct a square from polygon"
		end
		return square
	end

	# return a rectangle that can be cut from image according to outputDimension requirement
	# Assumes: all inputs are Rectangles (and not parallelograms or other types of polygons)
	# Assumes: inputRect and outputRequirementRect have same aspect ratio
	def resize_to_match(imageConstraintRect, inputRect, outputRequirementRect)
		rect = Rectangle.new

		# if inputRect is larger than imageConstraintRect
		if not inputRect.inside_of?(imageConstraintRect)
			# for now, not handling this case - will be necessary if we want to shear
			raise RuntimeError, "CoordinateMath: Not implemented shear related resizing"
		end

		# if inputRect fits inside imageConstraintRect 
		if inputRect.has_larger_area_than?(outputRequirementRect)
			# if we need to shrink, that will be done by convert
			rect = inputRect
		else
			# if we need to enlarge, do it one pixel at a time until we either
			# (a) go out of bounds or (b) become as big as outputRequirementRect dictates
			rect.from_dimension(inputRect.x0, inputRect.y0, inputRect.width, inputRect.height)
			while (rect.inside_of?(imageConstraintRect) && 
				outputRequirementRect.has_larger_area_than?(rect)) do

				# pixel by pixel increase
				if rect.x0 == imageConstraintRect.x0
					if rect.x2 == imageConstraintRect.x2
						break
					else
						x0 = rect.x0; x2 = rect.x2 + 2
					end
				else
					if rect.x2 == imageConstraintRect.x2
						x0 = rect.x0 - 2
					else
						x0 = rect.x0 - 1; x2 = rect.x2 + 1
					end
				end
				x1 = x0; x3 = x2

				if rect.y0 == imageConstraintRect.y0
					if rect.y1 == imageConstraintRect.y1
						break
					else
						y0 = rect.y0; y1 = rect.y1 + 2
					end
				else
					if rect.y1 == imageConstraintRect.y1
						y0 = rect.y0 - 2
					else
						y0 = rect.y0 - 1; y1 = rect.y1 + 1
					end
				end
				y2 = y0; y3 = y1

				rect.from_points(x0, y0, x1, y1, x2, y2, x3, y3)
			end
		end
		return rect
	end
end
