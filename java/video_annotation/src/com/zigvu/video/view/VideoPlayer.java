package com.zigvu.video.view;

import java.awt.BorderLayout;
import java.awt.image.BufferedImage;

import javax.swing.JPanel;

import com.zigvu.video.annotation.Annotator;

import uk.co.caprica.vlcj.component.EmbeddedMediaPlayerComponent;
import uk.co.caprica.vlcj.player.embedded.EmbeddedMediaPlayer;

@SuppressWarnings("serial")
public class VideoPlayer extends JPanel {
	
	private EmbeddedMediaPlayerComponent mediaPlayerComponent;
	public EmbeddedMediaPlayer mediaPlayer;

	/**
	 * Create the panel.
	 */
	public VideoPlayer(int width, int height) {
		Annotator.log(Annotator.logInfo, "VideoPlayer: Setting up");
		this.setBounds(0, 0, width, height);
		this.setOpaque(true);
		this.setLayout(new BorderLayout());
		
		mediaPlayerComponent = new EmbeddedMediaPlayerComponent();
		this.add(mediaPlayerComponent, BorderLayout.CENTER);
		mediaPlayer = mediaPlayerComponent.getMediaPlayer();
		
		//mediaPlayer.setFullScreen(true);
        //mediaPlayer.setEnableMouseInputHandling(false);
	}
		
	public void prepareMedia(String mrl){
		Annotator.log(Annotator.logDebug, "VideoPlayer: play file: " + mrl);
		mediaPlayer.prepareMedia(mrl);
	}
	
	public void pause(){
		if (mediaPlayer.isPlaying()){
			mediaPlayer.pause();
		}
	}
	
	public BufferedImage getCurrentFrame(){
        if (mediaPlayer.isPlayable()){
			pause();
			return mediaPlayer.getSnapshot();
        }
        return null;
	}

	public long getTime(){
        if (mediaPlayer.isPlayable()){
			pause();
			return mediaPlayer.getTime();
        }
        return -1;
	}
}
