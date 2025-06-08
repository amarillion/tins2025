module cell;

import constants;
import startSpecies;
import planet;
import std.math;
import std.algorithm;
import std.range;
import species;
import std.format;

//TODO: switch back to struct.
//We switched to class, because struct semantics do not work well with forEach, getAdjacent etc...
//referring to an element within the data structure
class Cell {

	int x, y;

	// the following are all in Mol
	
	/** dead organic material, represented by formula ch2o */
	double deadBiomass = 0; 
	double co2 = START_CO2;
	double o2 = 0;
	double h2o = START_H2O;
	
	/** latitude in degrees, from -90 (north pole) to 90 (south pole) */
	int latitude;

	double heat = START_HEAT;
	double stellarEnergy;

	int biotope = 0;
	double temperature;
	double albedo;
	double heatLoss;
	string albedoDebugStr;

	/** 
	pairs of { speciesId, biomass }
	keep this list sorted, most prevalent species first
	*/
	SimpleSpecies[] _species;

	/** constructor */
	this(int x, int y, int height) {
		this.x = x;
		this.y = y;

		// the following are all in Mol
		deadBiomass = 0; // dead organic material, represented by formula ch2o
		co2 = START_CO2;
		o2 = 0;
		h2o = START_H2O;
		latitude = ((y * 160 / (height - 1)) - 80);
		heat = START_HEAT;
		
		// constant amount of stellar energy per tick
		stellarEnergy = cos(this.latitude / 180.0 * 3.141) * MAX_STELLAR_HEAT_IN;
		assert (this.stellarEnergy >= 0);

		_species = [];
	}

	double sumLivingBiomass() {
		return reduce!((acc, cur) => acc + cur.biomass.get())(0.0, _species);
	}

	SimpleSpecies[] species() {
		return _species;
	}

	// introduce a given amount of species to this cell
	void addSpecies(int speciesId, double biomass) {
		auto existing = _species.find!(i => i.speciesId == speciesId);
		if (!existing.empty) {
			existing[0].biomass += biomass;
			sortSpecies();
		}
		else {
			_species ~= SimpleSpecies(speciesId, biomass);
			maxSpeciesCheck();
		}
	}

	// if there are more than a given number of species in this cell, the last one is automatically removed
	void maxSpeciesCheck() {
		sortSpecies();
		if (_species.length > MAX_SPECIES_PER_CELL) {
			removeLowestSpecies();
		}
	}

	void removeLowestSpecies() {
		deadBiomass += _species[$-1].biomass.get(); // biomass converted from dead species
		_species = _species[0..$-1]; // pop last one
	}

	// clean up pink elephants (as in: there are not 0.0001 pink elephants in this room)
	// if the amount of species drops below 1.0 mol, then the remainder dies and is cleaned up completely.
	void pinkElephantCheck() {
		sortSpecies();

		if (_species.empty) return;

		auto last = _species[$-1];
		if (last.biomass.get() < SPECIES_MINIMUM) {
			removeLowestSpecies();
		}
	}

	void sortSpecies() {
		sort!"b.biomass.get() < a.biomass.get()"(_species); // TODO: check sort order...
	}

	string speciesToString() {
		return _species.map!(i => format("%s: %.1f", i.speciesId, i.biomass)).join("\n  ");
	}

	// string representation of cell...
	override string toString() {
		return format(`[%d, %d] Biotope: %s
Heat: %.2e GJ/km²
Temperature: %.0f °K
Heat gain from sun: %.2e GJ/km²/tick
Heat loss to space: %.2e GJ/km²/tick
Albedo: %.2f
%s
Latitude: %d deg

CO₂: %.1f
H₂O: %.1f
O₂: %.1f
Organic: %.1f

Species: %s`, 
	x, y, biotope, 
	heat, temperature, stellarEnergy, heatLoss, albedo, albedoDebugStr, 
	latitude, co2, h2o, o2, deadBiomass, speciesToString());
	}

