package com.zigvu.video.model;

public class LogoListReader {
	String[] logoList;
	private String filename;
	
	public LogoListReader(String fn){
		filename = fn;
		logoList = new String[] {"LogoA", "LogoB", "LogoC", "LogoD", "LogoE", "LogoF", "LogoG", "Logo Long Long List of Logos H", "LogoI", "LogoJ", "LogoK", "LogoL"};
	}
	
	public String[] getLogoLabels(){
		return logoList;
	}
	
	public int numOfLogos(){
		return logoList.length;
	}
}
