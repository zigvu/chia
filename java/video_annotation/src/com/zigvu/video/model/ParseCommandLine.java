package com.zigvu.video.model;

import java.io.File;

import org.apache.commons.cli.*;

import com.zigvu.video.annotation.Annotator;

public class ParseCommandLine {
	private Options options;
	private HelpFormatter formatter;
	private CommandLineParser parser;

	// allow main class to peer into state
	public boolean parseSuccess;
	public boolean videoMode;
	public String mediaFileName;
	public String annotationsFolder;
	public String framesFolder;
	public String logoListFile;
	public int logLevel;

	@SuppressWarnings("static-access")
	public ParseCommandLine(String[] args) {
		Annotator.log(Annotator.logInfo, "ParseCommandLine: Setting up");
		options = new Options();
		formatter = new HelpFormatter();
		parser = new GnuParser();
		parseSuccess = true;
		logLevel = Annotator.logDebug;

		options.addOption(OptionBuilder
				.hasArg()
				.withArgName("integer value")
				.withType(Number.class)
				.withDescription(
						"[0 = video annotation], [1 = image annotation]")
				.create("mode"));
		options.addOption(OptionBuilder.hasArg().withArgName("string value")
				.withType(String.class)
				.withDescription("If video mode, the video file path")
				.create("videoFileName"));
		options.addOption(OptionBuilder.hasArg().withArgName("string value")
				.withType(String.class)
				.withDescription("Folder to read/write annotation files")
				.create("annotationsFolder"));
		options.addOption(OptionBuilder.hasArg().withArgName("string value")
				.withType(String.class)
				.withDescription("Folder to read/write image files")
				.create("framesFolder"));
		options.addOption(OptionBuilder
				.hasArg()
				.withArgName("string value")
				.withType(String.class)
				.withDescription(
						"List of logos for annotations - separated in each line")
				.create("logoListFile"));
		options.addOption(OptionBuilder
				.hasArg()
				.withArgName("integer value")
				.withType(Number.class)
				.withDescription(
						"[Optional] Log Level: [0 = info], [1 = debug (default)], [2 = error]")
				.create("logLevel"));

		try {
			CommandLine line = parser.parse(options, args);
			// needs to have a mode
			if (line.hasOption("mode")) {
				if ((new Integer(line.getOptionValue("mode"))).intValue() == 0) {
					videoMode = true;
					if (line.hasOption("videoFileName")) {
						mediaFileName = line.getOptionValue("videoFileName");
						File file = new File(mediaFileName);
						if (!file.canRead()) {
							Annotator.log(Annotator.logError,
									"ParseCommandLine: Cannot read video file: "
											+ mediaFileName);
							parseSuccess = false;
						}
					} else {
						Annotator
								.log(Annotator.logError,
										"ParseCommandLine: Missing video filename in video mode");
						parseSuccess = false;
					}
				} else {
					videoMode = false;
				}
			} else {
				Annotator.log(Annotator.logError,
						"ParseCommandLine: Missing mode");
				parseSuccess = false;
			}
			// needs to have annotation folder
			if (line.hasOption("annotationsFolder")) {
				annotationsFolder = line.getOptionValue("annotationsFolder");
				createFolder(annotationsFolder);
			} else {
				Annotator.log(Annotator.logError,
						"ParseCommandLine: Missing annotations folder");
				parseSuccess = false;
			}
			// needs to have images folder
			if (line.hasOption("framesFolder")) {
				framesFolder = line.getOptionValue("framesFolder");
				if (videoMode) {
					createFolder(framesFolder);
				} else {
					// needs to have at least 1 PNG image
					File imageFolder = new File(framesFolder);
					File[] images = imageFolder.listFiles();
					mediaFileName = null;
					for (int i = 0; i < images.length; i++) {
						if (images[i].isFile()
								&& images[i].getName().endsWith(".png")) {
							mediaFileName = images[i].getPath();
							break;
						}
					}
					if (mediaFileName == null) {
						Annotator
								.log(Annotator.logError,
										"ParseCommandLine: Missing PNG file in images folder");
						parseSuccess = false;
					}
				}
			} else {
				Annotator.log(Annotator.logError,
						"ParseCommandLine: Missing images folder");
				parseSuccess = false;
			}
			// needs to have logo list
			if (line.hasOption("logoListFile")) {
				logoListFile = line.getOptionValue("logoListFile");
			} else {
				Annotator.log(Annotator.logError,
						"ParseCommandLine: Missing logo list file");
				parseSuccess = false;
			}
			// log level is optional
			if (line.hasOption("logLevel")) {
				int ll = (new Integer(line.getOptionValue("logLevel"))).intValue();
				if (ll >= 0 && ll <= Annotator.logError){
					logLevel = ll;
				}
			}
		} catch (ParseException e) {
			Annotator
					.log(Annotator.logError,
							"ParseCommandLine: Parsing of command line arguments failed");
			e.printStackTrace();
		}
	}

	public void printHelp() {
		formatter.printHelp("AnnotateVideo", options);
	}

	public String videoFilePrefix() {
		File file = new File(mediaFileName);
		return file.getName().split("\\.(?=[^\\.]+$)")[0];
	}

	public void createFolder(String folderName) {
		File file = new File(folderName);
		if (!file.exists()) {
			file.mkdir();
		} else {
			if (!file.isDirectory()) {
				Annotator
						.log(Annotator.logError,
								"ParseCommandLine: Cannot create folder: "
										+ folderName);
				parseSuccess = false;
			}
		}
	}
}
