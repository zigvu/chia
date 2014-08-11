package com.zigvu.video.view;

import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.KeyEventDispatcher;
import java.awt.KeyboardFocusManager;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.KeyEvent;
import java.awt.event.KeyListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

import javax.swing.AbstractAction;
import javax.swing.ActionMap;
import javax.swing.ImageIcon;
import javax.swing.InputMap;
import javax.swing.JButton;
import javax.swing.JComponent;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JSlider;
import javax.swing.KeyStroke;
import javax.swing.SwingUtilities;

import uk.co.caprica.vlcj.player.MediaPlayer;
import uk.co.caprica.vlcj.player.embedded.EmbeddedMediaPlayer;

@SuppressWarnings("serial")
public class NavigationPanel extends JPanel {
	
	public JSlider slider;
	public JLabel timeLabel;
	public JButton fastSeekBackward;
	public JButton seekBackward;
	public JButton rewindFrame;
	public JButton playFrame;
	public JButton pauseFrame;
	public JButton forwardFrame;
	public JButton seekForward;
	public JButton fastSeekForward;

	// media helper variables
	private static final int SKIP_TIME_MS_NORMAL = 10 * 1000;
	private static final int SKIP_TIME_MS_FAST = 5 * SKIP_TIME_MS_NORMAL;
	private static final int SKIP_TIME_MS_ONE_FRAME = 100;
	private static final float RATE_MAX_MULTIPLE = (float)5.0;
	private static final float RATE_MIN_MULTIPLE = (float)0.01;
	private static final float RATE_NORMAL_MULTIPLE = (float)1.0;
	private float playRate = (float)1.0;
    private final ScheduledExecutorService executorService = Executors.newSingleThreadScheduledExecutor();
    private final EmbeddedMediaPlayer mediaPlayer;
    private boolean mousePressedPlaying = false;

	public NavigationPanel(VideoPlayer vpl) {
		this.mediaPlayer = vpl.mediaPlayer;

		// create UI and execute on thread
		createUI();
		registerListeners();
		executorService.scheduleAtFixedRate(new UpdateRunnable(mediaPlayer), 0L, 1L, TimeUnit.SECONDS);
	}
	
	public void enableComponent(){
		AnnotationView.enableComponents(this, true);
	}
	
	public void disableComponent(){
		AnnotationView.enableComponents(this, false);
	}
	
