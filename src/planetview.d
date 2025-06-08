module planetview;

import helix.component;
import helix.util.grid;
import helix.tilemap;
import helix.util.coordrange;
import helix.util.vec;
import helix.mainloop;
import helix.signal;
import helix.color;

import allegro5.allegro;
import allegro5.allegro_primitives;

class PlanetView : Component {

	this(MainLoop window) {
		super(window, "default");
	}

	TileMap planetMap;
	TileMap speciesMap;
	Model!Point selectedTile;

	override void draw(GraphicsContext gc) {
		Point ofst = Point(0);
		draw_tilemap(planetMap, shape, ofst);
		draw_tilemap(speciesMap, shape, ofst);
		draw_tilemap(speciesMap, shape, ofst, 1);
		
		Point p = selectedTile.get();
		Point p1 = p * 64;
		Point p2 = p1 + 64;
		al_draw_rectangle(p1.x, p1.y, p2.x, p2.y, Color.WHITE, 1.0);
	}

	override void onMouseDown(Point p) {
		Point mp = p / 64;
		if (planetMap.layers[0].inRange(mp)) {
			selectedTile.set(mp);
		}
	}

}