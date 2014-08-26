package com.zigvu.video.controller;

import java.awt.Color;
import java.awt.Polygon;
import java.awt.event.*;
import java.awt.image.BufferedImage;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import javax.swing.*;
import javax.swing.event.*;

import com.zigvu.video.annotation.Annotator;
import com.zigvu.video.model.*;
import com.zigvu.video.view.*;

public class AnnotationController {
	private AnnotationModel model;
	private AnnotationView view;

	private boolean videoMode;
	private boolean currentlyAnnotating;

	public AnnotationController(AnnotationModel m, AnnotationView v) {
		Annotator.log(Annotator.logInfo, "AnnotationController: Setting up");
		model = m;
		view = v;
		videoMode = model.videoMode;

		// Populate logo list
		resetLogoList();
		view.settingsPanel.disableComponent();
		view.logoList.disableComponent();
		currentlyAnnotating = false;

		// attach listeners
		view.logoList.addLogoListListener(new LogoListListener());
		view.settingsPanel.addSettingsListener(new SettingsListener());
		view.menuBar.addMenuBarListener(new MenuBarListener());

		// set keyboard bindings
		InputMap inputMap = view
				.getInputMap(JComponent.WHEN_ANCESTOR_OF_FOCUSED_COMPONENT);
		ActionMap actionMap = view.getActionMap();
		setKeyBoardBindings(inputMap, actionMap);

		// if not videoMode, show first frame
		if (!videoMode) {
			view.navigationPanel
					.addNavigationListener(new NavigationListener());
			setFrame();
		}
	}
	
	private void resetLogoList(){
		view.logoList.removeAllItems();
		try {
			Annotator.log(Annotator.logInfo, "AnnotationController: Load logo list");
			model.logoListR.reloadLogoListFromFile();
		} catch (IOException e) {
			System.out.println("Error reading logo list from file");
			e.printStackTrace();
		}
		ArrayList<String> logoLabels = model.logoListR.getLogoLabels();
		for (String logoLabel : logoLabels) {
			view.logoList.addItem(logoLabel);
		}
	}

	private void setFrame() {
		if (videoMode) {
			return;
		}
		view.videoLayeredPane.removeCurrentFrame();
		view.videoLayeredPane.resetAllLayers();
		ImageIcon img = new ImageIcon(model.getFrame());
		view.videoLayeredPane.setCurrentFrame(img);
		AnnotationReaderWriter annotationRW = model.getAnnotation();
		ArrayList<String> logoLabels = model.logoListR.getLogoLabels();
		for (String logoName : logoLabels) {
			ArrayList<Polygon> logoPolys = annotationRW.getAnnotation(logoName);
			if (logoPolys.size() > 0) {
				int selectedIndex = view.logoList.getIndex(logoName);
				Color bgColor = view.logoList.getColor(selectedIndex);
				view.videoLayeredPane.setNewLogo(bgColor, selectedIndex,
						logoName);
				for (Polygon po : logoPolys) {
					view.videoLayeredPane.addPolyFromAnnotation(po);
				}
			}
		}
		view.navigationPanel.longLabel.setText("File: "
				+ annotationRW.getAnnotationFileName());
		Annotator.log(Annotator.logDebug, "AnnotationController: Read file: "
				+ annotationRW.getAnnotationFileName());
	}

	// Event Listeners
	class LogoListListener implements ListSelectionListener {
		@Override
		public void valueChanged(ListSelectionEvent e) {
			if (!e.getValueIsAdjusting()) {
				int selectedIndex = ((JList) e.getSource()).getSelectedIndex();
				if (selectedIndex != -1) {
					Annotator.log(Annotator.logInfo, "AnnotationController: Setting logo index to: "
							+ selectedIndex);
					Color bgColor = view.logoList.getColor(selectedIndex);
					String logoName = view.logoList.getName(selectedIndex);
					view.videoLayeredPane.setNewLogo(bgColor, selectedIndex,
							logoName);
				}
			}
		}
	}

	class NavigationListener implements MouseListener {
		@Override
		public void mouseClicked(MouseEvent e) {
			if (e.getSource() == view.navigationPanel.fastSeekBackward) {
				model.firstFrame();
				setFrame();
			}
			if (e.getSource() == view.navigationPanel.rewindFrame) {
				model.previousFrame();
				setFrame();
			}
			if (e.getSource() == view.navigationPanel.forwardFrame) {
				model.nextFrame();
				setFrame();
			}
			if (e.getSource() == view.navigationPanel.fastSeekForward) {
				model.lastFrame();
				setFrame();
			}
		}

		@Override
		public void mouseEntered(MouseEvent e) { }

		@Override
		public void mouseExited(MouseEvent e) { }

		@Override
		public void mousePressed(MouseEvent e) { }

		@Override
		public void mouseReleased(MouseEvent e) { }
	}

