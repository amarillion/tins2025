module world;

import helix.component;
import helix.util.vec;
import helix.mainloop;
import helix.allegro.bitmap;
import allegro5.allegro;
import allegro5.allegro_primitives;
import primitives3d;
import std.stdio;
import std.conv;
import mesh;
import helix.color;
import helix.allegro.shader;

struct NewSpecies {
	int[4] layers;
	ALLEGRO_COLOR color1;
	ALLEGRO_COLOR color2;
}

struct Object3D {
	vec3f position;
	vec3f scale;
	double rotation; // in radians
	Bitmap texture;
	Mesh mesh;

	this(Mesh mesh, vec3f position, vec3f scale, double rotation, Bitmap texture) {
		this.mesh = mesh;
		this.position = position;
		this.scale = scale;
		this.rotation = rotation;
		this.texture = texture;
	}
}

Vertex[] transformVertices(in Vertex[] vertBuf, ALLEGRO_TRANSFORM t) {
	Vertex[] result = new Vertex[vertBuf.length];
	for (int i = 0; i < vertBuf.length; i++) {
		float x = vertBuf[i].position.x, y = vertBuf[i].position.y, z = vertBuf[i].position.z; 
		al_transform_coordinates_3d(&t, &x, &y, &z);
		result[i] = Vertex(vec3f(x, y, z), vertBuf[i].texCoord);
	}
	return result;
}

void drawObject(Object3D obj, ref ALLEGRO_TRANSFORM cameraTransform) {
	
	ALLEGRO_TRANSFORM t;
	al_identity_transform(&t);
	al_scale_transform_3d(&t, obj.scale.x, obj.scale.y, obj.scale.z);
	al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, obj.rotation);
	al_translate_transform_3d(&t, obj.position.x, obj.position.y, obj.position.z);

	al_compose_transform(&t, &cameraTransform); // compose with camera transform

	vec3f lightSource = vec3f(0, 0, 1000); // light source position (above the object)
	
	// transform light source position with camera transform
	float lx = lightSource.x, ly = lightSource.y, lz = lightSource.z;
	al_transform_coordinates_3d(&cameraTransform, &lx, &ly, &lz);
	
	vec3f lightDir = vec3f(-lx, -ly, -lz);
	lightDir.normalize(); // direction from object to light source
	
	Vertex[] vertBuf = transformVertices(obj.mesh.vertices, t);

	for (int i = 0; i < obj.mesh.faces.length; i++) {
		int[] face = obj.mesh.faces[i];
		// calculate light from angle of normal vector of face with light source
		
		// TODO: move to Mesh/Face
		vec3f normal = (vertBuf[face[1]].position - vertBuf[face[0]].position).crossProductVector(vertBuf[face[2]].position - vertBuf[face[0]].position);
		
		if (normal.z < 0) {
			continue; // skip back faces
		}

		// TODO: move normalize function to utility class
		double light = 0.3 + 0.7 * normal.dotProduct(lightDir) / (normal.length() * lightDir.length());

		int[] indices = [0, 1, 2];

		ALLEGRO_VERTEX[3] vertices;
		int textureIndex = i % 8;

		for(int j = 0; j < 3; j++) {
			vertices[j].x = vertBuf[face[j]].position.x;
			vertices[j].y = vertBuf[face[j]].position.y;
			vertices[j].z = 0; //vertBuf[face[j]].position.z; TODO: something goes wrong here. Depth buffer?

			// the following leads to merged / overwritten tex coords
			// vertices[j].u = vertBuf[face[j]].texCoord.x;
			// vertices[j].v = vertBuf[face[j]].texCoord.y;
			vertices[j].color = al_map_rgb_f(light, light, light); // set color based on light intensity
		}

		// hard-resetting texture coords for each triangle
		// we will need to do away with shared vertices if we want to make this more efficient
		vertices[0].u = textureIndex * 64; vertices[0].v = 0;
		vertices[1].u = textureIndex * 64 + 64; vertices[1].v = 0;
		vertices[2].u = textureIndex * 64; vertices[2].v = 64;
		
		al_draw_prim(&vertices, null, obj.texture.ptr, 0, 4, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
	}
}

struct Camera {
	vec2f angle;
	float zoom;
}

class CameraController {

	this(MainLoop window, Component canvas) {
		this.camera = Camera(vec2f(0, 0), 1.0f); // initial camera position and distance
		this.canvas = canvas;
	}

	Camera camera;
	Component canvas;

	// cache
	private ALLEGRO_TRANSFORM t;

	ref ALLEGRO_TRANSFORM getTransform() {
		// move camera to 0,0,0, looking in from angle.x and angle.y
		al_identity_transform(&t);
		al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, camera.angle.x); // rotate around x-axis
		al_rotate_transform_3d(&t, 1.0f, 0.0f, 0.0f, camera.angle.y); // rotate around y-axis
		// al_translate_transform_3d(&t, 0.0f, 0.0f, -camera
		// 	vertices[0].x, vertices[0].y,
		// 	vertices[1].x, vertices[1].y,
		// 	vertices[2].x, vertices[2].y,
		// 	al_map_rgb(255, 0, 0), 2.0 // red color with line thickness of 2
		// );.distance);

		import std.math : tan, PI;
		float fov = tan(90 * PI / 180 / 2); // 90 degree field of view
		float zoom = camera.zoom; // enlarge x 2
		al_perspective_transform(&t,  
			-1 / zoom, 1 / zoom,
			1 / fov,
			1 / zoom, -1 / zoom,
			2000); // perspective projection

