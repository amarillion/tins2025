module sim;

import helix.util.grid;
import planet;
import species;
import cell;
import helix.util.vec;
import helix.util.coordrange;
import dialog;
import helix.mainloop;
import helix.richtext;
import std.format : format;
import std.conv : to;

struct Trigger {
	string id;
	bool delegate(Sim) condition;
	Fragment[] delegate(Sim) toMessage;
}

const TRIGGERS = [
	Trigger(
		"start",
		(sim) => sim.tickCounter > 0,
		(sim) => new RichTextBuilder()
			.h1(`Welcome to Exo Keeper`)
			.text(format!`After a voyage of hundreds of lightyears, you have now arrived. Before you lies the barren surface of Kepler-7311b
Your goal is to make the surface suitable for human inhabitation. 
But the planet is far too cold. At a breezy %.0f °K / %.0f °C) it's impossible to 
step outside without a jacket. Plus, there is no oxygen atmosphere.`(sim.planet.temperature, sim.planet.temperature - 273))
			.p()
			.text(`To terraform the planet, we must introduce some microbe species to the surface.`)
			.p()
			.text(`Study and choose one of the 12 species below. Click on any location in the map, pick a species, and click 'Introduce species'.
Note that after introducing a species, it takes 20 seconds of game-time before another new batch of that species is ready again.`)
			.build()
	),
	Trigger(
		"dead_biomass_increased",
		(sim) => sim.planet.deadBiomass > 1.2e5,
		(sim) => new RichTextBuilder().h1(`Dead biomass build-up`).text(
`Life on the surface is harsh, and microbes are dying, leaving their dead bodies behind.
They won't decompose, unless you introduce the microbes that do so. Make sure you introduce some decomposers!`)
			.build()
	),
	Trigger(
		"albedo_lowered",
		(sim) => (sim.tickCounter > 10 && sim.planet.albedo < 0.65),
		(sim) => new RichTextBuilder().h1(`Albedo is lowering`).text(format!`
Great job! The albedo of the planet is currently %.2f and lowering.
With a lower albedo, more of the energy from the star Kepler-7311 is being absorbed, warming the surface.
By introducing more species, you can decrease the albedo of the planet even further`(sim.planet.albedo))
			.build()
	),
	Trigger(
		"first_ice_melting",
		(sim) => sim.planet.maxTemperature > 273,
		(sim) => new RichTextBuilder().h1(`First ice is melting`).text(
format!`At the warm equator, the temperature has reached %.0f °K (Or %.0f °C)
This means that ice starts melting and the planet is getting even more suitable for life.
Can you reach an average temperature of 298 °K?`(sim.planet.maxTemperature, sim.planet.maxTemperature - 273))
			.build()
	),
	Trigger(
		"room_temperature_reached",
		(sim) => sim.planet.temperature > 298,
		(sim) => new RichTextBuilder().h1(`Temperate climate`).text(format!
`The average temperature of your planet now stands at %.0f °K ( or %.0f °C)
The ice has melted, there is oxygen in the atmosphere, the surface is teeming with life.
Well done, you have taken this game as far as it goes!`(sim.planet.temperature, sim.planet.temperature - 273))
			.p()
			.text(`Thank you for playing.
Did you like it? Send me a message to @mpvaniersel on twitter!`)
			.build()
	)
];

AdjacentRange!(2, T) getAdjacent(T)(Grid!(2, T) grid, Point pos) {
	return AdjacentRange!(2, T)(grid, pos);
}

struct AdjacentRange(int N, T) {
	
	Grid!(N, T) parent;
	Point pos;
	
	int opApply(int delegate(const ref Point) operations) const {
		const deltas = [
			Point(0,-1), 
			Point(1,0), 
			Point(0,1), 
			Point(-1,0)
		];

		int result = 0;

		foreach (i, delta; deltas) {
			Point neighbor = Point(
				(pos.x + parent.width + delta.x) % parent.width, 
				pos.y + delta.y
			);
			if (!parent.inRange(neighbor)) continue;
			result = operations(neighbor);
			if (result) {
				break;
			}
		}
		return result;
	}
}

class Sim {

	/** grid for cellular automata */
	Grid!(2, Cell) grid;

	SimpleSpecies[long] species; // map of species by id.

	Planet planet;
	long tickCounter = 0;
	bool[string] achievements;

	this(int w, int h) {
		// TODO: return to larger grid
		grid = new Grid!(2, Cell)(w, h);
		foreach(p; PointRange(Point(w, h))) {
			grid[p] = new Cell(p.x, p.y, grid.height);
		}
		planet = new Planet(); // planetary properties
		init();
	}

	void init() {
		// introduce the first species with random DNA
		// NB: the first 12 species will be hardcoded
		foreach (i; 0..4) {
			// this.createSpecies();
		
			// randomly drop some species in a few spots.
			// for (let j = 0; j < 5; ++j) {
			// 	const randomCell = this.grid.randomCell();
			// 	randomCell.addSpecies(lca.id, 100);
			// }
		}
	}

/*
	void createSpecies() {
		//TODO - I don't think this was used at all?
		const s = new Species();
		species[s.id] = s;
		return s;
	}
*/
	void tick() {
		updatePhysicalProperties();
		// phase I
		growAndDie();
		// phase II
		interact();
		// phase III
		evolve();
		// phase IV
		migrate();
		// phase V
		updatePlanet();

		tickCounter += 1;
	}

	void updatePhysicalProperties() {
		foreach (c; grid.eachNode()) {
			c.updatePhysicalProperties();
		}

		// for each pair of cells, do diffusion
		foreach (c; grid.eachNodeCheckered()) {
			foreach (other; grid.getAdjacent(Point(c.x, c.y))) {
				c.diffusionTo(grid[other]);
			}
		}
	}

	void growAndDie() {
		foreach (c; grid.eachNode()) {
			c.growAndDie();
		}
	}

	void interact() {

	}

	void evolve() {

	}

	void migrate() {
		// for each pair of cells, do migration
		foreach (cell; grid.eachNodeCheckered()) {
			
			const deltas = [
				Point(0,-1), 
				Point(1,0), 
				Point(0,1), 
				Point(-1,0)
			];

			// migration direction depends on tick, with position to mix it up.
			Point delta = deltas[to!size_t((tickCounter + cell.x + cell.y) % 4)];
			Point neighbor = Point(
				(cell.x + grid.width + delta.x) % grid.width, 
				cell.y + delta.y
			);
			if (!grid.inRange(neighbor)) continue;
			
			cell.migrateTo(grid[neighbor]);
		}

	}

	void updatePlanet() {
		this.planet.reset();
		foreach(c; grid.eachNode()) {
			c.updateStats(this.planet);
		}
		const n = grid.width * grid.height;
		planet.temperature = planet.temperatureSum / n;
		planet.albedo = planet.albedoSum / n;

	}

	void checkAchievements(MainLoop window) {
		foreach (v; TRIGGERS) {
			// don't trigger twice...
			if (v.id in this.achievements) continue;

			if (v.condition(this)) {
				achievements[v.id] = true;
				openDialog(window, v.toMessage(this));
			}
		}
	}

}