package com.zigvu.video.view;

import javax.swing.*;

import java.awt.*;

import javax.swing.border.*;

import com.zigvu.video.annotation.Annotator;


@SuppressWarnings("serial")
public class AnnotationView extends JPanel {
	
	public JMenuBar menuBar;
	public VideoLayeredPane videoLayeredPane;
	public VideoPlayer videoPlayer;
	public LogoList logoList;
	public NavigationPanel navigationPanel;
	public SettingsPanel settingsPanel;
	
	private int logoListWidth = 150;
	
	public AnnotationView(int width, int height, boolean videoMode) {
		Annotator.log(Annotator.logInfo, "AnnotationView: Setting up");
		this.setLayout(new BorderLayout(0, 0));

		// Set Menu
		menuBar = new JMenuBar();
		JMenu mnFile = new JMenu("File");
		menuBar.add(mnFile);
		
		JMenuItem mntmOpenVideo = new JMenuItem("Open Video");
		mnFile.add(mntmOpenVideo);		
		JMenuItem mntmSaveAll = new JMenuItem("Save All");
		mnFile.add(mntmSaveAll);
		
		// Top panel has video/drawing panes and logo list
		JPanel topPanel = new JPanel(new BorderLayout(0, 0));
		topPanel.setBorder(new BevelBorder(BevelBorder.LOWERED, Color.GRAY, Color.DARK_GRAY, Color.LIGHT_GRAY, Color.WHITE));
		this.add(topPanel, BorderLayout.NORTH);
	      
		// Panel to hold JLayeredPane
		JPanel topPanelLayerContainer = new JPanel();
		topPanelLayerContainer.setBorder(new CompoundBorder(new EmptyBorder(5, 5, 5, 5), new MatteBorder(1, 1, 1, 1, (Color) new Color(128, 128, 128))));
		topPanel.add(topPanelLayerContainer, BorderLayout.CENTER);
				
		videoLayeredPane = new VideoLayeredPane(width,height);
		topPanelLayerContainer.add(videoLayeredPane);

		if (videoMode){
			videoPlayer = new VideoPlayer(width,height);
			videoLayeredPane.setVideoPlayer(videoPlayer);
		}
		
		// Panel to hold LogoList
		JPanel topPanelScrollContainer = new JPanel();
		topPanelScrollContainer.setBorder(new CompoundBorder(new EmptyBorder(5, 5, 5, 5), new MatteBorder(1, 1, 1, 1, (Color) new Color(128, 128, 128))));
		topPanel.add(topPanelScrollContainer, BorderLayout.EAST);
		
		logoList = new LogoList(logoListWidth, height);
		topPanelScrollContainer.add(logoList);
		
		// Bottom panel has video controls and settings
		JPanel bottomPanel = new JPanel(new BorderLayout(0, 0));
		bottomPanel.setBorder(new BevelBorder(BevelBorder.LOWERED, Color.GRAY, Color.DARK_GRAY, Color.LIGHT_GRAY, Color.WHITE));
		this.add(bottomPanel, BorderLayout.SOUTH);
		
		navigationPanel = new NavigationPanel(videoPlayer, videoMode);
		navigationPanel.setBorder(new CompoundBorder(new EmptyBorder(5, 5, 5, 5), new MatteBorder(1, 1, 1, 1, (Color) new Color(128, 128, 128))));
		bottomPanel.add(navigationPanel, BorderLayout.CENTER);
		
		settingsPanel = new SettingsPanel();
		settingsPanel.setBorder(new CompoundBorder(new EmptyBorder(5, 5, 5, 5), new MatteBorder(1, 1, 1, 1, (Color) new Color(128, 128, 128))));
		bottomPanel.add(settingsPanel, BorderLayout.EAST);
	}
	
	static public void enableComponents(Container container, boolean enable) {
        Component[] components = container.getComponents();
        for (Component component : components) {
            component.setEnabled(enable);
            if (component instanceof Container) {
                enableComponents((Container)component, enable);
            }
        }
    }
}
