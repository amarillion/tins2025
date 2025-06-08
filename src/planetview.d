module planetview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;
import helix.mainloop;
import helix.signal;
import helix.color;
import helix.util.box;

import allegro5.allegro;
import allegro5.allegro_primitives;
import renderSpecies;
import startSpecies;

class PlanetView : Component {

	this(MainLoop window) {
		super(window, "default");
		renderSpecies = new RenderSpecies(window);
	}

	TileMap speciesMap;
	Model!Point selectedTile;
	RenderSpecies renderSpecies;
	
	// TODO: allow passing render function to generic draw function
	void drawSpeciesMap(TileMap tilemap, Rect!int shape, Point viewPos) {
		renderSpecies.startRender();

		int layer = 0;

		assert(tilemap.layers[layer]);
		assert(tilemap.tilelist.bmp);

		void tileHelper(int index, int x, int y)
		{
			assert (index >= 0);
			renderSpecies.renderSpecies(
				START_SPECIES[index % 12], 
				x, 
				y, 
				0.5, 
				counter
			);
		}

		// idem as teg_draw, but only a part of the target bitmap will be drawn.
		// x, y, w and h are relative to the target bitmap coordinates
		// xview and yview are relative to the target bitmap (0,0), not to (x,y)
		// void teg_partdraw (const TEG_MAP* map, int layer, int cx, int cy, int cw, int ch, int xview, int yview)

		int ox, oy, ow, oh;
		
		// TODO: setting clipping should maybe be built into the Component system...
		al_get_clipping_rectangle(&ox, &oy, &ow, &oh);

		Rect!int area = shape.intersection(Rect!int(ox, oy, ow, oh));
		al_set_clipping_rectangle(area.x, area.y, area.w, area.h);
		
		const tileSize = Point(tilemap.tilelist.tilew, tilemap.tilelist.tileh);
		foreach (tilePos; PointRange(tilemap.layers[layer].size)) {
			Point pixelPos = tilePos * tileSize - viewPos;

			int i = tilemap.layers[layer][tilePos];
			if (i >= 0 && i < tilemap.tilelist.tilenum) {
				tileHelper(i, pixelPos.x, pixelPos.y);
			}
		}

		al_set_clipping_rectangle(ox, oy, ow, oh);

		renderSpecies.endRender();
	}
	
	int counter = 0;
	override void update() {
		counter++;
	}

	override void draw(GraphicsContext gc) {
		Point ofst = Point(0);
		drawSpeciesMap(speciesMap, shape, ofst);
		draw_tilemap(speciesMap, shape, ofst, 1);

		// draw cursor
		Point p = selectedTile.get();
		Point p1 = p * 64;
		Point p2 = p1 + 64;
		al_draw_rectangle(p1.x, p1.y, p2.x, p2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		Point mp = p / 64;
		if (speciesMap.layers[0].inRange(mp)) {
			selectedTile.set(mp);
		}
	}

}