module app;

import std.stdio;
import std.conv;

import allegro5.allegro;
import allegro5.allegro_audio;

import helix.mainloop;
import helix.richtext;

import dialog;
import mainState;
import engine;
import gamestate;
import startSpecies;

void main(string[] args)
{
	al_run_allegro(
	{
		// non-allegro setup
		initStartSpecies();

		al_init();
		auto mainloop = new MainLoop(MainConfig.of
			.appName("tins25")
			.targetFps(60)
		);
		mainloop.init();

		void showErrorDialog(Exception e) {
			writeln(e.info);
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Error")
				.text(to!string(e.message)).p();
			openDialog(mainloop, builder.build());
		}

		mainloop.onException.add((e) {
			showErrorDialog(e);
		});

		mainloop.resources.addFile("data/DejaVuSans.ttf");
		mainloop.resources.addGlob("data/*.json");
		mainloop.resources.addFile("data/color-replace.glsl");
		mainloop.resources.addGlob("data/*.png");

		mainloop.resources.addGlob("data/biotope/*.png");
		mainloop.resources.addGlob("data/species/*.png");
		mainloop.resources.addGlob("data/species_cover_art/*.png");

		mainloop.styles.applyResource("style");

		mainloop.onDisplaySwitch.add((switchIn) { if (switchIn) { writeln("Window switched in event called"); mainloop.resources.refreshAll(); }});

		mainloop.styles.applyResource("style");
		mainloop.addState("TitleState", new TitleState(mainloop));
		mainloop.addState("GameState", new GameState(mainloop));
		mainloop.switchState("TitleState");
		
		mainloop.run();

		return 0;
	});

}
