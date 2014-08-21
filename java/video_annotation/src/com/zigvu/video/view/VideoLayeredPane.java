package com.zigvu.video.view;

import java.awt.*;
import java.awt.event.*;
import java.util.ArrayList;
import java.util.List;

import javax.swing.*;

import com.zigvu.video.annotation.Annotator;

@SuppressWarnings("serial")
public class VideoLayeredPane extends JLayeredPane {
	private JPanel videoPlayer;
	private JLabel currentFrameLabel;
	private List<ResizablePolygon> rePolys;
	private ResizablePolygon newPolyToAdd;
	private ResizablePolygon currentlySelectedPoly;
	private boolean creatingNewPolyToAdd = false;
	private int layerCount;
	private static final int layerCountStartForLogos = 2;
	private boolean layersEnabled;

	private int paneWidth, paneHeight;

	private Color curLogoColor;
	private int curLogoIndex = -1;
	private String curLogoName;

	public VideoLayeredPane(int width, int height) {
		Annotator.log(Annotator.logInfo, "VideoLayeredPane: Setting up");
		paneWidth = width;
		paneHeight = height;
		this.setPreferredSize(new Dimension(width, height));
		VideoLayeredPaneListner videoLayeredPaneListner = new VideoLayeredPaneListner();
		this.addMouseListener(videoLayeredPaneListner);
		this.addMouseMotionListener(videoLayeredPaneListner);
		rePolys = new ArrayList<ResizablePolygon>();
		layerCount = layerCountStartForLogos;
	}

	public void setVideoPlayer(JPanel vp) {
		videoPlayer = vp;
		this.add(vp, new Integer(0));
	}

	public void setCurrentFrame(ImageIcon img) {
		Annotator.log(Annotator.logInfo, "VideoLayeredPane: Set current frame");
		currentFrameLabel = new JLabel(img);
		currentFrameLabel.setBounds(0, 0, paneWidth, paneHeight);
		this.add(currentFrameLabel, new Integer(1));
		this.validate();
		this.repaint();
	}

	public void removeCurrentFrame() {
		Annotator.log(Annotator.logInfo,
				"VideoLayeredPane: Remove current frame");
		try {
			this.remove(currentFrameLabel);
		} catch (Exception e) {
			// do nothing for now
		}
		this.validate();
		this.repaint();
		curLogoIndex = -1;
	}

	public void enableAllLayers() {
		layersEnabled = true;
	}

	public void resetAllLayers() {
		resetNewPoly();
		for (ResizablePolygon rePoly : rePolys) {
			this.remove(rePoly);
		}
		this.validate();
		this.repaint();
		rePolys = new ArrayList<ResizablePolygon>();
		layerCount = layerCountStartForLogos;
		layersEnabled = false;
	}

	public void setNewLogo(Color bgColor, int logoIndex, String logoName) {
		// if creating a new poly, discard
		resetNewPoly();
		curLogoColor = bgColor;
		curLogoIndex = logoIndex;
		curLogoName = logoName;
	}

	public void deleteSelectedLogo() {
		// if creating a new poly
		resetNewPoly();
		// reset currently selected polygon
		if (currentlySelectedPoly != null) {
			rePolys.remove(currentlySelectedPoly);
			this.remove(currentlySelectedPoly);
			this.validate();
			this.repaint();
			currentlySelectedPoly = null;
		}
	}

	public void addPolyFromAnnotation(Polygon po) {
		ResizablePolygon tempPoly = new ResizablePolygon(paneWidth, paneHeight,
				curLogoColor, curLogoIndex, curLogoName, po);
		this.addResizablePoly(tempPoly);
		Annotator.log(Annotator.logDebug,
				"VideoLayeredPane: Add new logo: Name: " + curLogoName + "; "
						+ tempPoly.toString());
	}

	public void addResizablePoly(ResizablePolygon rp) {
		rePolys.add(rp);
		this.add(rp, new Integer(layerCount++));
	}

	public void removeResizablePoly(ResizablePolygon rp) {
		rePolys.remove(rp);
		this.remove(rp);
		this.validate();
		this.repaint();
		layerCount--;
	}

	protected void addPointToNewPoly(int x, int y) {
		// if no logo has been selected, then do nothing
		if (curLogoIndex == -1) {
			return;
		}
		// if there was a previous newPolyToAdd on which
		// points were already being added, add to it
		if (creatingNewPolyToAdd) {
			newPolyToAdd.addPointToPoly(x, y);
			if (newPolyToAdd.isPolyComplete()) {
				Annotator.log(Annotator.logDebug,
						"VideoLayeredPane: Add new logo: Name: " + curLogoName
								+ "; " + newPolyToAdd.toString());
				// if new poly is complete, then can't add here
				creatingNewPolyToAdd = false;
			}
		} else {
			creatingNewPolyToAdd = true;
			newPolyToAdd = new ResizablePolygon(paneWidth, paneHeight,
					curLogoColor, curLogoIndex, curLogoName);
			this.addResizablePoly(newPolyToAdd);
			newPolyToAdd.addPointToPoly(x, y);
		}
	}

	public void resetNewPoly() {
		if (creatingNewPolyToAdd) {
			creatingNewPolyToAdd = false;
			removeResizablePoly(newPolyToAdd);
		}
	}

	public List<Polygon> getPolygons(int logoIndex) {
		List<Polygon> logoPolys = new ArrayList<Polygon>();
		for (ResizablePolygon rePoly : rePolys) {
			if (rePoly.getLogoIndex() == logoIndex) {
				logoPolys.add(rePoly.getPoly());
			}
		}
		return logoPolys;
	}

	private class VideoLayeredPaneListner extends MouseAdapter {
		@Override
		public void mouseClicked(MouseEvent e) {
			// if layers are not enabled, clicking has no effect
			if (!layersEnabled) {
				return;
			}
			// reset currently selected polygon
			if (currentlySelectedPoly != null) {
				currentlySelectedPoly.unSelect();
				currentlySelectedPoly = null;
			}
			// if right click, select previously made poly
			if (e.getButton() == MouseEvent.BUTTON2
					|| e.getButton() == MouseEvent.BUTTON3) {
				// discard any new poly that were being made
				resetNewPoly();
				for (ResizablePolygon rePoly : rePolys) {
					if (rePoly.contains(e.getPoint())) {
						rePoly.select();
						currentlySelectedPoly = rePoly;
					} else {
						rePoly.unSelect();
					}
				}
			}
			// if left click, add new points to creating poly
			if (e.getButton() == MouseEvent.BUTTON1) {
				Annotator.log(Annotator.logInfo, "VideoLayeredPane: Click: ("
						+ e.getX() + ", " + e.getY() + ")");
				addPointToNewPoly(e.getX(), e.getY());
			}
		}

		@Override
		public void mouseDragged(MouseEvent e) {
			// if layers are not enabled, dragging has no effect
			if (!layersEnabled) {
				return;
			}
			if (currentlySelectedPoly != null) {
				currentlySelectedPoly.dragCorner(e.getX(), e.getY());
			}
		}
	}
}
