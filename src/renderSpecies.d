module renderSpecies;

import helix.mainloop;
import helix.allegro.shader;
import core.internal.container.common;
import helix.allegro.bitmap;
import startSpecies;
import allegro5.allegro;
import allegro5.allegro_color;
import helix.util.vec;
import std.conv;
import mesh;
import util3d;
import giftwrap;

alias Face = int[3];

struct Sprite {
	int faceId;
	int speciesId;
	int changeTile;
	int localIdx;
}

class RenderSpecies {

	this(MainLoop window) {
		speciesTexture = window.resources.bitmaps["Bacteria"];
		shader = shader.ofFragment(window.resources.shaders["color-replace"]);

	}

	void startRender() {
		setter = shader.use(true);
	}
	
	void renderSpecies(in SpeciesInfo species, int x, int y, double scale, int timer) {
		int delta = (timer % 60 < 30) ? 8 : 0;
		
		// TODO: cache hsv mapped values
		ALLEGRO_COLOR color1 = al_color_hsv(species.hue1, 0.5, 1.0);
		ALLEGRO_COLOR color2 = al_color_hsv(species.hue2, 0.5, 1.0);

		// TODO: add function setter.withColor
		setter.withVec3f("red_replacement", vec!(3, float)(color1.r, color1.g, color1.b));
		setter.withVec3f("green_replacement", vec!(3, float)(color2.r, color2.g, color2.b));

		int destSize = to!int(64.0 * scale);
		al_draw_scaled_bitmap(speciesTexture.ptr, (species.layers[0] + delta) * 64, 192, 64, 64, x, y, destSize, destSize, 0);
		al_draw_scaled_bitmap(speciesTexture.ptr, (species.layers[1] + delta) * 64, 0, 64, 64, x, y,   destSize, destSize, 0);
		al_draw_scaled_bitmap(speciesTexture.ptr, (species.layers[2] + delta) * 64, 64, 64, 64, x, y,  destSize, destSize, 0);
		al_draw_scaled_bitmap(speciesTexture.ptr, (species.layers[3] + delta) * 64, 128, 64, 64, x, y, destSize, destSize, 0);
	}

	void endRender() {
		shader.use(false);
	}

	Bitmap speciesTexture;
	Shader shader;
	Shader.UniformSetter setter;

	Bitmap renderSingleSpecies(ref SpeciesInfo species) {
		Bitmap bmp = Bitmap.create(64, 64);
		ALLEGRO_BITMAP *current = al_get_target_bitmap();
		al_set_target_bitmap(bmp.ptr);
		startRender();
		renderSpecies(species, 0, 0, 1.0, 0);
		endRender();
		al_set_target_bitmap(current);
		return bmp;
	}

	void renderSprites(in SpeciesInfo[] species, Sprite[] sprites, ref Mesh mesh, ref ALLEGRO_TRANSFORM transform, int timer) {
		startRender();

		// apply camera transform to face
		vec3f[] vertBuf = transformVertices(mesh.vertices, transform);

		foreach (sprite; sprites) {
			// get face
			int faceId = sprite.faceId;
			Face face = mesh.faces[faceId];

			vec3f normal = (vertBuf[face[1]] - vertBuf[face[0]]).crossProductVector(vertBuf[face[2]] - vertBuf[face[0]]);		
			if (normal.z < 0) {
				continue; // skip back faces
			}

			// get center of face
			vec!(3, float) center = (vertBuf[face[0]] + vertBuf[face[1]] + vertBuf[face[2]]) / 3.0;
			
			renderSpecies(species[sprite.speciesId], to!int(center.x), to!int(center.y), 1.0, timer);
		}
		endRender();
	}
}