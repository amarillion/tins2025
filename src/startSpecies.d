module startSpecies;

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
	string iconUrl;
	string coverArt;
	int tileIdx;
	uint color;
	ROLE role;
	INTERACTION[long] interactionMap;
	double albedo;
	double[2] temperatureRange;
	string backstory;
	float[int] biotopeTolerances;
}

SpeciesInfo[] START_SPECIES = null;

void initStartSpecies() {
	// TODO better read from JSON perhaps?
	START_SPECIES = [
		SpeciesInfo( // 0
			"Plant 0",
			"plant0",
			"platn_intro2",
			12,
			0x69F0AE,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			1.0, // 1.0 = light & early game 0.0 == dark & late game
			[ 225, 255 ], // min, max temperature in Kelvin
`An ancient and strong unicellular plant, but perhaps not the most effective.

Will do well in the cooler early phase of the game.`,
			[ 0: 0.1, 1: 0.5, 2: 0.5, 3: 0.5, 4: 0.5, 5: 1.0, 6: 0.1, 7: 0.5 ]
		), 
		SpeciesInfo( // 1
			"Plant 1",
			"plant1",
			"platn_intro1",
			4,
			0x388E3C,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.95, // 1.0 = light & early game 0.0 == dark & late game
			[ 235, 275 ], // min, max temperature in Kelvin
			
`Legends say that this plant microbe came from a great scientist. Sounds too funny to be true.

Will do well in the cooler early phase of terraformation.`,
			[ 0: 1.0, 1: 0.1, 2: 0.5, 3: 0.5, 4: 0.5, 5: 0.1, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 2
			"Herbivore 0",
			"herbivore0",
			"herbivore_intro0",
			11,
			0xF8BBD0,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 230, 265 ], // min, max temperature in Kelvin
			
`A sweet but dangerous creature. Arghhh yarr! Watch yourself, be careful!

One of the hardiest herbivores that will survive in low temperatures.`,
			[ 0: 1.0, 1: 0.5, 2: 0.5, 3: 0.1, 4: 0.5, 5: 0.5, 6: 0.1, 7: 0.5 ]
		), SpeciesInfo( // 3
			"Fungus 1",
			"fungi1",
			"fungi_intro0",
			13,
			0x8D6E63,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.95, // 1.0 = light & early game 0.0 == dark & late game
			[ 230, 270 ], // min, max temperature in Kelvin
			
`Recycle useful substances and return them to the circle of life. Sometimes it feels like a radio wave.

You'll need to introduce a decomposer like this one, otherwise dead organic material will pile up, and stifle the ecosystem.`,
			[ 0: 0.5, 1: 0.5, 2: 1.0, 3: 0.5, 4: 1.0, 5: 0.1, 6: 0.1, 7: 0.5 ]
		), SpeciesInfo( // 4
			"Microbe 1",
			"microb1",
			"microb_intro1",
			1,
			0xFFFF00,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 250, 295 ], // min, max temperature in Kelvin
`The cow says Muuuu. This yellow creature does not say anything, it is a microbe. But sometimes...

This creature is a herbivore that can survive in moderately cold climates.`,
			[ 0: 0.1, 1: 1.0, 2: 0.5, 3: 0.5, 4: 0.5, 5: 0.5, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 5
			"Microbe 2",
			"microb2",
			"microb_intro5",
			3,
			0x8C9EFF,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.5, // 1.0 = light & early game 0.0 == dark & late game
			[ 255, 305 ], // min, max temperature in Kelvin
`Inspired by space and ready for complexity, the purple mushroom! 

A useful decomposer in a moderately cold climate.`,
			[ 0: 0.5, 1: 0.1, 2: 0.1, 3: 0.9, 4: 0.9, 5: 0.5, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 6
			"Catcrobe 2",
			"catcrobe2",
			"catcrobe_intro2",
			9,
			0xBA68C8,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 2: INTERACTION.EAT, 3: INTERACTION.EAT, 4: INTERACTION.EAT, 5: INTERACTION.EAT, 9: INTERACTION.EAT, 10: INTERACTION.EAT, 11: INTERACTION.EAT ],
			0.3, // 1.0 = light & early game 0.0 == dark & late game
			[ 255, 305 ], // min, max temperature in Kelvin
`This is a cat? Is it a microbe? This is a catcrobe! Micro meow!

This carnivorous microbe will attack and eat other microbes.`,
			[ 0: 0.5, 1: 0.1, 2: 0.1, 3: 0.5, 4: 0.9, 5: 0.9, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 7
			"Plant 2",
			"microb4",
			"microb_intro4",
			6,
			0x18FFFF,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.5, // 1.0 = light & early game 0.0 == dark & late game
			[ 260, 310 ], // min, max temperature in Kelvin
			
`The spiral concentrates the energy of the star and turns it into food for itself. And others.

This is a photosynthesizing organism, a plant species that can survive in moderately cold climates.`,
			[ 0: 0.5, 1: 0.1, 2: 1.0, 3: 0.5, 4: 0.5, 5: 0.5, 6: 0.1, 7: 0.5 ]
		), SpeciesInfo( // 8
			"Plant 3",
			"microb5",
			"microb_intro2",
			7,
			0x76FF03,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 280, 325 ], // min, max temperature in Kelvin
			
`Rise and Shine, Micro Pumpkin!  Nutritious, but does not help to increase the temperature greatly.

Let this plant species cooperate with other microbes to boost its effect.`,
			[ 0: 0.5, 1: 0.5, 2: 0.5, 3: 0.5, 4: 0.1, 5: 0.9, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 9
			"Microbe 3",
			"microb3",
			"microb_intro7",
			8,
			0xBBDEFB,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 275, 325 ], // min, max temperature in Kelvin
			
`As we all know, bats are cool and dangerous. Therefore, even single-celled bats can eat whatever they want.

This creature is a herbivore for temperate climes.`,
			[ 0: 0.1, 1: 0.1, 2: 1.0, 3: 0.5, 4: 0.5, 5: 0.9, 6: 0.9, 7: 0.5 ]
		), SpeciesInfo( // 10
			"Donut 1",
			"donut1",
			"donut_intro1",
			5,
			0xFF8F00,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 285, 330 ], // min, max temperature in Kelvin
			
`Circle of life! Or a death donut? This mushroom combines immiscible.

A decomposer in temperate climates.`,
			[ 0: 0.2, 1: 0.5, 2: 0.5, 3: 0.5, 4: 0.8, 5: 0.5, 6: 0.5, 7: 0.5 ]
		), SpeciesInfo( // 11
			"Angry 1",
			"angry1",
			"angry_intro1",
			10,
			0xFF3D00,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 2: INTERACTION.EAT, 3: INTERACTION.EAT, 4: INTERACTION.EAT, 5: INTERACTION.EAT, 6: INTERACTION.EAT, 9: INTERACTION.EAT, 10: INTERACTION.EAT ],
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 290, 330 ], // min, max temperature in Kelvin
			
	`DO NOT JOKE WITH THIS MICRO RED TERMINATOR!!!`,
			[ 0: 0.1, 1: 0.1, 2: 0.2, 3: 1.0, 4: 0.8, 5: 0.9, 6: 0.9, 7: 0.1 ]
		)

	];
}