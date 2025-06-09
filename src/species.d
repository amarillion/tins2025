module species;

import core.sys.posix.stdlib;
import startSpecies;
import std.conv;
import constants;

enum START_SPECIES_NUM = 12;

enum ROLE {
	REDUCER =  0, // metabolises dead biomass using oxygen
	PRODUCER = 1, // grows from h2o and co2
	CONSUMER = 2, // metabolises living species that it can eat using oxygen
};

enum INTERACTION {
	EAT = 0,
	NEUTRAL = 1, 
	PARASITE = 2, 
	SYMBIOSIS = 3
};

/*

 
	one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER

// interactionMap: 

	for each other species, define how they interact
	1: EAT will mean that this species will eat species 1.
	being carnivore / omnivore / herbivore is implicit
	the role takes precedence. So a ROLE.PRODUCER will never EAT another species, no matter what"s defined in the interactionMap
	B: PARASITE -> current species reduces fitness of B without eating it. For plants, you could imagine that it"s somehow poisonous
	B: SYMBIOSIS -> current speices increases fitness of B just by being in the same location 
					(to be true symbiosis, the same needs to be defined in reverse on the other species)
	B: NEUTRAL -> should be most common. Live side-by-side Neutral is the DEFAULT

biotopeTolerances: 
	
	fitness for each biotope 0..7, as a factor between 0.0 and 1.0. Default: 0.5

*/

struct SpeciesInfo {
	string name;	
	int tileIdx;
	uint color;
	ROLE role;
	INTERACTION[long] interactionMap;
	double albedo;
	double[2] temperatureRange;
	string backstory;
	float[NUM_BIOTOPES] biotopeTolerances;

	int[4] layers; // between 0 and 7.
	int hue1; // between 0 and 360
	int hue2;
}

/*
long globalSpeciesCounter = 0;

struct Species {

	long id;
	string dna;
	double biomass;
	
	this() {
		id = globalSpeciesCounter++;
		dna = ""; // TODO random data
		calculateProperties();
	}

	void calculateProperties() {

	}
}
*/

struct Substance(T) {
	
	private T _latest;
	private T _prev;

	void set(T val) {
		_latest = val;
		assert (_latest >= 0, "Amount dropped below zero"); 
	}

	void tick() {
		_prev = _latest;
	}

	double changeRatio() {
		if (_prev == 0) {
			return 1.0;
		}
		return _latest / _prev;
	}

	T get() {
		return _latest;
	}

	auto opOpAssign(string op, T)(T value) {
		_latest = mixin ("_latest" ~ op ~ "value");
		assert (_latest >= 0, "Amount dropped below zero"); 
		return this;
	}

}

/*
double reaction(T)(Substance!T from, Substance!T to, double amount) {
	assert (amount >= from);
	assert (amount <= from)
	from -= amount;
	to += amount;
}
*/

struct SimpleSpecies {
	
	this(int speciesId, double biomass) {
		this.speciesId = speciesId;
		this.biomass.set(biomass);
	}
	
	int speciesId;
	Substance!double biomass;
	
	string status = ""; // something to explain what it's doing...
}

class SpeciesMap {

	private static nextId = 0;

	static SpeciesMap ALL_SPECIES;
	static this() {
		ALL_SPECIES = new SpeciesMap();
	}

	ref SpeciesInfo get(int id) {
		assert (id in speciesInfo, "Species ID not found: " ~ id.to!string);
		return speciesInfo[id];
	}

	SpeciesInfo[int] speciesInfo;

	this() {
		auto START_SPECIES = initStartSpecies();
		for (int i = 0; i < START_SPECIES.length; i++) {
			speciesInfo[nextId++] = START_SPECIES[i];
		}
	}

	int mutate(int speciesId) {
		if (speciesInfo.length > 10_000) {
			// don't mutate if we have too many species
			return speciesId; // keep the same
			// TODO: cull some dead species from the map.
		}

		import std.random : uniform;

		// copy a species and mutate it
		assert (speciesId in speciesInfo);
		int newId = nextId++;
		assert (newId !in speciesInfo);
		
		speciesInfo[newId] = speciesInfo[speciesId];

		speciesInfo[newId].name = "Variant of species " ~ to!string(speciesId);
		speciesInfo[newId].backstory = "This is a mutant of species '" ~ speciesInfo[speciesId].name ~ "'. It has been mutated by the forces of evolution.";
		// mutations
		speciesInfo[newId].hue1 = (speciesInfo[newId].hue1 + uniform(0, 120) + 300) % 360;
		speciesInfo[newId].hue2 = (speciesInfo[newId].hue2 + uniform(0, 120) + 300) % 360;

		int pctChance = uniform(0, 100);
		if (pctChance < 33) {
			// 33% chance to change a layer
			speciesInfo[newId].layers[uniform(0, 4)] = uniform(0, 8);
		}
		
		// change temperature tolerance
		speciesInfo[newId].temperatureRange[0] += uniform(-5.0, 5.0) + uniform(-5.0, 5.0);
		speciesInfo[newId].temperatureRange[1] += uniform(-5.0, 5.0) + uniform(-5.0, 5.0);

		// change albedo
		speciesInfo[newId].albedo += uniform(-0.1, 0.1);

		// mutate biotope tolerances
		foreach (i, ref tolerance; speciesInfo[newId].biotopeTolerances) {
			tolerance += uniform(-0.1, 0.1);
			if (tolerance < 0.0) tolerance = 0.0;
			if (tolerance > 1.0) tolerance = 1.0;
		}

		return newId;
	}
}

