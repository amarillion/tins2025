module gamestate;

import engine;
import helix.mainloop;
import helix.widgets;
import helix.tilemap;
import helix.util.vec;
import helix.util.coordrange;
import helix.layout;
import helix.component;
import planetview;
import std.json;
import sim;
import cell;
import std.conv;
import std.format;
import std.array;
import std.algorithm;
import startSpecies;
import helix.signal;
import helix.timer;
import helix.richtext;
import dialog;
import std.random;
import constants;

class RadioGroup(T) {

	Model!T value;
	Component[T] buttons;
	
	void addButton(Component c, T _value) {
		buttons[_value] = c;
		c.onAction.add((e) {
			value.set( _value);
			updateButtons();
		});
	}

	void updateButtons() {
		foreach(v, button; buttons) {
			button.selected = (v == value.get());	
		}
	}

	void select(T _value) {
		value.set(_value);
		updateButtons();
	}
}

RichTextBuilder biotope(RichTextBuilder b, MainLoop window, int biotope) {
	const biotopes = [
		0: "sorry_sulfuric2",
		1: "mountain3",
		2: "sulfur4",
		3: "lava1",
		4: "canyon1",
		5: "lowland0",
		6: "salt4",
		7: "canyon2",
	];
	return b.img(window.resources.bitmaps[biotopes[biotope]]);
}

RichTextBuilder species(RichTextBuilder b, MainLoop window, int sp) {
	return b.img(window.resources.bitmaps[START_SPECIES[sp].iconUrl]);
}

	RichTextBuilder cellInfo(RichTextBuilder b, MainLoop window, Cell c) {
		b
		.h1("Selected area")
		.biotope(window, c.biotope)
		.text(format!`[%d, %d]`(c.x, c.y))
		.p()
		.i(format!"Temperature: %.0f °K"(c.temperature))
		.p()
		.lines(format!
`Heat: %.2e GJ/km²
Heat gain from sun: %.2e GJ/km²/tick
Heat loss to space: %.2e GJ/km²/tick
Albedo: %.2f

Latitude: %d deg

CO₂: %.1f
H₂O: %.1f
O₂: %.1f
Organic: %.1f`(
	c.heat, c.stellarEnergy, c.heatLoss, c.albedo, 
	c.latitude, c.co2, c.h2o, c.o2, c.deadBiomass)).p();
		foreach(ref sp; c._species) { b
			.species(window, to!int(sp.speciesId))
			.text(format!": %.1f "(sp.biomass.get()));
			if (sp.status != "") { b.b(sp.status); }
			b.br();
		}
		return b;
	}


class GameState : State {

	Sim sim;
	RichText logElement;
	Component planetElement;
	RichText speciesInfoElement;
	TileMap planetMap;
	TileMap speciesMap;
	Cell currentCell;
	RadioGroup!int speciesGroup;
	PlanetView planetView;

	final void initMap() {
		// planetMap.fromTiledJSON(window.resources.getJSON("planetscape")); 
		planetMap = new TileMap(MAP_WIDTH, MAP_HEIGHT, 1);
		planetMap.tilelist = TileList(Point(64, 64), 8, window.resources.bitmaps["biotope"]);

		foreach (p; PointRange(Point(planetMap.width, planetMap.height))) {
			planetMap.layers[0][p] = uniform(0, NUM_BIOTOPES);
		}

		// do some sort of voting rule
		foreach (i; 0 .. (MAP_WIDTH * MAP_HEIGHT) * 5) {
			// pick random cell, and copy biotope to random adjacent cell
			Point rndpos = Point (uniform(0, planetMap.width), uniform(0, planetMap.height));
			const Point[] adj = getAdjacent(planetMap.layers[0], rndpos).array;
			Point choice = adj[uniform(0, adj.length)];
			planetMap.layers[0][choice] = planetMap.layers[0][rndpos];
		}

		// initialize species map
		speciesMap = new TileMap(MAP_WIDTH * 2, MAP_HEIGHT * 2, 2);
		foreach (p; PointRange(Point(speciesMap.width, speciesMap.height))) {
			speciesMap.layers[0][p] = -1;
			speciesMap.layers[1][p] = -1;
		}
		speciesMap.tilelist = TileList(Point(32, 32), 32, window.resources.bitmaps["species"]);

	}

