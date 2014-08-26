package com.zigvu.video.view;

import java.awt.event.ActionListener;

import javax.swing.JMenu;
import javax.swing.JMenuBar;
import javax.swing.JMenuItem;

@SuppressWarnings("serial")
public class MenuBar extends JMenuBar {
	public JMenuItem mntmOpenVideo;
	
	public MenuBar() {
		JMenu mnFile = new JMenu("File");
		this.add(mnFile);
		
		mntmOpenVideo = new JMenuItem("Reload logo list (r)");
		mnFile.add(mntmOpenVideo);
	}
	
	public void addMenuBarListener(ActionListener al){
		mntmOpenVideo.addActionListener(al);
	}
}
