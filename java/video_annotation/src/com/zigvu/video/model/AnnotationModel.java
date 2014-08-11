package com.zigvu.video.model;

import java.awt.Polygon;

public class AnnotationModel {
	public LogoListReader logoListR;

	public AnnotationModel(){
		logoListR = new LogoListReader("NotSpecifiedFileYet");
	}
	
	public AnnotationReaderWriter newAnnotationRW(int timeIndex){
		AnnotationReaderWriter annotationRW = new AnnotationReaderWriter();
		return annotationRW;
	}
}
