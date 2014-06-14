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

		xCenter = Integer(xMinMax[0] + (xMinMax[1] - xMinMax[0])/2)
		yCenter = Integer(yMinMax[0] + (yMinMax[1] - yMinMax[0])/2)

		xCenter = 1 if xCenter < 1
		xCenter = imageConstraintRect.x2 - 1 if xCenter > imageConstraintRect.x2 - 1
		yCenter = 1 if yCenter < 1
		yCenter = imageConstraintRect.y1 - 1 if yCenter > imageConstraintRect.y1 - 1

		minSquare = Rectangle.new
		minSquare.from_dimension(xCenter, yCenter, 1, 1)
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

	def get_negative_candidates(imageConstraintRect, labelRect, outputRequirementRect, numOfPatches)
		patchCandidates = []
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
		return patchCandidates if possibleWindows.count == 0

		for i in 0..numOfPatches
			# if window is possible, choose one in random
			chosenWindow = possibleWindows[rand(possibleWindows.count)]
			# to create subwindow, look at places where it will go out of bounds
			xMax = chosenWindow.x2 - chosenWindow.x0 - oc.width
			yMax = chosenWindow.y1 - chosenWindow.y0 - oc.height
			if xMax > 0 && yMax > 0
				rect = Rectangle.new
				rect.from_dimension(
					chosenWindow.x0 + rand(xMax), chosenWindow.y0 + rand(yMax), 
					oc.width, oc.height)
				patchCandidates << rect
			end
		end
		return patchCandidates
	end

	def get_patch_candidates(imageConstraintRect, inputRect, outputRequirementRect, minPixelMove)
		patchCandidates = []
		ic = imageConstraintRect
		ir = inputRect
		oc = outputRequirementRect

		centerInputRect = Rectangle.new
		xCenter, yCenter = inputRect.get_center
		smallWidth, smallHeight = outputRequirementRect.smallest_proportional_dimensions
		centerInputRect.from_dimension(xCenter, yCenter, smallWidth, smallHeight)

		# if inputRect has larger dimension than outputRequirementRect, this image needs resizing
		if not outputRequirementRect.has_larger_dimensions_than?(inputRect)
			# however, pass through a patch if it contain at least 85% of inputRect
			largePatchCandidate = resize_to_match(imageConstraintRect, centerInputRect, outputRequirementRect)
			if inputRect.overlap_fraction(largePatchCandidate) > 0.85
				patchCandidates << largePatchCandidate
			end
			return patchCandidates
		end

		# no matter what, get at least the first patch
		patchCandidates << resize_to_match(imageConstraintRect, centerInputRect, outputRequirementRect)

		# new image constraints
		newImageConstraints = []

		# possible rectangle towards the left
		leftMinPx = (ir.x2 - oc.width) > ic.x0 ? (ir.x2 - oc.width) : ic.x0
		leftMinSteps = Integer((ir.x0 - leftMinPx) * 1.0 / minPixelMove)
		for steps in 0..leftMinSteps
			icNew = Rectangle.new
			icNew.from_points(
				ir.x0 - steps * minPixelMove, ic.y0,
				ir.x1 - steps * minPixelMove, ic.y1,
				ic.x2, ic.y2,
				ic.x3, ic.y3)
			newImageConstraints << icNew if icNew.has_larger_dimensions_than?(outputRequirementRect)
		end

		# possible rectangle towards the right
		rightMaxPx = (ir.x0 + oc.width) < ic.x2 ? (ir.x0 + oc.width) : ic.x2
		rightMaxSteps = Integer((rightMaxPx - ir.x2) * 1.0 / minPixelMove)
		for steps in 0..rightMaxSteps
			icNew = Rectangle.new
			icNew.from_points(
				ic.x0, ic.y0,
				ic.x1, ic.y1,
				ir.x2 + steps * minPixelMove, ic.y2,
				ir.x3 + steps * minPixelMove, ic.y3)
			newImageConstraints << icNew if icNew.has_larger_dimensions_than?(outputRequirementRect)
		end

		# possible rectangle towards the top
		topMinPx = (ir.y1 - oc.height) > ic.y0 ? (ir.y1 - oc.height) : ic.y0
		topMinSteps = Integer((ir.y0 - topMinPx) * 1.0 / minPixelMove)
		for steps in 0..topMinSteps
			icNew = Rectangle.new
			icNew.from_points(
				ic.x0, ir.y0 - steps * minPixelMove,
				ic.x1, ic.y1,
				ic.x2, ir.y2 - steps * minPixelMove,
				ic.x3, ic.y3)
			newImageConstraints << icNew if icNew.has_larger_dimensions_than?(outputRequirementRect)
		end


		# possible rectangle towards the bottom
		bottomMaxPx = (ir.y0 + oc.height) < ic.y1 ? (ir.y0 + oc.height) : ic.y1
		bottomMaxSteps = Integer((bottomMaxPx - ir.y1) * 1.0 / minPixelMove)
		bottomMaxSteps = Integer((bottomMaxPx - ir.y1) * 1.0 / minPixelMove)
		for steps in 0..bottomMaxSteps
			icNew = Rectangle.new
			icNew.from_points(
				ic.x0, ic.y0,
				ic.x1, ir.y1 + steps * minPixelMove,
				ic.x2, ic.y2,
				ic.x3, ir.y3 + steps * minPixelMove)
			newImageConstraints << icNew if icNew.has_larger_dimensions_than?(outputRequirementRect)
		end

		# puts "leftMinPx: #{leftMinPx};     leftMinSteps: #{leftMinSteps}"
		# puts "rightMaxPx: #{rightMaxPx};   rightMaxSteps: #{rightMaxSteps}"
		# puts "topMinPx: #{topMinPx};       topMinSteps: #{topMinSteps}"
		# puts "bottomMaxPx: #{bottomMaxPx}; bottomMaxSteps: #{bottomMaxSteps}"

		newImageConstraints.each do |newImageConstraint|
			resizedRect = resize_to_match(newImageConstraint, centerInputRect, outputRequirementRect)
			if (resizedRect != nil) && (not array_has_rectangle?(patchCandidates, resizedRect))
				patchCandidates << resizedRect
			end
		end

		# patchCandidates.each do |patch|
		# 	patch.print
		# end
		return patchCandidates
	end

	# return a rectangle that can be cut from image according to outputDimension requirement
	# Assumes: all inputs are Rectangles (and not parallelograms or other types of polygons)
	# Assumes: inputRect and outputRequirementRect have same aspect ratio
	def resize_to_match(imageConstraintRect, inputRect, outputRequirementRect)
		rect = Rectangle.new

		# if inputRect falls out of imageConstraintRect
		if not inputRect.inside_of?(imageConstraintRect)
			raise RuntimeError, "CoordinateMath: Requested patch falls out of image boundary"
		end
		# if outputRequirement is larger than imageConstraintRect
		if outputRequirementRect.has_larger_dimensions_than?(imageConstraintRect)
			raise RuntimeError, "CoordinateMath: Image too small for output patch size"
		end
		# resizing is done at a layer above this - so freak out
		if inputRect.has_larger_area_than?(outputRequirementRect)
			raise RuntimeError, "CoordinateMath: Resize request not supported"
		end

		# if we need to enlarge, do it one pixel at a time until we either
		# (a) go out of bounds or (b) become as big as outputRequirementRect dictates
		rect.from_dimension(inputRect.x0, inputRect.y0, inputRect.width, inputRect.height)
		while (rect.inside_of?(imageConstraintRect) && 
			(outputRequirementRect.has_larger_area_than?(rect))) do
			# pixel by pixel increase

			# left of rect before left of imageConstraintRect
			if rect.x0 <= imageConstraintRect.x0
				# right of rect after right of imageConstraintRect
				if rect.x2 >= imageConstraintRect.x2
					x0 = rect.x0; x2 = rect.x2
					break
				else
					if outputRequirementRect.width >= rect.width
						x0 = rect.x0; x2 = rect.x2 + 2
					else
						x0 = rect.x0; x2 = rect.x2
					end
				end
			else
				if rect.x2 >= imageConstraintRect.x2
					if outputRequirementRect.width >= rect.width
						x0 = rect.x0 - 2; x2 = rect.x2
					else
						x0 = rect.x0; x2 = rect.x2
					end
				else
					if outputRequirementRect.width >= rect.width
						x0 = rect.x0 - 1; x2 = rect.x2 + 1
					else
						x0 = rect.x0; x2 = rect.x2
					end
				end
			end
			x1 = x0; x3 = x2

			# top of rect above top of imageConstraintRect
			if rect.y0 <= imageConstraintRect.y0
				# bottom of rect below bottom of imageConstraintRect
				if rect.y1 >= imageConstraintRect.y1
					y0 = rect.y0; y1 = rect.y1
					break
				else
					if outputRequirementRect.height >= rect.height
						y0 = rect.y0; y1 = rect.y1 + 2
					else
						y0 = rect.y0; y1 = rect.y1
					end
				end
			else
				if rect.y1 >= imageConstraintRect.y1
					if outputRequirementRect.height >= rect.height
						y0 = rect.y0 - 2; y1 = rect.y1
					else
						y0 = rect.y0; y1 = rect.y1
					end
				else
					if outputRequirementRect.height >= rect.height
						y0 = rect.y0 - 1; y1 = rect.y1 + 1
					else
						y0 = rect.y0; y1 = rect.y1
					end
				end
			end
			y2 = y0; y3 = y1

			rect.from_points(x0, y0, x1, y1, x2, y2, x3, y3)
		end
		# fix pixel arithmetic mistake - sometimes gets off by 1
		x0 = rect.x0 < 0 ? 0 : rect.x0
		y0 = rect.y0 < 0 ? 0 : rect.y0
		rect.from_dimension(x0, y0, outputRequirementRect.width, outputRequirementRect.height)

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

	# orders an array of rectangle by the distance from rectangle
	def order_by_distance(array, rectangle)
		retArray = []
		return retArray if array.count == 0
		distHash = {}
		array.each do |a|
			dist = rectangle.get_distance(a)
			distHash.merge!({ dist => a })
		end
		sortedArr = distHash.sort_by { |dist, arr| dist }
		sortedArr.each do |sa|
			retArray << sa[1]
		end
		return retArray
	end

	private
		def array_has_rectangle?(array, rectangle)
			array.each do |ar|
				# if the overlap is larger than 95%, consider rectangle already included
				if ar.overlap_fraction(rectangle) > 0.95
					return true
				end
			end
			return false
		end
end
