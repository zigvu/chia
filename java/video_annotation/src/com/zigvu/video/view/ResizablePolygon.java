package com.zigvu.video.view;

import java.awt.*;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.ArrayList;
import java.util.List;

import javax.swing.*;

@SuppressWarnings("serial")
public class ResizablePolygon extends JPanel {
	private static final int RECT_ANCHOR_WH = 10;
	private Poly poly;
	private int logoIndex;

	/**
	 * Start new polygon
	 */
	public ResizablePolygon(int width, int height, Color bgColor, int logoIndex, String logoName, Polygon p) {
		this(width, height, bgColor, logoIndex, logoName);
		poly = new Poly(bgColor, logoName, p);
	}
	
	public ResizablePolygon(int width, int height, Color bgColor, int logoIndex, String logoName) {
		poly = new Poly(bgColor, logoName);
		this.logoIndex = logoIndex;
		this.setBounds(0, 0, width, height);
		this.setOpaque(false);
	}
	
	public int getLogoIndex(){
		return logoIndex;
	}

	// override paint to also paint poly
	@Override
	public void paintComponent(Graphics g) {
		super.paintComponent(g);
		poly.paint(g);
	}

	// override contains to only look for inside poly
	@Override
	public boolean contains(Point p) {
		return poly.contains(p);
	}

	public void select() {
		poly.isSelected = true;
		this.repaint();
	}

	public boolean isSelected() {
		return poly.isSelected;
	}

	public void unSelect() {
		poly.isSelected = false;
		this.repaint();
	}

	public boolean isUnSelected() {
		return poly.isSelected;
	}
	
	public boolean isPolyComplete(){
		return poly.npoints >= 4;
	}
	
	public void addPointToPoly(int x, int y){
		if (!isPolyComplete()){
			poly.addPoint(x, y);
			this.repaint();
		} else {
			throw new RuntimeException("Adding points to a full poly");
		}
	}
	
	public void dragCorner(int x, int y){
		poly.drag(x, y);
		this.repaint();
	}
	
	public Polygon getPoly() {
		return poly.getPoly();
	}

	protected class Poly extends Polygon {
		protected boolean isSelected = false;
		private Color selectedColor = new Color(255, 0, 0, 128);
		private Color backgroundColor;
		private String name;

		private List<Rectangle> rects = new ArrayList<Rectangle>();

		public Poly(Color bgColor, String logoName, Polygon po) {
			this(bgColor, logoName);
			for (int i = 0; i < po.npoints; i++) {
				this.addPoint(po.xpoints[i], po.ypoints[i]);
			}
		}

		public Poly(Color bgColor, String logoName) {
			backgroundColor = bgColor;
			name = logoName;
		}
				
		protected Polygon getPoly(){
			Polygon po = new Polygon();
			for (int i = 0; i < 4; i++) {
				po.addPoint(this.xpoints[i], this.ypoints[i]);
			}
			return po;
		}

		@Override
		public Rectangle getBounds(){
			if (super.npoints >= 4){
				int rh = RECT_ANCHOR_WH;
				Rectangle ob = super.getBounds();
				return  new Rectangle(ob.x - rh/2, ob.y - rh/2, ob.width + rh/2, ob.height + rh/2);
			} else {
				return super.getBounds();
			}
		}
		
		@Override
		public void addPoint(int x, int y){
			int rh = RECT_ANCHOR_WH;
			super.addPoint(x, y);
			rects.add(new Rectangle(x - rh/2, y - rh/2, rh, rh));
		}

		@Override
		public boolean contains(Point p) {
			boolean cont = super.contains(p);
			for (int i = 0; i < rects.size(); i++) {
				Rectangle rect = rects.get(i);
				cont = cont || rect.contains(p);
			}
			return cont;
		}
		
		public void drag(int x, int y){
			int rh = RECT_ANCHOR_WH;
			for (int i = 0; i < rects.size(); i++) {
				Rectangle rect = rects.get(i);
				if (rect.contains(new Point(x, y))){
					//System.out.println("Dragged corner i: " + i + " by x: " + x + ", y: " + y);
					super.xpoints[i] = x;
					super.ypoints[i] = y;
					super.invalidate();
					rect.x = x - rh/2;
					rect.y = y - rh/2;
					break;
				}
			}
		}

		protected void paint(Graphics g) {
			if (this.npoints >= 4) {
				if (isSelected) {
					g.setColor(selectedColor);
				} else {
					g.setColor(Color.BLUE);
				}
				((Graphics2D) g).setStroke(new BasicStroke(2));
				g.drawPolygon(this);
				g.setColor(backgroundColor);
				g.fillPolygon(this);
				// Draw logo text
				Rectangle r = this.getBounds();
				Font f = new Font("Dialog", Font.BOLD, 12);
				g.setFont(f);
				g.setColor(Color.BLACK);
				g.drawString(name, r.x + RECT_ANCHOR_WH, r.y + r.height/2);
			}
			// draw rects for each point
			g.setColor(selectedColor);
			for (int i = 0; i < rects.size(); i++) {
				Rectangle rect = rects.get(i);
				g.drawRect(rect.x, rect.y, rect.width, rect.height);
			}
		}
	}
}
