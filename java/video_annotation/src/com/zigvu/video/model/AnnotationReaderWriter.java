package com.zigvu.video.model;

import java.awt.Polygon;

import org.json.*;

public class AnnotationReaderWriter {

	private String filename;
	JSONObject json;
	
	public AnnotationReaderWriter(String fn){
		this();
		filename = fn;
	}
	
	public AnnotationReaderWriter(){
		json = new JSONObject();
		json.put("annotations", new JSONObject());
	}
	
	public void addAnnotation(String logoName, Polygon poly){
		// construct JSON object
		JSONObject polyJ = new JSONObject();
		for (int i = 0; i < poly.npoints; i++) {
			polyJ.put("x" + i, poly.xpoints[i]);
			polyJ.put("y" + i, poly.ypoints[i]);
		}
		// now create new array for logo and add item or append to existing array
		try {
			json.getJSONObject("annotations").getJSONArray(logoName);
		} catch (Exception e){
			json.getJSONObject("annotations").put(logoName, new JSONArray());
		}
		JSONArray logoJSONArr = json.getJSONObject("annotations").getJSONArray(logoName);
		logoJSONArr.put(logoJSONArr.length(), polyJ);			
	}
	
	public void write(){
		System.out.println(json.toString());
	}
}