		// move to center of screen
		auto width = canvas.w();
		auto height = canvas.h();

		al_translate_transform_3d(&t, width / 2.0f, height / 2.0f, 0.0f);
		return t;
	}

	public bool onKey(int code, int c, int mod) {
		switch (code) {
			case ALLEGRO_KEY_A:
			case ALLEGRO_KEY_LEFT:
				camera.angle.x -= 0.1;
				return true;
			case ALLEGRO_KEY_D:
			case ALLEGRO_KEY_RIGHT:
				camera.angle.x += 0.1;
				return true;
			case ALLEGRO_KEY_W:
			case ALLEGRO_KEY_UP:
				camera.angle.y -= 0.1;
				return true;
			case ALLEGRO_KEY_S:
			case ALLEGRO_KEY_DOWN:
				camera.angle.y += 0.1;
				return true;
			case ALLEGRO_KEY_PAD_PLUS:
			case ALLEGRO_KEY_EQUALS:
			case ALLEGRO_KEY_PGUP:
				camera.zoom *= 1.1;
				return true;
			case ALLEGRO_KEY_PGDN:
			case ALLEGRO_KEY_MINUS:
			case ALLEGRO_KEY_PAD_MINUS:
				camera.zoom /= 1.1;
				return true;
			default:
				return false;
				break;
		}
		
	}

}

Object3D wrapWithTextures(Mesh mesh, Bitmap texture, vec3f position, vec3f scale, double rotation) {
	auto result = Object3D(mesh, position, scale, rotation, texture);
	enum NUM_TILES = 8;

	for (int i = 0; i < mesh.faces.length; i++) {
		// for each face, pick a random tile
		// and set the texture coordinates to the face vertices
		auto face = mesh.faces[i];
		int tileIndex = i % NUM_TILES; // simple tiling

		result.mesh.vertices[face[0]].texCoord = vec2f(64 * tileIndex, 0);
		result.mesh.vertices[face[1]].texCoord = vec2f(64 * tileIndex + 64, 0);
		result.mesh.vertices[face[2]].texCoord = vec2f(64 * tileIndex, 64); 
	}
	return result;
}

class World : Component {

	Bitmap texture;
	Object3D[] objects;
	CameraController cameraControl;
	Bitmap speciesTexture;

	this(MainLoop window) {
		super(window, "world");
		this.initResources();
		cameraControl = new CameraController(window, this);

		auto meshData = generateFibonacciSpehereMesh(numPoints);
		Object3D obj = wrapWithTextures(meshData, window.resources.bitmaps["biotope"],
			vec3f(0, 0, 0), // position 
			vec3f(400, 400, 400), // scale
			0, // angle 
		);

		this.objects = [ obj ];

		this.initSpecies();
	}

	NewSpecies[] species;

	void initSpecies() {
		import allegro5.allegro_color : al_color_hsv;
		import std.random : uniform;
		for (int i = 0; i < 512; i++) {
			NewSpecies newSpecies = NewSpecies(
				[uniform(0, 8), uniform(0, 8), uniform(0, 8), uniform(0, 8)],
				al_color_hsv(uniform(0, 360), 0.5, 1.0), // random pastel color
				al_color_hsv(uniform(0, 360), 0.5, 1.0), // random pastel color
			);
			species ~= newSpecies;
		}
	}

	void renderSpecies(in NewSpecies species, int x, int y, int timer, ref Shader.UniformSetter setter) {
		int delta = (timer % 60 < 30) ? 8 : 0;
		
		setter.withVec3f("red_replacement", vec!(3, float)(species.color1.r, species.color1.g, species.color1.b));
		setter.withVec3f("green_replacement", vec!(3, float)(species.color2.r, species.color2.g, species.color2.b));

		al_draw_bitmap_region(speciesTexture.ptr, (species.layers[0] + delta) * 64, 192, 64, 64, x, y, 0);
		al_draw_bitmap_region(speciesTexture.ptr, (species.layers[1] + delta) * 64, 0, 64, 64, x, y, 0);
		al_draw_bitmap_region(speciesTexture.ptr, (species.layers[2] + delta) * 64, 64, 64, 64, x, y, 0);
		al_draw_bitmap_region(speciesTexture.ptr, (species.layers[3] + delta) * 64, 128, 64, 64, x, y, 0);
	}

	Shader shader;
	void renderAllSpecies() {
		auto setter = shader.use(true);
		for (int i = 0; i < species.length; i++) {
			int x = (i % 32) * 64 + 10;
			int y = (i / 32) * 64 + 10;
			renderSpecies(species[i], x, y, counter + (i * 7), setter);
		}
		shader.use(false);
	}

	final void initResources() {
		texture = window.resources.bitmaps["biotope"];
		speciesTexture = window.resources.bitmaps["Bacteria"];
		shader = shader.ofFragment(window.resources.shaders["color-replace"]);
	}

	override void draw(GraphicsContext gc) {
		al_clear_depth_buffer(1000);
		al_set_clipping_rectangle(this.x, this.y, this.w, this.h);
		
		ref ALLEGRO_TRANSFORM cameraTransform = cameraControl.getTransform();

		foreach(obj; objects) {
			drawObject(obj, cameraTransform);
		}

		// this.renderAllSpecies();
		al_reset_clipping_rectangle();
	}

	int numPoints = 256;

	int counter;
	override void update() {

		counter++;
		// TODO: use animators
		foreach(ref obj; objects) {
			obj.rotation += 0.002; // Rotate each object for demonstration
		}
	}

	public override bool onKey(int code, int c, int mod) {
		return cameraControl.onKey(code, c, mod);
	}
}