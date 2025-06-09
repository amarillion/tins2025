module startSpecies;

import std.random;
import species;

void initRandomLook(ref SpeciesInfo species) {
	species.layers = [uniform(0, 8), uniform(0, 8), uniform(0, 8), uniform(0, 8)],
	// random pastel colors
	species.hue1 = uniform(0, 360);
	species.hue2 = uniform(0, 360);
}

SpeciesInfo[] initStartSpecies() {
	// TODO better read from JSON perhaps?
	SpeciesInfo[] START_SPECIES = [
		SpeciesInfo( // 0
			"Plant 0",
			12,
			0x69F0AE,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			1.0, // 1.0 = light & early game 0.0 == dark & late game
			[ 225, 255 ], // min, max temperature in Kelvin
`An ancient and strong unicellular plant, but perhaps not the most effective.

Will do well in the cooler early phase of the game.`,
			[ 0.1, 0.5, 0.5, 0.5, 0.5, 1.0, 0.1, 0.5 ]
		), 
		SpeciesInfo( // 1
			"Plant 1",
			4,
			0x388E3C,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.95, // 1.0 = light & early game 0.0 == dark & late game
			[ 235, 275 ], // min, max temperature in Kelvin
			
`Legends say that this plant microbe came from a great scientist. Sounds too funny to be true.

Will do well in the cooler early phase of terraformation.`,
			[ 1.0, 0.1, 0.5, 0.5, 0.5, 0.1, 0.5, 0.5 ]
		), SpeciesInfo( // 2
			"Herbivore 0",
			11,
			0xF8BBD0,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 230, 265 ], // min, max temperature in Kelvin
			
`A sweet but dangerous creature. Arghhh yarr! Watch yourself, be careful!

One of the hardiest herbivores that will survive in low temperatures.`,
			[ 1.0, 0.5, 0.5, 0.1, 0.5, 0.5, 0.1, 0.5 ]
		), SpeciesInfo( // 3
			"Fungus 1",
			13,
			0x8D6E63,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.95, // 1.0 = light & early game 0.0 == dark & late game
			[ 230, 270 ], // min, max temperature in Kelvin
			
`Recycle useful substances and return them to the circle of life. Sometimes it feels like a radio wave.

You'll need to introduce a decomposer like this one, otherwise dead organic material will pile up, and stifle the ecosystem.`,
			[ 0.5, 0.5, 1.0, 0.5, 1.0, 0.1, 0.1, 0.5 ]
		), SpeciesInfo( // 4
			"Microbe 1",
			1,
			0xFFFF00,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 250, 295 ], // min, max temperature in Kelvin
`The cow says Muuuu. This squishy creature does not say anything, it is a microbe. But sometimes...

This creature is a herbivore that can survive in moderately cold climates.`,
			[ 0.1, 1.0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5 ]
		), SpeciesInfo( // 5
			"Microbe 2",
			3,
			0x8C9EFF,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.5, // 1.0 = light & early game 0.0 == dark & late game
			[ 255, 305 ], // min, max temperature in Kelvin
`Inspired by space and ready for complexity, the bulbous mushroom! 

A useful decomposer in a moderately cold climate.`,
			[ 0.5, 0.1, 0.1, 0.9, 0.9, 0.5, 0.5, 0.5 ]
		), SpeciesInfo( // 6
			"Catcrobe 2",
			9,
			0xBA68C8,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 2: INTERACTION.EAT, 3: INTERACTION.EAT, 4: INTERACTION.EAT, 5: INTERACTION.EAT, 9: INTERACTION.EAT, 10: INTERACTION.EAT, 11: INTERACTION.EAT ],
			0.3, // 1.0 = light & early game 0.0 == dark & late game
			[ 255, 305 ], // min, max temperature in Kelvin
`This is a cat? Is it a microbe? This is a catcrobe! Micro meow!

This carnivorous microbe will attack and eat other microbes.`,
			[ 0.5, 0.1, 0.1, 0.5, 0.9, 0.9, 0.5, 0.5 ]
		), SpeciesInfo( // 7
			"Plant 2",
			6,
			0x18FFFF,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.5, // 1.0 = light & early game 0.0 == dark & late game
			[ 260, 310 ], // min, max temperature in Kelvin
			
`The spiral concentrates the energy of the star and turns it into food for itself. And others.

This is a photosynthesizing organism, a plant species that can survive in moderately cold climates.`,
			[ 0.5, 0.1, 1.0, 0.5, 0.5, 0.5, 0.1, 0.5 ]
		), SpeciesInfo( // 8
			"Plant 3",
			7,
			0x76FF03,
			ROLE.PRODUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 280, 325 ], // min, max temperature in Kelvin
			
`Rise and Shine, Micro Pumpkin! Nutritious, but does not help to increase the temperature greatly.

Let this plant species cooperate with other microbes to boost its effect.`,
			[ 0.5, 0.5, 0.5, 0.5, 0.1, 0.9, 0.5, 0.5 ]
		), SpeciesInfo( // 9
			"Microbe 3",
			8,
			0xBBDEFB,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 0: INTERACTION.EAT, 1: INTERACTION.EAT, 7: INTERACTION.EAT, 8: INTERACTION.EAT ],
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 275, 325 ], // min, max temperature in Kelvin
			
`As we all know, bats are cool and dangerous. Therefore, even single-celled bats can eat whatever they want.

This creature is a herbivore for temperate climes.`,
			[ 0.1, 0.1, 1.0, 0.5, 0.5, 0.9, 0.9, 0.5 ]
		), SpeciesInfo( // 10
			"Donut 1",
			5,
			0xFF8F00,
			ROLE.REDUCER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			null,
			0.7, // 1.0 = light & early game 0.0 == dark & late game
			[ 285, 330 ], // min, max temperature in Kelvin
			
`Circle of life! Or a death donut? This mushroom combines immiscible.

A decomposer in temperate climates.`,
			[ 0.2, 0.5, 0.5, 0.5, 0.8, 0.5, 0.5, 0.5 ]
		), SpeciesInfo( // 11
			"Angry 1",
			10,
			0xFF3D00,
			ROLE.CONSUMER, // one of ROLE.PRODUCER, ROLE.CONSUMER, ROLE.REDUCER
			[ 2: INTERACTION.EAT, 3: INTERACTION.EAT, 4: INTERACTION.EAT, 5: INTERACTION.EAT, 6: INTERACTION.EAT, 9: INTERACTION.EAT, 10: INTERACTION.EAT ],
			0.8, // 1.0 = light & early game 0.0 == dark & late game
			[ 290, 330 ], // min, max temperature in Kelvin
			
	`DO NOT JOKE WITH THIS MICRO BLOB TERMINATOR!!!`,
			[ 0.1, 0.1, 0.2, 1.0, 0.8, 0.9, 0.9, 0.1 ]
		)
	];
	assert(START_SPECIES.length == START_SPECIES_NUM, "START_SPECIES array must have exactly START_SPECIES_NUM elements");

	foreach (ref species; START_SPECIES) {
		initRandomLook(species);
	}

	return START_SPECIES;
}