	this(MainLoop window) {
		super(window);

		/* GAME SCREEN */
		buildDialog(window.resources.jsons["game-layout"]);

		initMap();


		auto planetViewParentElt = getElementById("div_planet_view");
		
		planetView = new PlanetView(window);
		planetView.planetMap = planetMap;
		planetView.speciesMap = speciesMap;
		planetView.selectedTile.onChange.add((e) {
			currentCell = sim.grid[e.newValue];
		});
		planetViewParentElt.addChild(planetView);
	
		planetElement = getElementById("pre_planet_info");
		logElement = cast(RichText)getElementById("rt_cell_info");
		assert(logElement);
		speciesInfoElement = cast(RichText)getElementById("rt_species_info");
		assert(speciesInfoElement);
		
		auto btn1 = getElementById("btn_species_info");
		btn1.onAction.add((e) { 
			const selectedSpecies = speciesGroup.value.get();
			if(selectedSpecies < 0) {
				return;
			}
			Component slotted = new Component(window, "default");

			auto info = START_SPECIES[selectedSpecies];
			ImageComponent img = new ImageComponent(window);
			img.setRelative(0, 0, 0, 0, 512, 384, LayoutRule.BEGIN, LayoutRule.CENTER);
			img.img = window.resources.bitmaps[info.coverArt];

			RichText rt1 = new RichText(window);
			rt1.setRelative(528, 0, 0, 0, 0, 0, LayoutRule.STRETCH, LayoutRule.STRETCH);
			
			auto rtb = new RichTextBuilder().h1("Species info")
				.text(format!"Name: %s"(info.name)).br()
				.text(info.backstory)
				.p()
				.lines(format("Temperature tolerance between %.0f °K and %.0f °K\nAlbedo contribution: %.2f (lower is better)", 
					info.temperatureRange[0], info.temperatureRange[1], info.albedo)).br()
				.text("Likes:").br();

			foreach (k, v; info.biotopeTolerances) {
				if (v > 0.5) {
					rtb.biotope(window, k);
				}
			}
			rtb.p().text("Dislikes:").br();
			foreach (k, v; info.biotopeTolerances) {
				if (v < 0.5) {
					rtb.biotope(window, k);
				}
			}

			rt1.setFragments(rtb.build());
			
			slotted.addChild(img);
			slotted.addChild(rt1);
			Dialog dlg = new Dialog(window, slotted);
			window.pushScene(dlg);
		});

		auto btn2 = getElementById("btn_species_introduce");
		btn2.onAction.add((e) {
			if (currentCell) {
				int selectedSpecies = speciesGroup.value.get();
				if (selectedSpecies >= 0) {
					currentCell.addSpecies(selectedSpecies, 10);
					
					btn2.disabled = true;
					addChild (new Timer(window, 100, {
						btn2.disabled = false;
					}));
				}
			}
		});

		initSpeciesButtons();
		initSim(planetMap);
	}

	void initSpeciesButtons() {
		Component parentElt = getElementById("pnl_species_buttons");
		int xco = 0;
		int yco = 0;
		speciesGroup = new RadioGroup!int();
		
		foreach(i, sp; START_SPECIES) {
			Button btn = new Button(window);
			btn.setRelative(xco, yco, 0, 0, 36, 36, LayoutRule.BEGIN, LayoutRule.BEGIN);
			btn.icon = window.resources.bitmaps[sp.iconUrl];
			xco += 40;
			parentElt.addChild(btn);
			speciesGroup.addButton(btn, to!int(i));
		}

		speciesGroup.value.onChange.add((e) {
			int selectedSpecies = e.newValue;
			if (selectedSpecies < 0) {
				speciesInfoElement.setFragments([]);
				return;
			}
			auto info = START_SPECIES[selectedSpecies];
			auto rtb = new RichTextBuilder()
				.lines(format("Temperature range: %.0f °K - %.0f °K\nAlbedo: %.2f", 
					info.temperatureRange[0], info.temperatureRange[1], info.albedo)).br()
				.text("Likes: ");

			foreach (k, v; info.biotopeTolerances) {
				if (v > 0.5) {
					rtb.biotope(window, k);
				}
			}
			rtb.text(" Dislikes: ");
			foreach (k, v; info.biotopeTolerances) {
				if (v < 0.5) {
					rtb.biotope(window, k);
				}
			}

				// TODO: likes and dislikes
			speciesInfoElement.setFragments(rtb.build());

		});

		speciesGroup.value.set(-1); // nothing selected
	}

	void initSim(TileMap map) {
		sim = new Sim(map.width, map.height);
		currentCell = sim.grid[Point(0)];
		this.initBiotopes(map);
	}

	void initBiotopes(TileMap map) {
		// copy biotopes from layer to cells
		foreach(pos; PointRange(map.layers[0].size)) {
			int biotope = map.layers[0][pos];
			sim.grid[pos].biotope = biotope;
		}
	}

	
	override void update() {
		super.update();

		// in original game, delay was 500 msec
		static int tickDelay = 0;
		if (tickDelay++ == 5) {
			tickAndLog();
			tickDelay = 0;
		}
	}

	void tickAndLog() {
		sim.tick();
		// gridView.update(); // TODO
		logElement.setFragments (new RichTextBuilder().cellInfo(window, currentCell).build());
		planetElement.text = format("Tick: %s\n%s", sim.tickCounter, sim.planet);
		updateSpeciesMap();
		sim.checkAchievements(window);

	}

	void updateSpeciesMap() {
		
		foreach (cell; sim.grid.eachNode()) {

			Point pos = Point(cell.x, cell.y) * 2;
			Point[] deltas = PointRange(Point(2)).array;
			foreach (delta; deltas) {
				speciesMap.layers[0][pos + delta] = -1;
				speciesMap.layers[1][pos + delta] = -1;
			}

			// get top 4 species from cell...
			foreach (i; 0 .. min(cell.species.length, 4)) {
				auto sp = cell.species[i];
				if (sp.biomass.get() < 5.0) continue;
				const tileIdx = START_SPECIES[sp.speciesId].tileIdx;
				speciesMap.layers[0][pos + deltas[i]] = tileIdx;
				
				double change = sp.biomass.changeRatio();
				int tile2 = -1;
				if (change < 0.98) {
					tile2 = change < 0.96 ? 19: 18;
				}
				else if (change > 1.02) {
					tile2 = change > 1.04 ? 17: 16;
				}
				speciesMap.layers[1][pos + deltas[i]] = tile2;
			}


			// save each value to calculate ratio next round
			foreach (ref sp; cell.species) {
				sp.biomass.tick();
			}
		}
	}

}
