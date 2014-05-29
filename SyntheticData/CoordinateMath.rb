require_relative 'Rectangle.rb'

class CoordinateMath
	def poly_to_rectangle(imageConstraintRect, polygon)
		p = polygon
		# for now, center the rectangle around the center of the polygon
		xMinMax = [p.x0, p.x1, p.x2, p.x3].minmax
		yMinMax = [p.y0, p.y1, p.y2, p.y3].minmax
		width = xMinMax[1] - xMinMax[0]
		height = yMinMax[1] - yMinMax[0]
		xNew = Integer(xMinMax[0] + (xMinMax[1] - xMinMax[0])/2 - width/2)
		yNew = Integer(yMinMax[0] + (yMinMax[1] - yMinMax[0])/2 - height/2)

		xNew = 0 if xNew < 0; xNew = imageConstraintRect.x2 if xNew > imageConstraintRect.x2
		yNew = 0 if yNew < 0; yNew = imageConstraintRect.y1 if yNew > imageConstraintRect.y1

		rect = Rectangle.new
		rect.from_dimension(xNew, yNew, width, height)
		return rect
	end

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

	def get_negative_candidate(imageConstraintRect, labelRect, outputRequirementRect)
		ic = imageConstraintRect
		lr = labelRect
		oc = outputRequirementRect

		clearanceTop 			= lr.y0 - ic.y0
		clearanceBottom 	= ic.y1 - lr.y1
		clearanceLeft			= lr.x0 - ic.x0
		clearanceRight		= ic.x2 - lr.x2

		possibleWindows = []
		if clearanceTop > oc.height
			rect = Rectangle.new
			possibleWindows << rect.from_dimension(ic.x0, ic.y0, ic.width, clearanceTop)
		end
		if clearanceBottom > oc.height
			rect = Rectangle.new
			possibleWindows << rect.from_dimension(ic.x0, lr.y1, ic.width, clearanceBottom)
		end
		if clearanceLeft > oc.width
			rect = Rectangle.new
			possibleWindows << rect.from_dimension(ic.x0, ic.y0, clearanceLeft, ic.height)
		end
		if clearanceRight > oc.width
			rect = Rectangle.new
			possibleWindows << rect.from_dimension(lr.x2, ic.y0, clearanceRight, ic.height)
		end

		# if no possible windows, then return nil
		return nil if possibleWindows.count == 0

		# if window is possible, choose one in random
		chosenWindow = possibleWindows[rand(possibleWindows.count)]
		# to create subwindow, look at places where it will go out of bounds
		xMax = chosenWindow.x2 - chosenWindow.x0 - oc.width
		yMax = chosenWindow.y1 - chosenWindow.y0 - oc.height
		return nil if (xMax <= 0) || (yMax <= 0)

		# form the new rectangle and return
		rect = Rectangle.new
		rect.from_dimension(chosenWindow.x0 + rand(xMax), chosenWindow.y0 + rand(yMax), oc.width, oc.height)

		# puts "chosenWindow: "
		# chosenWindow.print
		# puts "rect: "
		# rect.print
		return rect
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

	def sliding_window_boxes(imageConstraintRect, outputRequirementRect, xStride, yStride)
		slidingWindowBoxes = []
		ic = imageConstraintRect
		oc = outputRequirementRect

		xSteps = Integer((ic.x2 - ic.x0 - 1) * 1.0 / xStride)
		ySteps = Integer((ic.y1 - ic.y0 - 1) * 1.0 / yStride)

		for xStep in 0..(xSteps - 1)
			for yStep in 0..(ySteps - 1)
				xStart = xStep * xStride
				yStart = yStep * yStride

				# if going out of bounds
				xStart = ic.x2 - oc.width  if (xStart + oc.width)  > ic.x2
				yStart = ic.y1 - oc.height if (yStart + oc.height) > ic.y1
				
				rect = Rectangle.new
				rect.from_dimension(xStart, yStart, oc.width, oc.height)
				slidingWindowBoxes << rect
			end
		end
		return slidingWindowBoxes
	end
end
