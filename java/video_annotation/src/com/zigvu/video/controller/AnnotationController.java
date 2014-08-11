package com.zigvu.video.controller;

import java.awt.Color;
import java.awt.Polygon;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.util.List;

import javax.swing.*;
import javax.swing.event.*;

import com.zigvu.video.model.*;
import com.zigvu.video.view.*;

public class AnnotationController {
	private AnnotationModel model;
	private AnnotationView view;
	
	private boolean currentlyAnnotating;

	public AnnotationController(AnnotationModel m, AnnotationView v){
		model = m;
		view = v;
		
		// Populate logo list
		String[] strList = model.logoListR.getLogoLabels();
		for (int i = 0; i < strList.length; i++){
			view.logoList.addItem(strList[i]);
		}
		view.settingsPanel.disableComponent();
		view.logoList.disableComponent();
		currentlyAnnotating = false;
		
		// attach listeners
		view.logoList.addLogoListListener(new LogoListListener());
		view.settingsPanel.addSettingsListener(new SettingsListener());
		
		// set keyboard bindings
		InputMap inputMap = view.getInputMap(JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT);
		ActionMap actionMap = view.getActionMap();
		setKeyBoardBindings(inputMap, actionMap);
	}
	
	// pass logo selection info to view
	private void newLogoItemSelected(int logoIndex){
		//System.out.println("Setting logo index to: " + logoIndex);
		Color bgColor = view.logoList.getColor(logoIndex);
		String logoName = view.logoList.getName(logoIndex);
		view.videoLayeredPane.setNewLogo(bgColor, logoIndex, logoName);
	}
	
	// Event Listeners
	class LogoListListener implements ListSelectionListener {
		@Override
		public void valueChanged(ListSelectionEvent e) {
			if(!e.getValueIsAdjusting()){
				int selectedIndex = ((JList) e.getSource()).getSelectedIndex();
				if (selectedIndex != -1){
					newLogoItemSelected(selectedIndex);
				}
			}
		}
    }

	class SettingsListener implements ActionListener {
		@Override
		public void actionPerformed(ActionEvent e) {
			if (e.getSource() == view.settingsPanel.btnStartAnnotation){
				// if currently annotating, skip
				if (currentlyAnnotating){
					return;
				}
				// disable navigation buttons
				view.navigationPanel.disableComponent();
				// set captured frame as the visible layer
				BufferedImage bi = view.videoPlayer.getCurrentFrame();
				if (bi == null){
					view.navigationPanel.enableComponent();
					view.settingsPanel.disableComponent();
					currentlyAnnotating = false;
					return;
				}
				ImageIcon img = new ImageIcon(bi);
				view.videoLayeredPane.setCapturedFrame(img);
				
				view.logoList.enableComponent();
				view.videoLayeredPane.enableAllLayers();
				currentlyAnnotating = true;
			}
			if (e.getSource() == view.settingsPanel.btnClearOneAnnotation){
				view.videoLayeredPane.deleteSelectedLogo();
			}
			if (e.getSource() == view.settingsPanel.btnSaveAnnotation){
				// if not currently annotating, skip
				if (!currentlyAnnotating){
					return;
				}
				AnnotationReaderWriter annotationRW = model.newAnnotationRW(242323);
				for (int i = 0; i < model.logoListR.numOfLogos(); i++){
					List<Polygon> polygons = view.videoLayeredPane.getPolygons(i);
					for (Polygon poly : polygons){
						annotationRW.addAnnotation(view.logoList.getName(i), poly);						
					}
				}
				annotationRW.write();
				endAnnotation();
			}
			if (e.getSource() == view.settingsPanel.btnClearAllAnnotation){
				endAnnotation();
			}
		}
		
		private void endAnnotation(){
			// restore video as the visible layer
			view.videoLayeredPane.removeCapturedFrame();
			view.logoList.disableComponent();
			view.videoLayeredPane.resetAllLayers();
			// enable navigation buttons and disable settings buttons
			view.navigationPanel.enableComponent();
			view.settingsPanel.disableComponent();
			currentlyAnnotating = false;
		}
	}
	
	private void setKeyBoardBindings(InputMap inputMap, ActionMap actionMap){
		inputMap.put(KeyStroke.getKeyStroke('a'), "startAnnotation");
		actionMap.put("startAnnotation", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.settingsPanel.enableComponent();
		    	view.settingsPanel.btnStartAnnotation.doClick();
		    }
		});

		inputMap.put(KeyStroke.getKeyStroke('s'), "saveAnnotation");
		actionMap.put("saveAnnotation", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.settingsPanel.btnSaveAnnotation.doClick();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke(' '), "play");
		actionMap.put("play", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	if (!currentlyAnnotating){
		    		view.navigationPanel.togglePlay();
		    	}
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke('e'), "nextFrame");
		actionMap.put("nextFrame", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.nextFrame();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("shift LEFT"), "keyJumpExtraShortBack");
		actionMap.put("keyJumpExtraShortBack", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.previousFrame();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("shift RIGHT"), "keyJumpExtraShortForward");
		actionMap.put("keyJumpExtraShortForward", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.nextFrame();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("alt LEFT"), "keyJumpShortBack");
		actionMap.put("keyJumpShortBack", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.seekBackward();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("alt RIGHT"), "keyJumpShortForward");
		actionMap.put("keyJumpShortForward", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.seekForward();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("control LEFT"), "keyJumpMediumBack");
		actionMap.put("keyJumpMediumBack", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.fastSeekBackward();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke("control RIGHT"), "keyJumpMediumForward");
		actionMap.put("keyJumpMediumForward", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.fastSeekForward();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke('+'), "keyPlayFaster");
		actionMap.put("keyPlayFaster", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.playFasterRate();
		    }
		});
		
		inputMap.put(KeyStroke.getKeyStroke('-'), "keyPlaySlower");
		actionMap.put("keyPlaySlower", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.playSlowerRate();
		    }
		});

		inputMap.put(KeyStroke.getKeyStroke('='), "keyPlayNormal");
		actionMap.put("keyPlayNormal", new AbstractAction() {
		    @Override
		    public void actionPerformed(ActionEvent e) {
		    	view.navigationPanel.playNormalRate();
		    }
		});
	}
}

//int [] xpts = new int []{100,200,200,100};
//int [] ypts = new int []{100,200,200,100};
//Polygon po = new Polygon(xpts, ypts, xpts.length);
//ResizablePolygon rp = new ResizablePolygon(640, 360, Color.RED, 1, "New", po);
//view.videoLayeredPane.addResizablePoly(rp);
//videoLayeredPane.removeResizablePoly(rp);
