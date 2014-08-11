package com.zigvu.video.view;

import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.ImageIcon;
import javax.swing.JButton;
import javax.swing.JPanel;

@SuppressWarnings("serial")
public class SettingsPanel extends JPanel {

	public JButton btnStartAnnotation;
	public JButton btnClearAllAnnotation;
	public JButton btnSaveAnnotation;
	public JButton btnClearOneAnnotation;
	
	/**
	 * Create the panel.
	 */
	public SettingsPanel() {
		this.setLayout(new GridLayout(0, 2, 0, 0));
		
		btnStartAnnotation = new JButton("");
		btnStartAnnotation.setToolTipText("Annotate Frame");
		btnStartAnnotation.setIcon(new ImageIcon(SettingsPanel.class.getResource("/resources/glyphicons_030_pencil.png")));
		this.add(btnStartAnnotation);
		
		btnClearOneAnnotation = new JButton("");
		btnClearOneAnnotation.setToolTipText("Delete Selected Frame Annotation");
		btnClearOneAnnotation.setIcon(new ImageIcon(SettingsPanel.class.getResource("/resources/glyphicons_192_circle_remove.png")));
		this.add(btnClearOneAnnotation);
		
		btnSaveAnnotation = new JButton("");
		btnSaveAnnotation.setToolTipText("Save Annotation");
		btnSaveAnnotation.setIcon(new ImageIcon(SettingsPanel.class.getResource("/resources/glyphicons_443_floppy_disk.png")));
		this.add(btnSaveAnnotation);
		
		btnClearAllAnnotation = new JButton("");
		btnClearAllAnnotation.setToolTipText("Delete All Frame Annotations");
		btnClearAllAnnotation.setIcon(new ImageIcon(SettingsPanel.class.getResource("/resources/glyphicons_016_bin.png")));
		this.add(btnClearAllAnnotation);
	}

	public void enableComponent(){
		AnnotationView.enableComponents(this, true);
	}
	
	public void disableComponent(){
		AnnotationView.enableComponents(this, false);
	}	
	
	public void addSettingsListener(ActionListener sl){
		btnStartAnnotation.addActionListener(sl);
		btnClearOneAnnotation.addActionListener(sl);
		btnSaveAnnotation.addActionListener(sl);
		btnClearAllAnnotation.addActionListener(sl);
	}
}