	/** part of Phase I */
	void growAndDie() {
		// each species should grow and die based on local fitness.

		foreach (ref sp; _species) {
			const info = START_SPECIES[sp.speciesId];
			sp.status = "";
			
			double fitness = 1.0;
			assert (this.biotope in info.biotopeTolerances);
			fitness *= info.biotopeTolerances[this.biotope];
			
			if (fitness < 0.3) {
				sp.status = "Bad biotope";
			}

			// no chance of survival outside preferred temperature range
			if (temperature < info.temperatureRange[0]) {
				fitness *= 0.1;
				sp.status = "Too cold";
			} else if (temperature > info.temperatureRange[1]) {
				fitness *= 0.1;
				sp.status = "Too hot";
			}

			//TODO: fitness is affected by presence of symbionts
	
			// fitness must always be a value between 0.0 and 1.0
			assert(fitness >= 0.0 && fitness <= 1.0);

			// each species has 3 possible roles:
			// consumer, producer, reducer	
			if (info.role == ROLE.PRODUCER) {
				// lowest substrate determines growth rate.
				const minS = min(co2, h2o);
				const rate = fitness * temperature * stellarEnergy * PHOTOSYNTHESIS_BASE_RATE * minS; // growth per tick
				
				const amount = min(sp.biomass.get() * rate, this.co2, this.h2o);
				
				if (co2 < sp.biomass.get() / 3) {
					sp.status = "Not enough CO2";
				}
				if (h2o < sp.biomass.get() / 3) {
					sp.status = "Too dry";
				}

				assert (amount >= 0);

				co2 -= amount;
				h2o -= amount;

				o2 += amount;
				sp.biomass += amount;
				assert (sp.biomass.get() >= 0);
			}
			else if (info.role == ROLE.CONSUMER) {
				// for each other species
				double totalFood = 0;
				foreach (ref other; _species) {
					if (other.speciesId == sp.speciesId) continue; // don't interact with self

					const interaction = info.interactionMap.get(other.speciesId, INTERACTION.NEUTRAL);
					if (interaction == INTERACTION.EAT) {
						// sp(ecies) eats other (species)
						// take some of the biomass from other, and adopt it as own biomass
						const rate = fitness * CONSUMPTION_BASE_RATE * other.biomass.get();
						const amount = min(sp.biomass.get() * rate, other.biomass.get());

						assert (amount >= 0);
						other.biomass -= amount;
						sp.biomass += amount;

						totalFood += other.biomass.get();

						assert(sp.biomass.get() >= 0);
						assert(other.biomass.get() >= 0);
					}
				}
				if (totalFood < sp.biomass.get() / 4) {
					sp.status = "Hungry";
				}
			}
			else if  (info.role == ROLE.REDUCER) {
				// reducers take some of the dead biomass, and adopt it as their own biomass
				const double rate = fitness * REDUCTION_BASE_RATE * this.deadBiomass;
				const double amount = min(sp.biomass.get() * rate, this.deadBiomass);

				if (this.deadBiomass < sp.biomass.get() / 4) {
					sp.status = "Not enough organic matter";
				}

				assert (amount >= 0);
				deadBiomass -= amount;
				sp.biomass += amount;

				assert (this.deadBiomass >= 0);
			}

			if (info.role != ROLE.PRODUCER) {
				// simulate respiration for consumers and reducers.
				// lowest substrate determines growth rate.
				const double minS = min(sp.biomass.get(), this.o2);
				if (this.o2 < sp.biomass.get()) {
					sp.status = "Not enough oxygen";
				}

				// not affected by fitness - all species consume oxygen at a given rate
				const double rate = RESPIRATION_BASE_RATE * minS;
				const double amount = min(sp.biomass.get() * rate, sp.biomass.get(), this.o2);

				assert (amount >= 0);
				this.o2 -= amount;
				sp.biomass -= amount;
				this.h2o += amount;
				this.co2 += amount;

				assert (this.deadBiomass >= 0);
			}

			// all species die at a given rate...
			{
				assert(sp.biomass.get() >= 0, format(`Wrong value %s %s`, sp.biomass, sp.speciesId));

				// the lower the fitness, the higher the death rate
				// divisor has a minimum just above 0, to avoid division by 0
				// death rate has a maximum of 1.0 (instant death)
				const double rate = min(1.0, DEATH_RATE / max(fitness, 0.0001));
				const double amount = min(sp.biomass.get() * rate, sp.biomass.get());

				assert (amount >= 0);
				this.deadBiomass += amount;
				sp.biomass -= amount;
			}

		}

		assert (this.o2 >= 0);
		assert (this.co2 >= 0);
		assert (this.h2o >= 0);
		assert (this.deadBiomass >= 0);

		pinkElephantCheck();
	}

	void migrateTo(Cell other) {
		if (this._species.length == 0) return;

		foreach (ref sp; _species) {
			const amount = sp.biomass.get() * MIGRATION_BASE_RATE;
			
			// do not migrate too little - otherwise it will be culled immediately and will be a huge drain on early growth
			if (amount < SPECIES_MINIMUM * 2) {
				continue;
			}

			other.addSpecies(sp.speciesId, amount);
			sp.biomass -= amount;
		}
	}

