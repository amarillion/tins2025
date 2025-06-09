module gamestate;

import engine;
import helix.mainloop;
import helix.widgets;
import helix.tilemap;
import helix.util.vec;
import helix.util.coordrange;
import helix.layout;
import helix.component;
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
import world;
import renderSpecies;
import sphereGrid;
import mesh;
import primitives3d;

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
		.text(format!`id: %d`(c.id))
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
	Cell currentCell;
	RadioGroup!int speciesGroup;
	World world;

	int numPoints = 256;

	this(MainLoop window) {
		super(window);

		auto meshData = generateFibonacciSpehereMesh(numPoints);
		initSim(meshData);

		/* GAME SCREEN */
		buildDialog(window.resources.jsons["game-layout"]);

		auto planetViewParentElt = getElementById("div_planet_view");
		
		world = new World(window, meshData, sim.grid);

		planetViewParentElt.addChild(world);
		window.focus(world);

		world.selectedFace.onChange.add((e) {
			currentCell = sim.grid.getCell(e.newValue);
		});
		
		planetElement = getElementById("pre_planet_info");
		logElement = cast(RichText)getElementById("rt_cell_info");
		assert(logElement);
		speciesInfoElement = cast(RichText)getElementById("rt_species_info");
		assert(speciesInfoElement);
		
		auto btn1 = getElementById("btn_species_info");
		RenderSpecies speciesRenderer = new RenderSpecies(window);
		btn1.onAction.add((e) { 
			const selectedSpecies = speciesGroup.value.get();
			if(selectedSpecies < 0) {
				return;
			}
			Component slotted = new Component(window, "default");

			auto info = START_SPECIES[selectedSpecies];
			ImageComponent img = new ImageComponent(window);
			img.setRelative(0, 0, 0, 0, 512, 384, LayoutRule.BEGIN, LayoutRule.CENTER);
			img.img = speciesRenderer.renderSingleSpecies(info);

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

		auto btn3 = getElementById("btn_toggle_heatmap");
		btn3.onAction.add((e) {
			world.toggleHeatmap();
		});

		auto btn4 = getElementById("btn_toggle_albedo_overlay");
		btn4.onAction.add((e) {
			world.toggleAlbedoOverlay();
		});

		auto btn5 = getElementById("btn_view_species");
		btn5.onAction.add((e) {
			world.clearOverlays();
		});

		auto btn6 = getElementById("btn_toggle_rotation");
		btn6.onAction.add((e) {
			world.toggleRotation();
		});

		initSpeciesButtons();
	}

	private void initSpeciesButtons() {
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

	private void initSim(Mesh meshData) {
		sim = new Sim(meshData);
		currentCell = sim.grid.getCell(0);
		initBiotopes(sim.grid);
	}

	private void initBiotopes(SphereGrid sphereGrid) {
		// first initalize all cells with random biotope
		foreach(i; 0 .. sphereGrid.size) {
			Cell cell = sphereGrid.getCell(to!int(i));
			cell.biotope = uniform(0, NUM_BIOTOPES);
		}

		// now put some tiles the cells
		// do some sort of voting rule
		foreach (i; 0 .. sphereGrid.size * 20) {
			// pick random cell, and copy biotope to random adjacent cell
			Cell cell = sphereGrid.getCell(to!int(uniform(0, sphereGrid.size)));
			const Cell[] adj = sphereGrid.getAdjacent(cell);
			const Cell choice = adj[uniform(0, adj.length)];
			
			cell.biotope = choice.biotope; // copy biotope
			import std.stdio : writeln;
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
		world.sprites = [];
		foreach (cell; sim.grid.eachNode()) {

			// get top 4 species from cell...
			foreach (i; 0 .. min(cell.species.length, 4)) {
				auto sp = cell.species[i];
				if (sp.biomass.get() < 5.0) continue;
								
				double change = sp.biomass.changeRatio();
				int tile2 = -1;
				if (change < 0.98) {
					tile2 = change < 0.96 ? 19: 18;
				}
				else if (change > 1.02) {
					tile2 = change > 1.04 ? 17: 16;
				}
				
				world.sprites ~= Sprite(
					faceId: cell.id,
					speciesId: sp.speciesId,
					changeTile: tile2,
					localIdx: i
				);
			}

			// save each value to calculate ratio next round
			foreach (ref sp; cell.species) {
				sp.biomass.tick();
			}
		}
	}

}