	class SettingsListener implements ActionListener {
		@Override
		public void actionPerformed(ActionEvent e) {
			if (e.getSource() == view.settingsPanel.btnStartAnnotation) {
				// if currently annotating, skip
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					// set captured frame as the visible layer
					BufferedImage bi = view.videoPlayer.getCurrentFrame();
					if (bi == null) {
						view.settingsPanel.disableComponent();
						currentlyAnnotating = false;
						return;
					}
					ImageIcon img = new ImageIcon(bi);
					view.videoLayeredPane.setCurrentFrame(img);
					view.videoLayeredPane.resetAllLayers();
				}

				// disable navigation buttons
				view.navigationPanel.disableComponent();
				view.logoList.enableComponent();
				view.videoLayeredPane.enableAllLayers();
				currentlyAnnotating = true;
				Annotator.log(Annotator.logDebug, "AnnotationController: Draw new annotation");
			}
			if (e.getSource() == view.settingsPanel.btnClearOneAnnotation) {
				view.videoLayeredPane.deleteSelectedLogo();
				Annotator.log(Annotator.logDebug, "AnnotationController: Delete selected logo");
			}
			if (e.getSource() == view.settingsPanel.btnSaveAnnotation) {
				// if not currently annotating, skip
				if (!currentlyAnnotating) {
					return;
				}
				BufferedImage bi = null;
				AnnotationReaderWriter annotationRW;
				if (videoMode) {
					bi = view.videoPlayer.getCurrentFrame();
					long currentTime = view.videoPlayer.getTime();
					if (bi == null || currentTime == -1) {
						throw new RuntimeException(
								"Error in saving current frame");
					}
					annotationRW = model.newAnnotationRW(currentTime);
				} else {
					annotationRW = model.getAnnotation();
				}
				// populate annotations file
				annotationRW.clearAllLogoData();
				for (int i = 0; i < model.logoListR.numOfLogos(); i++) {
					List<Polygon> polygons = view.videoLayeredPane
							.getPolygons(i);
					for (Polygon poly : polygons) {
						annotationRW.addAnnotation(view.logoList.getName(i),
								poly);
					}
				}
				// if in video mode, write only if not empty annotation
				if (videoMode) {
					if (annotationRW.hasAnnotations()) {
						annotationRW.write(bi);
					}
				} else {
					annotationRW.write(bi);
				}
				endAnnotation();
				Annotator.log(Annotator.logDebug, "AnnotationController: Save changes");
			}
			if (e.getSource() == view.settingsPanel.btnClearAllAnnotation) {
				endAnnotation();
				Annotator.log(Annotator.logDebug, "AnnotationController: Discard changes");
			}
		}

		private void endAnnotation() {
			// restore video as the visible layer
			view.videoLayeredPane.removeCurrentFrame();
			view.logoList.disableComponent();
			view.videoLayeredPane.resetAllLayers();
			// enable navigation buttons and disable settings buttons
			view.navigationPanel.enableComponent();
			view.settingsPanel.disableComponent();
			setFrame();
			currentlyAnnotating = false;
		}
	}
	
	class MenuBarListener implements ActionListener {
		@Override
		public void actionPerformed(ActionEvent e) {
			if (e.getSource() == view.menuBar.mntmOpenVideo) {
				if (currentlyAnnotating) {
					return;
				}
				resetLogoList();
			}
		}
	}

	@SuppressWarnings("serial")
	private void setKeyBoardBindings(InputMap inputMap, ActionMap actionMap) {
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
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.togglePlay();
				} else {
					model.nextFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke('e'), "nextFrame");
		actionMap.put("nextFrame", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.nextFrame();
				} else {
					model.nextFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("shift LEFT"),
				"keyJumpExtraShortBack");
		inputMap.put(KeyStroke.getKeyStroke("LEFT"), "keyJumpExtraShortBack");
		actionMap.put("keyJumpExtraShortBack", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.seekShortBackward();
				} else {
					model.previousFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("shift RIGHT"),
				"keyJumpExtraShortForward");
		inputMap.put(KeyStroke.getKeyStroke("RIGHT"),
				"keyJumpExtraShortForward");
		actionMap.put("keyJumpExtraShortForward", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.seekShortForward();
				} else {
					model.nextFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("alt LEFT"), "keyJumpShortBack");
		actionMap.put("keyJumpShortBack", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.seekBackward();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("alt RIGHT"), "keyJumpShortForward");
		actionMap.put("keyJumpShortForward", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.seekForward();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("control LEFT"),
				"keyJumpMediumBack");
		actionMap.put("keyJumpMediumBack", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.fastSeekBackward();
				} else {
					model.firstFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke("control RIGHT"),
				"keyJumpMediumForward");
		actionMap.put("keyJumpMediumForward", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.fastSeekForward();
				} else {
					model.lastFrame();
					setFrame();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke('+'), "keyPlayFaster");
		actionMap.put("keyPlayFaster", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.playFasterRate();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke('-'), "keyPlaySlower");
		actionMap.put("keyPlaySlower", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.playSlowerRate();
				}
			}
		});

		inputMap.put(KeyStroke.getKeyStroke('='), "keyPlayNormal");
		actionMap.put("keyPlayNormal", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				if (videoMode) {
					view.navigationPanel.playNormalRate();
				}
			}
		});
		
		inputMap.put(KeyStroke.getKeyStroke("BACK_SPACE"), "keyDeleteAnnotation");
		inputMap.put(KeyStroke.getKeyStroke("DELETE"), "keyDeleteAnnotation");
		actionMap.put("keyDeleteAnnotation", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (!currentlyAnnotating) {
					return;
				}
				view.settingsPanel.btnClearOneAnnotation.doClick();
			}
		});
		
		inputMap.put(KeyStroke.getKeyStroke('r'), "keyReloadLogoList");
		actionMap.put("keyReloadLogoList", new AbstractAction() {
			@Override
			public void actionPerformed(ActionEvent e) {
				if (currentlyAnnotating) {
					return;
				}
				resetLogoList();
			}
		});
	}
}
