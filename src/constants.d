module constants;

// mostly for simulation parameters

enum MAX_SPECIES_PER_CELL = 8;

enum PHOTOSYNTHESIS_BASE_RATE = 1.5e-8; // rate per mol substrate, per mol organism per GJ of solar energy
enum REDUCTION_BASE_RATE = 1.0e-4; // rate per mol substrate, per mol organism
enum CONSUMPTION_BASE_RATE = 2.0e-4; // rate per mol substrate, per mol organism
enum RESPIRATION_BASE_RATE = 1.0e-4; // rate per mol substrate, per mol organism
enum MIGRATION_BASE_RATE = 0.8e-2;
enum DEATH_RATE = 1.0e-3; // percentage death per turn. will be modified by fitness factor
enum SPECIES_MINIMUM = 0.1; // minimum presence before a species is removed altogether

enum START_CO2 = 1000.0; // starting amount of CO2 per km^2, in GMol
enum START_H2O = 1000.0; // starting amount of H2O per km^2, in GMol

enum START_HEAT = 2.2e2; // in GJ per km^2 (= cell area)
enum SURFACE_HEAT_CAPACITY = 1.0e0; // base thermal capacity of planetary surface, in GJ/K

// due to the effect of feedback loops, this number is actually very sensitive
enum MAX_STELLAR_HEAT_IN = 10e0; // heat added by the star in GJ per km^2 at the equator

enum CO2_BOILING_POINT = 216.0;
enum H2O_MELTING_POINT = 273.0;

// GUI parameters
enum TILESIZE = 64;
enum MAP_HEIGHT = 10;
enum MAP_WIDTH = 20;
enum NUM_BIOTOPES = 8;