	public void createUI(){
		
		GridBagLayout gbl_navigationPanel = new GridBagLayout();
		gbl_navigationPanel.columnWidths = new int[]{25, 0, 0, 0, 0, 0, 0, 0, 0};
		gbl_navigationPanel.rowHeights = new int[]{18, 0, 0};
		gbl_navigationPanel.columnWeights = new double[]{0.0, 0.0, 0.0, Double.MIN_VALUE, 0.0, 0.0, 0.0, 0.0, 0.0};
		gbl_navigationPanel.rowWeights = new double[]{0.0, 0.0, Double.MIN_VALUE};
		this.setLayout(gbl_navigationPanel);
		
		slider = new JSlider();
		slider.setMinimum(0);
		slider.setMaximum(1000);
		slider.setValue(0);
		slider.setToolTipText("Position");
		GridBagConstraints gbc_slider = new GridBagConstraints();
		gbc_slider.fill = GridBagConstraints.HORIZONTAL;
		gbc_slider.insets = new Insets(0, 0, 5, 5);
		gbc_slider.gridx = 0;
		gbc_slider.gridy = 0;
		gbc_slider.gridwidth = 7;
		this.add(slider, gbc_slider);
		
		timeLabel = new JLabel("hh:mm:ss");
		GridBagConstraints gbc_lblMs = new GridBagConstraints();
		gbc_lblMs.insets = new Insets(0, 0, 5, 0);
		gbc_lblMs.gridx = 7;
		gbc_lblMs.gridy = 0;
		this.add(timeLabel, gbc_lblMs);
		
		fastSeekBackward = new JButton("");
		fastSeekBackward.setToolTipText("Fast Seek Backward");
		fastSeekBackward.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_171_fast_backward.png")));
		GridBagConstraints gbc_fastSeekBackward = new GridBagConstraints();
		gbc_fastSeekBackward.weightx = 0.5;
		gbc_fastSeekBackward.insets = new Insets(0, 0, 0, 5);
		gbc_fastSeekBackward.gridx = 0;
		gbc_fastSeekBackward.gridy = 1;
		this.add(fastSeekBackward, gbc_fastSeekBackward);
		
		seekBackward = new JButton("");
		seekBackward.setToolTipText("Seek Backward");
		seekBackward.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_170_step_backward.png")));
		GridBagConstraints gbc_seekBackward = new GridBagConstraints();
		gbc_seekBackward.weightx = 0.5;
		gbc_seekBackward.insets = new Insets(0, 0, 0, 5);
		gbc_seekBackward.gridx = 1;
		gbc_seekBackward.gridy = 1;
		this.add(seekBackward, gbc_seekBackward);
		
		rewindFrame = new JButton("");
		rewindFrame.setToolTipText("Rewind One Frame");
		rewindFrame.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_172_rewind.png")));
		GridBagConstraints gbc_rewindFrame = new GridBagConstraints();
		gbc_rewindFrame.weightx = 0.5;
		gbc_rewindFrame.insets = new Insets(0, 0, 0, 5);
		gbc_rewindFrame.gridx = 2;
		gbc_rewindFrame.gridy = 1;
		this.add(rewindFrame, gbc_rewindFrame);
		
		playFrame = new JButton("");
		playFrame.setToolTipText("Play");
		playFrame.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_173_play.png")));
		GridBagConstraints gbc_playFrame = new GridBagConstraints();
		gbc_playFrame.weightx = 0.5;
		gbc_playFrame.insets = new Insets(0, 0, 0, 5);
		gbc_playFrame.gridx = 3;
		gbc_playFrame.gridy = 1;
		this.add(playFrame, gbc_playFrame);
		
		pauseFrame = new JButton("");
		pauseFrame.setToolTipText("Pause");
		pauseFrame.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_174_pause.png")));
		GridBagConstraints gbc_pauseFrame = new GridBagConstraints();
		gbc_pauseFrame.weightx = 0.5;
		gbc_pauseFrame.insets = new Insets(0, 0, 0, 5);
		gbc_pauseFrame.gridx = 4;
		gbc_pauseFrame.gridy = 1;
		this.add(pauseFrame, gbc_pauseFrame);
		
		forwardFrame = new JButton("");
		forwardFrame.setToolTipText("Forward One Frame");
		forwardFrame.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_176_forward.png")));
		GridBagConstraints gbc_forwardFrame = new GridBagConstraints();
		gbc_forwardFrame.weightx = 0.5;
		gbc_forwardFrame.insets = new Insets(0, 0, 0, 5);
		gbc_forwardFrame.gridx = 5;
		gbc_forwardFrame.gridy = 1;
		this.add(forwardFrame, gbc_forwardFrame);
		
		seekForward = new JButton("");
		seekForward.setToolTipText("Seek Forward");
		seekForward.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_178_step_forward.png")));
		GridBagConstraints gbc_seekFoward = new GridBagConstraints();
		gbc_seekFoward.weightx = 0.5;
		gbc_seekFoward.insets = new Insets(0, 0, 0, 5);
		gbc_seekFoward.gridx = 6;
		gbc_seekFoward.gridy = 1;
		this.add(seekForward, gbc_seekFoward);
		
		fastSeekForward = new JButton("");
		fastSeekForward.setToolTipText("Fast Seek Forward");
		fastSeekForward.setIcon(new ImageIcon(NavigationPanel.class.getResource("/resources/glyphicons_177_fast_forward.png")));
		GridBagConstraints gbc_fastSeekFoward = new GridBagConstraints();
		gbc_fastSeekFoward.weightx = 0.5;
		gbc_fastSeekFoward.insets = new Insets(0, 0, 0, 5);
		gbc_fastSeekFoward.gridx = 7;
		gbc_fastSeekFoward.gridy = 1;
		this.add(fastSeekForward, gbc_fastSeekFoward);
	}
	
	private void registerListeners() {
		slider.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
                if(mediaPlayer.isPlaying()) {
                    mousePressedPlaying = true;
                    mediaPlayer.pause();
                }
                else {
                    mousePressedPlaying = false;
                }
                setSliderBasedPosition();
            }

            @Override
            public void mouseReleased(MouseEvent e) {
                setSliderBasedPosition();
                updateUIState();
            }
        });
		fastSeekBackward.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	fastSeekBackward();
            }
        });
		seekBackward.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	seekBackward();
            }
        });
		rewindFrame.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	previousFrame();
            }
        });
		playFrame.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	play();
            }
        });
		pauseFrame.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	pause();
            }
        });
		forwardFrame.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	nextFrame();
            }
        });
		seekForward.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	seekForward();
            }
        });
		fastSeekForward.addMouseListener(new MouseAdapter() {
            @Override
            public void mousePressed(MouseEvent e) {
            	fastSeekForward();
            }
        });
	}
	
