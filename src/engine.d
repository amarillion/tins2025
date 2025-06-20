module engine;

import helix.color;
import helix.component;
import helix.style;
import helix.resources;
import helix.mainloop;
import helix.util.vec;
import helix.tilemap;
import helix.widgets;
import helix.richtext;

import std.stdio;
import std.conv;
import std.math;
import std.exception;
import std.format;

import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_font;
import allegro5.allegro_ttf;

import std.json;

import dialog;

class State : Component {

	this(MainLoop window) {
		super(window, "default");
	}

	//TODO: I want to move this registry to window...
	private Component[string] componentRegistry;

	void buildDialog(JSONValue data) {
		buildDialogRecursive(this, data);
	}

	void buildDialogRecursive(Component parent, JSONValue data) {

		assert(data.type == JSONType.ARRAY);

		foreach (eltData; data.array) {
			// create child components
		
			Component div = null;
			string type = eltData["type"].str;
			switch(type) {
				case "button": {
					div = new Button(window);
					break;
				}
				case "richtext": {
					div = new RichText(window);
					break;
				}
				case "image": {
					ImageComponent img = new ImageComponent(window);
					img.img = window.resources.bitmaps[eltData["src"].str];
					div = img;
					break;
				}
				case "pre": {
					auto pre = new PreformattedText(window);
					div = pre;
					break;
				}
				default: div = new Component(window, "div"); break;
			}

			assert("layout" in eltData);
			div.layoutFromJSON(eltData["layout"].object);

			if ("text" in eltData) {
				div.text = eltData["text"].str;
			}
			
			// override local style. TODO: make more generic
			if ("style" in eltData) {
				div.setLocalStyle(eltData["style"]);
			}

			if ("id" in eltData) {
				div.id = eltData["id"].str;
				componentRegistry[div.id] = div;
			}

			parent.addChild(div);
			if ("children" in eltData) {
				buildDialogRecursive(div, eltData["children"]);
			}
		}
	}

	Component getElementById(string id) {
		enforce(id in componentRegistry, format("Component '%s' not found", id));
		return componentRegistry[id];
	}

	override void draw(GraphicsContext gc) {
		foreach (child; children) {
			child.draw(gc);
		}
	}
}

class TitleState : State {

	this(MainLoop window) {
		super(window);
		
		/* MENU */
		buildDialog(window.resources.jsons["title-layout"]);
		
		getElementById("btn_start_game").onAction.add((e) { 
			window.switchState("GameState");
		});

		getElementById("btn_credits").onAction.add((e) { 
			RichTextBuilder builder = new RichTextBuilder()
				.h1("Exo Keeper III")
				.text("Exo Keeper III is a game about surviving and thriving on an exo-planet.").br()
				.text("This was made by")
				.p()
				.b("Amarillion").text(" (3D engine programming)").br()
				.b("Max").text(" (Cure and Adorable Sprites)").br()
				.b("AniCator").text(" (Musical chaos)")
				.p()
				.text("during the ").link("TINS 2025 Game Jam", "https://tins.amarillion.org/2025").text("!").p()
				.text("This is an Allegro remake of a game originally made for ").link("Ludum Dare 46", "https://ldjam.com/events/ludum-dare/46/exo-keeper").p()
				.text("The following people contributed to the original").p()
				.link("Georgii 'Gekaremi' Karelin", "https://github.com/gekaremi").text(" (Concept & scientific discussion)").br()
				.link("Tatiana Kondratieva", "https://www.instagram.com/l_p_kongroo").text(" (Original Microbe Art)").br()
				.link("Dónall O'Donoghue", "http://www.dodonoghue.com/").text(" (Original Music)").br();
			openDialog(window, builder.build());
		});

	}

}
