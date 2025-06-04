module mainState;

import std.json;
import std.conv;
import std.format;
import std.string;

import allegro5.shader;
import allegro5.allegro_color;

import helix.resources;
import helix.mainloop;
import helix.richtext;
import helix.component;
import helix.scroll;
import helix.layout;
import helix.util.vec;
import helix.widgets;

import dialog;
import dialogBuilder;
import core.sys.posix.fcntl;

class MainState : DialogBuilder {

	ResourceManager userResources;
	ScrollPane sp;
	Component canvas;

	this(MainLoop window) {
		super(window);

		userResources = new ResourceManager();

		window.onClose.add(() { 
			destroy(userResources); 
		});
		
		window.onDisplaySwitch.add((switchIn) { 
			if (switchIn) { userResources.refreshAll(); }
		});

		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		canvas = getElementById("canvas");
		
		// sp = new ScrollPane(window, canvas);
		//TODO: get layout from dialog json
		// sp.setRelative(0,0,176,0,0,0,LayoutRule.STRETCH,LayoutRule.STRETCH);
		// canvas.addChild(sp);

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("TINS 2025 game")
				.text("This was made by ").b("Amarillion, Max and AniCator")
				.text(" during the TINS 2025 Game Jam!");
			openDialog(window, builder.build());
		});

	}

}
