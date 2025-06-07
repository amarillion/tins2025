module species;

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