//	public void addNavigationListener(ActionListener nl){
//		//slider.addActionListener(nl);
//		fastSeekBackward.addActionListener(nl);
//		seekBackward.addActionListener(nl);
//		rewindFrame.addActionListener(nl);
//		playFrame.addActionListener(nl);
//		pauseFrame.addActionListener(nl);
//		forwardFrame.addActionListener(nl);
//		seekForward.addActionListener(nl);
//		fastSeekForward.addActionListener(nl);
//	}
	
	private final class UpdateRunnable implements Runnable {
        private final MediaPlayer mediaPlayer;

        private UpdateRunnable(MediaPlayer mediaPlayer) {
            this.mediaPlayer = mediaPlayer;
        }

        @Override
        public void run() {
            final long time = mediaPlayer.getTime();
            final int position = (int)(mediaPlayer.getPosition() * 1000.0f);

            // Updates to user interface components must be executed on the Event
            // Dispatch Thread
            SwingUtilities.invokeLater(new Runnable() {
                @Override
                public void run() {
                    if(mediaPlayer.isPlaying()) {
                        updateTime(time);
                        updatePosition(position);
                    }
                }
            });
        }
    }
	
	// helper routines for controller
	public void fastSeekBackward(){
		skip(-SKIP_TIME_MS_FAST);
	}
	public void seekBackward(){
		skip(-SKIP_TIME_MS_NORMAL);
	}
	public void previousFrame(){
		skipWithoutUpdate(-SKIP_TIME_MS_ONE_FRAME);
	}
	public void togglePlay(){
		if(mediaPlayer.isPlaying()){
    		pause();
    	} else {
    		play();
    	}
	}
	public void nextFrame(){
		mediaPlayer.nextFrame();
	}	
	public void seekForward(){
		skip(SKIP_TIME_MS_NORMAL);
	}
	public void fastSeekForward(){
		skip(SKIP_TIME_MS_FAST);
	}
	
	public void playFasterRate(){
		playRate = playRate * 2;
		if (playRate >= RATE_MAX_MULTIPLE){
			playRate = RATE_MAX_MULTIPLE;
		}
		mediaPlayer.setRate(playRate);
	}
	public void playSlowerRate(){
		playRate = playRate / 2;
		if (playRate <= RATE_MIN_MULTIPLE){
			playRate = RATE_MIN_MULTIPLE;
		}
		mediaPlayer.setRate(playRate);
	}
	public void playNormalRate(){
		playRate = RATE_NORMAL_MULTIPLE;
		mediaPlayer.setRate(playRate);
	}
	
	// helper routines:
	private void play(){
		if (!mediaPlayer.isPlaying()){
            mediaPlayer.play();
		}
        if (!mediaPlayer.isPlayable()){
        	mediaPlayer.stop();
        	mediaPlayer.play();
        }
	}
	
	private void pause(){
    	if (mediaPlayer.isPlaying()){
			mediaPlayer.pause();
		}
	}
	
	private void setSliderBasedPosition() {
        if(!mediaPlayer.isSeekable()) {
            return;
        }
        float positionValue = slider.getValue() / 1000.0f;
        // Avoid end of file freeze-up
        if(positionValue > 0.99f) {
            positionValue = 0.99f;
        }
        mediaPlayer.setPosition(positionValue);
    }
	
	private void updateUIState() {
        if(!mediaPlayer.isPlaying()) {
            // Resume play or play a few frames then pause to show current position in video
            mediaPlayer.play();
            if(!mousePressedPlaying) {
                try {
                    // Half a second probably gets an iframe
                    Thread.sleep(500);
                }
                catch(InterruptedException e) {
                    // Don't care if unblocked early
                }
                mediaPlayer.pause();
            }
        }
        long time = mediaPlayer.getTime();
        int position = (int)(mediaPlayer.getPosition() * 1000.0f);
        updateTime(time);
        updatePosition(position);
    }
	
	private void updateTime(long millis) {
        String s = String.format("%02d:%02d:%02d", TimeUnit.MILLISECONDS.toHours(millis), TimeUnit.MILLISECONDS.toMinutes(millis) - TimeUnit.HOURS.toMinutes(TimeUnit.MILLISECONDS.toHours(millis)), TimeUnit.MILLISECONDS.toSeconds(millis) - TimeUnit.MINUTES.toSeconds(TimeUnit.MILLISECONDS.toMinutes(millis)));
        timeLabel.setText(s);
    }

    private void updatePosition(int value) {
    	slider.setValue(value);
    }
	
	private void skip(int skipTime) {
        // Only skip time if can handle time setting
        if(mediaPlayer.getLength() > 0) {
            mediaPlayer.skip(skipTime);
            updateUIState();
        }
    }
	
	private void skipWithoutUpdate(int skipTime) {
        // Only skip time if can handle time setting
        if(mediaPlayer.getLength() > 0) {
            mediaPlayer.skip(skipTime);
        }
    }
}
