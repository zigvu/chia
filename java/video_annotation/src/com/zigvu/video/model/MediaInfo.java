package com.zigvu.video.model;

import java.awt.image.BufferedImage;
import java.io.*;

import javax.imageio.ImageIO;

import com.zigvu.video.annotation.Annotator;

public class MediaInfo {
	private int width = 0;
	private int height = 0;

	public MediaInfo(String filename, boolean videoMode) {
		Annotator.log(Annotator.logInfo, "MediaInfo: Setting up");
		if (videoMode) {
			getVideoInfo(filename);
		} else {
			getImageInfo(filename);
		}
	}

	private void getImageInfo(String filename) {
		try {
			BufferedImage bimg = ImageIO.read(new File(filename));
			width = bimg.getWidth();
			height = bimg.getHeight();
		} catch (IOException e) {
			Annotator.log(Annotator.logError,
					"MediaInfo: Couldn't read image file " + filename);
			e.printStackTrace();
		}
	}

	private void getVideoInfo(String filename) {
		// Use ffprobe to get video dimension
		try {
			Process proc = Runtime.getRuntime()
					.exec("ffprobe -show_streams -pretty -loglevel quiet "
							+ filename);
			BufferedReader read = new BufferedReader(new InputStreamReader(
					proc.getInputStream()));
			try {
				proc.waitFor();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
			while (read.ready()) {
				String line = read.readLine();
				if (line.contains("width")) {
					width = (new Integer(line.split("=")[1])).intValue();
				}
				if (line.contains("height")) {
					height = (new Integer(line.split("=")[1])).intValue();
				}
			}
		} catch (IOException e) {
			Annotator.log(Annotator.logError,
					"MediaInfo: Couldn't read ffprobe data: " + filename);
			e.printStackTrace();
		}
		// if ffprobe didn't work, throw execption
		if (width == 0 || height == 0) {
			throw new RuntimeException("FFProbe couldn't get video dimension");
		}
	}

	public int getWidth() {
		return width;
	}

	public int getHeight() {
		return height;
	}
}
