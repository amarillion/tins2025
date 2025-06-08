module planet;

import species;
import std.format;

// this just holds the calculated properties of our planet, such as average temperature, etc.

class Planet {

	this() {
		// summary stats...
		this.reset();
	}

	double temperature = 0; // in K
	double maxTemperature = 0;
	double minTemperature = double.infinity;
	double co2 = 0;
	double o2 = 0;
	double h2o = 0;
	double deadBiomass = 0;
	double[long] species; // biomass by species id
	
	double temperatureSum = 0;
	double albedoSum = 0;
	double albedo = 0;

	void reset() {
		temperature = 0; // in K
		maxTemperature = 0;
		minTemperature = double.infinity;
		co2 = 0;
		o2 = 0;
		h2o = 0;
		deadBiomass = 0;
		species = null;
		
		temperatureSum = 0;
		albedoSum = 0;
		albedo = 0;
	}

	string speciesToString() {
		char[] result;
		foreach (speciesId, biomass; species) {
			result ~= format("%s %g\n  ", speciesId, biomass);
		}
		return result.idup;
	}

	// string representation of cell...
	override string toString() {
		return format!`Average Temperature: %.0f °K
Lowest Temperature: %.0f °K
Highest Temperature: %.0f °K

Average albedo: %.2f

CO₂: %.1f
H₂O: %.1f
O₂: %.1f
Organic: %.1f

Species: %s`
		(temperature, minTemperature, maxTemperature, albedo,
		co2, h2o, o2, deadBiomass, speciesToString);
	}


}