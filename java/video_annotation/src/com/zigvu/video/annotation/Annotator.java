package com.zigvu.video.annotation;

import java.awt.*;

import javax.swing.*;

import com.zigvu.video.model.*;
import com.zigvu.video.view.*;
import com.zigvu.video.controller.*;

public class Annotator {
	private static ParseCommandLine commandLine;
	private AnnotationModel annotationModel;
	private AnnotationView annotationView;
	private AnnotationController annotationController;
	private final JFrame annotatorFrame;
	
	public static int logInfo = 0;
	public static int logDebug = 1;
	public static int logError = 2;
	public static int curLogLevel;

	/**
	 * Launch the application.
	 */
	public static void main(String[] args) {
		commandLine = new ParseCommandLine(args);
		if (!commandLine.parseSuccess) {
			commandLine.printHelp();
			return;
		}
		curLogLevel = commandLine.logLevel;
		EventQueue.invokeLater(new Runnable() {
			public void run() {
				try {
					Annotator.log(Annotator.logError, "Log Level: " + curLogLevel);
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
		Annotator.log(Annotator.logDebug, "Annotator: Setting up");
		String mrl = commandLine.mediaFileName;
		MediaInfo mediaInfo = new MediaInfo(mrl, commandLine.videoMode);

		annotationModel = new AnnotationModel(commandLine, mediaInfo);
		annotationView = new AnnotationView(mediaInfo.getWidth(),
				mediaInfo.getHeight(), commandLine.videoMode);
		annotationController = new AnnotationController(annotationModel, annotationView);

		annotatorFrame = new JFrame("Annotate Video");
		annotatorFrame.setContentPane(annotationView);
		annotatorFrame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		annotatorFrame.setSize(mediaInfo.getWidth(), mediaInfo.getHeight());
		annotatorFrame.setJMenuBar(annotationView.menuBar);
		annotatorFrame.setResizable(false);

		annotatorFrame.pack();
		annotatorFrame.setVisible(true);

		if (commandLine.videoMode){
			Annotator.log(Annotator.logDebug, "Annotator: Setting video mode");
			annotationView.videoPlayer.prepareMedia(mrl);
		} else {
			Annotator.log(Annotator.logDebug, "Annotator: Setting image mode");
		}
	}
	
	public static void log(int logLevel, String s){
		if (logLevel >= curLogLevel){
			System.out.println(s);
		}
	}
}
