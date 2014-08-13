package com.zigvu.video.model;

import java.awt.Polygon;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Scanner;

import javax.imageio.ImageIO;

import org.json.*;

import com.zigvu.video.annotation.Annotator;

public class AnnotationReaderWriter {

	private String annotationFolder;
	private String frameFolder;
	private JSONObject json;

	public AnnotationReaderWriter(String filename) {
		Annotator.log(Annotator.logInfo,
				"AnnotationReaderWriter: Read from file: " + filename);
		try {
			String content = new Scanner(new File(filename))
					.useDelimiter("\\Z").next();
			json = new JSONObject(content);
		} catch (FileNotFoundException e) {
			System.out.println("Couldn't read file: " + filename);
			e.printStackTrace();
		}
	}

	public AnnotationReaderWriter() {
		Annotator.log(Annotator.logInfo,
				"AnnotationReaderWriter: Start new annotation");
		json = new JSONObject();
		json.put("annotations", new JSONObject());
	}

	public void setDimension(int width, int height) {
		json.put("width", width);
		json.put("height", height);
	}

	public void setTime(long timeIndex) {
		json.put("time", timeIndex);
	}

	public void setFileNames(String annotationFileName, String frameFileName) {
		json.put("annotation_filename", annotationFileName);
		json.put("frame_filename", frameFileName);
	}

	public String getFrameFileName() {
		return json.getString("frame_filename");
	}

	public String getAnnotationFileName() {
		return json.getString("annotation_filename");
	}

	public void setFolderNames(String annotationFolder, String frameFolder) {
		this.annotationFolder = annotationFolder;
		this.frameFolder = frameFolder;
	}

	public void clearAllLogoData() {
		json.remove("annotations");
		json.put("annotations", new JSONObject());
	}

	public ArrayList<Polygon> getAnnotation(String logoName) {
		ArrayList<Polygon> logoPolys = new ArrayList<Polygon>();
		try {
			JSONArray logoJSONArr = json.getJSONObject("annotations")
					.getJSONArray(logoName);
			for (int j = 0; j < logoJSONArr.length(); j++) {
				JSONObject polyJ = logoJSONArr.getJSONObject(j);
				int[] xpoints = new int[polyJ.length() / 2];
				int[] ypoints = new int[polyJ.length() / 2];
				for (int i = 0; i < polyJ.length() / 2; i++) {
					xpoints[i] = polyJ.getInt("x" + i);
					ypoints[i] = polyJ.getInt("y" + i);
				}
				logoPolys.add(new Polygon(xpoints, ypoints, xpoints.length));
			}
		} catch (JSONException j) {
			// do nothing
		} catch (Exception e) {
			e.printStackTrace();
		}
		return logoPolys;
	}

	public void addAnnotation(String logoName, Polygon poly) {
		// construct JSON object
		JSONObject polyJ = new JSONObject();
		for (int i = 0; i < poly.npoints; i++) {
			polyJ.put("x" + i, poly.xpoints[i]);
			polyJ.put("y" + i, poly.ypoints[i]);
		}
		// create new array for logo and add item or append to existing array
		try {
			json.getJSONObject("annotations").getJSONArray(logoName);
		} catch (Exception e) {
			json.getJSONObject("annotations").put(logoName, new JSONArray());
		}
		JSONArray logoJSONArr = json.getJSONObject("annotations").getJSONArray(
				logoName);
		logoJSONArr.put(logoJSONArr.length(), polyJ);
	}

	public boolean hasAnnotations() {
		return (json.getJSONObject("annotations").length() != 0);
	}

	public void write(BufferedImage bufferedImage) {
		File annotationFile = new File(annotationFolder,
				json.getString("annotation_filename"));
		File frameFile = new File(frameFolder, json.getString("frame_filename"));
		Annotator.log(Annotator.logInfo, json.toString());
		try {
			FileWriter aFileWriter = new FileWriter(annotationFile);
			aFileWriter.write(json.toString(2));
			aFileWriter.flush();
			aFileWriter.close();
		} catch (IOException e) {
			Annotator.log(Annotator.logError,
					"AnnotationReaderWriter: Couldn't save json to file: "
							+ annotationFile.getName());
			e.printStackTrace();
		}
		if (bufferedImage != null) {
			try {
				ImageIO.write(bufferedImage, "png", frameFile);
			} catch (IOException e) {
				Annotator.log(Annotator.logError,
						"AnnotationReaderWriter: Couldn't save frame to file: "
								+ frameFile.getName());
				e.printStackTrace();
			}
		}
	}
}
