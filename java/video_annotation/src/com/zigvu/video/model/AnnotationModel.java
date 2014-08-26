package com.zigvu.video.model;

import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;

import javax.imageio.ImageIO;

import com.zigvu.video.annotation.Annotator;

public class AnnotationModel {
	public LogoListReader logoListR;
	public boolean videoMode;

	private ParseCommandLine commandLine;
	private MediaInfo mediaInfo;

	// manage re-annotation
	private ArrayList<String> annotationFiles;
	private int annotationCounter;
	private AnnotationReaderWriter currentAnnotation;
	private BufferedImage currentFrame;

	public AnnotationModel(ParseCommandLine commandLine, MediaInfo mediaInfo) {
		Annotator.log(Annotator.logInfo, "AnnotationModel: Setting up");
		this.commandLine = commandLine;
		this.mediaInfo = mediaInfo;
		videoMode = commandLine.videoMode;
		logoListR = new LogoListReader(this.commandLine.logoListFile);
		if (!videoMode) {
			annotationFiles = new ArrayList<String>();
			File[] annoFiles = (new File(commandLine.annotationsFolder))
					.listFiles();
			String[] annoFilesStr = new String[annoFiles.length];
			for (int i = 0; i < annoFiles.length; i++) {
				annoFilesStr[i] = annoFiles[i].getAbsolutePath();
			}
			Arrays.sort(annoFilesStr);
			for (int i = 0; i < annoFilesStr.length; i++) {
				File annoFile = new File(annoFilesStr[i]);
				if (annoFile.isFile() && annoFile.getName().endsWith(".json")) {
					annotationFiles.add(annoFile.getPath());
				}
			}
			Annotator.log(Annotator.logInfo,
					"AnnotationModel: Num of annotation files read: "
							+ annotationFiles.size());
			setCurrentAnno(0);
		}
	}

	public AnnotationReaderWriter getAnnotation() {
		return currentAnnotation;
	}

	public BufferedImage getFrame() {
		return currentFrame;
	}

	public void firstFrame() {
		setCurrentAnno(0);
	}

	public void nextFrame() {
		if ((annotationCounter + 1) < annotationFiles.size()) {
			setCurrentAnno(annotationCounter + 1);
		}
	}

	public void previousFrame() {
		if (annotationCounter > 0) {
			setCurrentAnno(annotationCounter - 1);
		}
	}

	public void lastFrame() {
		setCurrentAnno(annotationFiles.size() - 1);
	}

	private void setCurrentAnno(int idx) {
		annotationCounter = idx;
		currentAnnotation = new AnnotationReaderWriter(annotationFiles.get(idx));
		currentAnnotation.setFolderNames(commandLine.annotationsFolder,
				commandLine.framesFolder);
		File imageFile = new File(commandLine.framesFolder,
				currentAnnotation.getFrameFileName());
		try {
			currentFrame = ImageIO.read(imageFile);
		} catch (IOException e) {
			Annotator.log(Annotator.logError,
					"AnnotationModel: Error reading image file: "
					+ imageFile.getPath());
			e.printStackTrace();
		}
	}

	public AnnotationReaderWriter newAnnotationRW(long timeIndex) {
		String annotationFileName = commandLine.videoFilePrefix() + "_"
				+ timeIndex + ".json";
		String frameFileName = commandLine.videoFilePrefix() + "_" + timeIndex
				+ ".png";
		AnnotationReaderWriter annotationRW = new AnnotationReaderWriter();
		annotationRW.setDimension(mediaInfo.getWidth(), mediaInfo.getHeight());
		annotationRW.setTime(timeIndex);
		annotationRW.setFileNames(annotationFileName, frameFileName);
		annotationRW.setFolderNames(commandLine.annotationsFolder,
				commandLine.framesFolder);
		return annotationRW;
	}
}
