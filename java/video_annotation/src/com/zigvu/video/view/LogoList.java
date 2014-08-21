package com.zigvu.video.view;

import java.awt.*;

import javax.swing.*;
import javax.swing.border.*;
import javax.swing.event.*;

import com.zigvu.video.annotation.Annotator;

@SuppressWarnings("serial")
public class LogoList extends JScrollPane {
	private Color selectedItemColor = Color.RED;
	WidthCellRenderer cellRenderer;
	private DefaultListModel itemList;
	private JList logoList;

	public LogoList(int width, int height) {
		Annotator.log(Annotator.logInfo, "LogoList: Setting up");
		itemList = new DefaultListModel();
		logoList = new JList(itemList);
		cellRenderer = new WidthCellRenderer(width - 50, selectedItemColor);
		logoList.setCellRenderer(cellRenderer);
		this.setViewportView(logoList);
		//this.setPreferredSize(new Dimension(logoList
		//		.getPreferredScrollableViewportSize().width + 5, height));
		this.setPreferredSize(new Dimension(width + 5, height));
	}

	public void addItem(String item) {
		if (!itemList.contains(item)) {
			Annotator.log(Annotator.logInfo, "LogoList: Adding logo to UI: " + item);
			itemList.addElement(item);
		} else {
			Annotator.log(Annotator.logInfo, "LogoList: Skip adding logo to UI: "
					+ item);
		}
	}

	public Color getColor(int index) {
		return cellRenderer.getCellColor(index);
	}

	public String getName(int index) {
		return (String) itemList.getElementAt(index);
	}

	public int getIndex(String item) {
		return itemList.indexOf(item);
	}

	public void addLogoListListener(ListSelectionListener lsl) {
		logoList.addListSelectionListener(lsl);
	}

	public void enableComponent() {
		AnnotationView.enableComponents(this, true);
	}

	public void disableComponent() {
		logoList.clearSelection();
		AnnotationView.enableComponents(this, false);
	}

	class WidthCellRenderer extends DefaultListCellRenderer {
		public static final String HTML_1 = "<html><body style='width: ";
		public static final String HTML_2 = "px'>";
		public static final String HTML_3 = "</html>";
		private int width;
		private Color selectedItemColor;
		private String[] colourValues = new String[] { "FF0000", "00FF00",
				"0000FF", "FFFF00", "FF00FF", "00FFFF", "000000", "800000",
				"008000", "000080", "808000", "800080", "008080", "808080",
				"C00000", "00C000", "0000C0", "C0C000", "C000C0", "00C0C0",
				"C0C0C0", "400000", "004000", "000040", "404000", "400040",
				"004040", "404040", "200000", "002000", "000020", "202000",
				"200020", "002020", "202020", "600000", "006000", "000060",
				"606000", "600060", "006060", "606060", "A00000", "00A000",
				"0000A0", "A0A000", "A000A0", "00A0A0", "A0A0A0", "E00000",
				"00E000", "0000E0", "E0E000", "E000E0", "00E0E0", "E0E0E0", };
		private Color[] cellColors;

		public WidthCellRenderer(int width, Color selItemColor) {
			this.width = width;
			this.selectedItemColor = selItemColor;
			cellColors = new Color[colourValues.length];
			for (int i = 0; i < colourValues.length; i++) {
				Color tC = new Color(Integer.parseInt(colourValues[i], 16));
				cellColors[i] = new Color(tC.getRed(), tC.getGreen(),
						tC.getBlue(), 50);
			}
		}

		public Color getCellColor(int index) {
			return cellColors[index % cellColors.length];
		}

		@Override
		public Component getListCellRendererComponent(JList list, Object value,
				int index, boolean isSelected, boolean cellHasFocus) {
			String text = HTML_1 + String.valueOf(width) + HTML_2
					+ value.toString() + HTML_3;
			JLabel c = (JLabel) super.getListCellRendererComponent(list, text,
					index, isSelected, cellHasFocus);
			c.setBackground(cellColors[index % cellColors.length]);
			if (isSelected) {
				c.setBorder(new LineBorder(this.selectedItemColor, 2));
			} else {
				c.setBorder(new EmptyBorder(5, 5, 5, 5));
			}
			return c;
		}
	}
}
