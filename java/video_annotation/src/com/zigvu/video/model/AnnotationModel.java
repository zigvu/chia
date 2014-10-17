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
			File[] frameFiles = (new File(commandLine.framesFolder))
					.listFiles();

			// create empty annotations for frames that don't currently have
			// them
			for (int j = 0; j < frameFiles.length; j++) {
				File frameFile = frameFiles[j];
				if (frameFile.isFile() && frameFile.getName().endsWith(".png")) {
					boolean frameHasNoAnnotation = true;
					AnnotationReaderWriter annotationRW = newAnnotationRW(frameFile
							.getName());
					for (int i = 0; i < annoFiles.length; i++) {
						if (annoFiles[i].getName().equalsIgnoreCase(
								annotationRW.getAnnotationFileName())) {
							frameHasNoAnnotation = false;
							break;
						}
					}
					if (frameHasNoAnnotation) {
						Annotator.log(Annotator.logDebug,
								"AnnotationModel: Saving new annotation: "
										+ annotationRW.getAnnotationFileName());
						annotationRW.write(null);
					}
				}
			}
			// reread annotations
			annoFiles = (new File(commandLine.annotationsFolder)).listFiles();

			// sort and organize annotations
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
			Annotator.log(
					Annotator.logError,
					"AnnotationModel: Error reading image file: "
							+ imageFile.getPath());
			e.printStackTrace();
		}
	}

	// new annotation reader for video annotation
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

	// new annotation reader for image annotation
	public AnnotationReaderWriter newAnnotationRW(String frameFileName) {
		File frameFile = new File(commandLine.framesFolder, frameFileName);
		BufferedImage frame = null;
		try {
			frame = ImageIO.read(frameFile);
		} catch (IOException e) {
			Annotator.log(
					Annotator.logError,
					"AnnotationModel: Error reading image file: "
							+ frameFile.getPath());
			e.printStackTrace();
		}
		String annotationFileName = frameFile.getName().substring(0,
				frameFile.getName().lastIndexOf("."))
				+ ".json";

		AnnotationReaderWriter annotationRW = new AnnotationReaderWriter();
		annotationRW.setDimension(frame.getWidth(), frame.getHeight());
		annotationRW.setTime(0);
		annotationRW.setFileNames(annotationFileName, frameFileName);
		annotationRW.setFolderNames(commandLine.annotationsFolder,
				commandLine.framesFolder);
		return annotationRW;
	}
}
