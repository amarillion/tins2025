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
import sphereGrid;
import mesh;

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

class Sim {

	/** grid for cellular automata */
	SphereGrid grid;

	SimpleSpecies[long] species; // map of species by id.

	Planet planet;
	long tickCounter = 0;
	bool[string] achievements;

	this(Mesh meshData) {
		grid = new SphereGrid(meshData);
		planet = new Planet(); // planetary properties
		setup();
	}

	private void setup() {
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
		// TODO: was eachNodeCheckered before. How to implement eachNodeCheckered for sphere grid?
		foreach (cell; grid.eachNode()) {
			foreach (other; grid.getAdjacent(cell)) {
				cell.diffusionTo(other);
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
		// pick a random cell, pick the top species, and evolve.
		import std.random : uniform;
		auto randomCell = grid.getCell(to!int(uniform(0, grid.size)));
		if (randomCell.species.length == 0) return; // no species to evolve.
		// pick the top species, and evolve it.
		auto topSpecies = randomCell.species[0];
		if (topSpecies.biomass.get() < 5.0) return; // not enough biomass to evolve.
		// split off 1.0 units
		auto newSpecies = SpeciesMap.ALL_SPECIES.mutate(topSpecies.speciesId);
		randomCell.addSpecies(newSpecies, 1.0);
		topSpecies.biomass -= 1.0;
	}

	void migrate() {
		// for each pair of cells, do migration
		// TODO before I used eachNodeCheckered - random order to avoid bias. How to implement this for sphere grid?
		foreach(long idx, ref Cell cell; grid.eachNode()) {
			auto adjacent = grid.getAdjacent(cell);
			// migration direction depends on tick, with index to mix it up.
			auto neighbor = adjacent[(tickCounter + idx) % adjacent.length];
			cell.migrateTo(neighbor);
		}
	}

	void updatePlanet() {
		this.planet.reset();
		foreach(c; grid.eachNode()) {
			c.updateStats(this.planet);
		}
		const n = grid.size;
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