	void diffuseProperty(string prop)(ref Cell other, double pct_exchange) {
		mixin ("const netAmount = (this."  ~ prop ~ " * pct_exchange) - (other." ~ prop ~ " * pct_exchange);");
		mixin("this." ~ prop ~ " -= netAmount;");
		mixin("other." ~ prop ~ " += netAmount;");
		mixin("assert(this." ~ prop ~  " >= 0);");
		mixin("assert(other." ~ prop ~ " >= 0);");
	}

	void diffusionTo(Cell other) {

		// diffusion of CO2
		{
			// if CO2 is solid, a smaller percentage will diffuse
			const pct_exchange = this.temperature < CO2_BOILING_POINT ? 0.001 : 0.1;
			this.diffuseProperty!"co2"(other, pct_exchange);
		}

		// diffusion of H2O
		{
			// if H2O is solid, a smaller percentage will diffuse
			const pct_exchange = this.temperature < H2O_MELTING_POINT ? 0.001 : 0.1;
			this.diffuseProperty!"h2o"(other, pct_exchange);
		}

		// diffusion of o2
		{
			const pct_exchange = 0.1;
			this.diffuseProperty!"o2"(other, pct_exchange);
		}

		// heat diffusion.
		// a percentage of heat always diffuses...
		// TODO to be realistic, we should also make this dependent on weather
		{
			const pct_exchange = 0.1;
			this.diffuseProperty!"heat"(other, pct_exchange);
		}
	}

	/** calculate heat, albedo, greenhouse effect */
	void updatePhysicalProperties() {
		this.temperature = this.heat / SURFACE_HEAT_CAPACITY; // In Kelvin
		
		// intersects y-axis at 1.0, reaches lim in infinity.
		double mapAlbedoReduction (double lim, double x) {
			return lim + ((1-lim)/(x+1));
		}

		// intersects y-axis at base, reaches 1.0 in infinity
		double mapAlbedoRise (double base, double x) {
			return 1 - ((1-base)/(x+1));
		}

		// start albedo
		// albedo decreased by absence of dry ice or ice
		// (this will increase albedo at the poles for a long time)
		const dryIceEffect = this.temperature < CO2_BOILING_POINT 
			? mapAlbedoRise(0.9, (CO2_BOILING_POINT - this.temperature) * this.co2 / 20_000) 
			: 0.9;
		const iceEffect = this.temperature < H2O_MELTING_POINT 
			? mapAlbedoRise(0.9, (H2O_MELTING_POINT - this.temperature) * this.h2o / 20_000) 
			: 0.9;
		
		const ALBEDO_BASE = 0.75;
		this.albedo = ALBEDO_BASE * iceEffect * dryIceEffect;

		albedoDebugStr = format(`%.2f * %.2f [ice] * %.2f [dryIce]`, ALBEDO_BASE, iceEffect, dryIceEffect);

		foreach (ref sp; _species) {
			const info = START_SPECIES[sp.speciesId];
			const speciesEffect = mapAlbedoReduction(info.albedo, sp.biomass.get() / 500);
			this.albedo *= speciesEffect;
			albedoDebugStr ~= format(` * %g [%s] `, speciesEffect, sp.speciesId);
		}

		albedoDebugStr = albedoDebugStr;

		assert(this.albedo >= 0.0 && this.albedo <= 1.0);

		// receive fixed amount of energy from the sun, but part radiates back into space by albedo effect
		this.heat += (1.0 - this.albedo) * this.stellarEnergy;

		// percentage of heat radiates out to space
		const heatLossPct = 0.01; // TODO: influenced by greenhouse effect and albedo
		this.heatLoss = this.heat * heatLossPct;
		this.heat -= (this.heatLoss);
	}

	void updateStats(Planet planet) {
		planet.co2 += this.co2;
		planet.o2 += this.o2;
		planet.h2o += this.h2o;
		planet.deadBiomass += this.deadBiomass;

		planet.albedoSum += this.albedo;
		planet.temperatureSum += this.temperature;

		if (this.temperature > planet.maxTemperature) { planet.maxTemperature = this.temperature; }
		if (this.temperature < planet.minTemperature) { planet.minTemperature = this.temperature; }
		
		foreach (ref sp; _species) {
			if (!(sp.speciesId in planet.species)) {
				planet.species[sp.speciesId] = 0;
			}
			planet.species[sp.speciesId] += sp.biomass.get();
		}

	}

}
