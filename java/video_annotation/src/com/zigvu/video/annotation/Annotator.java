package com.zigvu.video.annotation;

import java.awt.*;
import java.awt.event.ActionEvent;

import javax.swing.AbstractAction;
import javax.swing.ActionMap;
import javax.swing.ImageIcon;
import javax.swing.InputMap;
import javax.swing.JComponent;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;

import uk.co.caprica.vlcj.component.EmbeddedMediaPlayerComponent;
import uk.co.caprica.vlcj.player.MediaPlayerFactory;
import uk.co.caprica.vlcj.player.embedded.EmbeddedMediaPlayer;
import uk.co.caprica.vlcj.player.embedded.FullScreenStrategy;

import com.zigvu.video.model.*;
import com.zigvu.video.view.*;
import com.zigvu.video.controller.*;

public class Annotator {
	private AnnotationModel annotationModel;
	private AnnotationView annotationView;
	private AnnotationController annotationController;
	private final JFrame annotatorFrame;
	
	private int width = 640;
	private int height = 360;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					Annotator window = new Annotator();
				} catch (Exception e) {
					e.printStackTrace();
				}
			}
		});
	}

	/**
	 * Create the application.
	 */
	public Annotator() {
		annotationModel = new AnnotationModel();
		annotationView = new AnnotationView(width, height);
		annotationController = new AnnotationController(annotationModel, annotationView);
				
        annotatorFrame = new JFrame("Annotate Video");
        annotatorFrame.setContentPane(annotationView);
        annotatorFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        annotatorFrame.setSize(400, 300);
        annotatorFrame.setJMenuBar(annotationView.menuBar);
        annotatorFrame.setResizable(false);
		
        annotatorFrame.pack();
        annotatorFrame.setVisible(true);

        String mrl = "/home/evan/Vision/chia/java/video_annotation/resources/out.mp4";
        annotationView.videoPlayer.prepareMedia(mrl);
	}
}
