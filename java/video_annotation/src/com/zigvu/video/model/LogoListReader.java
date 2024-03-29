package com.zigvu.video.model;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

import com.zigvu.video.annotation.Annotator;

public class LogoListReader {
	String filename;
	ArrayList<String> logoList;

	public LogoListReader(String filename) {
		Annotator.log(Annotator.logInfo, "LogoListReader: Read from file: "
				+ filename);
		this.filename = filename;
	}
	
	public void reloadLogoListFromFile() throws IOException {
		logoList = new ArrayList<String>();
		BufferedReader br = new BufferedReader(new FileReader(filename));
		String line = br.readLine();
		while (line != null) {
			if (!(line.equals("") || line.equals(" "))){
				logoList.add(line);
			}
			line = br.readLine();
		}
		br.close();
		Annotator.log(Annotator.logInfo,
				"LogoListReader: Read num logos total: " + numOfLogos());
	}

	public ArrayList<String> getLogoLabels() {
		return logoList;
	}

	public int numOfLogos() {
		return logoList.size();
	}
}
