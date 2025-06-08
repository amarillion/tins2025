module world;

import helix.component;
import helix.util.vec;
import helix.mainloop;
import helix.allegro.bitmap;
import allegro5.allegro;
import allegro5.allegro_primitives;
import allegro5.allegro_color;
import primitives3d;
import std.stdio;
import std.conv;
import mesh;
import helix.color;
import helix.allegro.shader;
import renderSpecies;
import startSpecies;
import sphereGrid;
import helix.signal;
import util3d;
import std.math;
import cell;

class Object3D {
	vec3f position;
	vec3f scale;
	double rotation; // in radians
	Bitmap texture;
	Mesh mesh;
	int[] faceTextures;
	int selectedFace;

	this(Mesh mesh, vec3f position, vec3f scale, double rotation, Bitmap texture, int[] faceTextures) {
		this.mesh = mesh;
		this.position = position;
		this.scale = scale;
		this.rotation = rotation;
		this.texture = texture;
		this.faceTextures = faceTextures;
		assert (mesh.faces.length == faceTextures.length, "Number of faces and face textures must match");
	}
}

void drawHeatmap(ref Object3D obj, ref ALLEGRO_TRANSFORM cameraTransform, SphereGrid grid, ALLEGRO_COLOR delegate(Cell) colorFunc) {
	assert(grid !is null);

	ALLEGRO_TRANSFORM t;
	al_identity_transform(&t);
	al_scale_transform_3d(&t, obj.scale.x, obj.scale.y, obj.scale.z);
	al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, obj.rotation);
	al_translate_transform_3d(&t, obj.position.x, obj.position.y, obj.position.z);

	al_compose_transform(&t, &cameraTransform); // compose with camera transform

	vec3f[] vertBuf = transformVertices(obj.mesh.vertices, t);

	enum VERTEX_BUFFER_SIZE = 8192;
	ALLEGRO_VERTEX[VERTEX_BUFFER_SIZE] vertices;
	assert(VERTEX_BUFFER_SIZE > obj.mesh.faces.length * 3, "Vertex buffer size is too small for the number of faces");

	int v = 0;
	for (int i = 0; i < obj.mesh.faces.length; i++) {
		int[] face = obj.mesh.faces[i];
		
		// TODO: move to Mesh/Face
		vec3f normal = (vertBuf[face[1]] - vertBuf[face[0]]).crossProductVector(vertBuf[face[2]] - vertBuf[face[0]]);
		
		if (normal.z < 0) {
			continue; // skip back faces
		}

		ALLEGRO_COLOR color = colorFunc(grid.getCell(i));

		for(int j = 0; j < 3; j++) {
			vertices[v + j].x = vertBuf[face[j]].x;
			vertices[v + j].y = vertBuf[face[j]].y;
			vertices[v + j].z = 0; //vertBuf[face[j]].position.z; TODO: something goes wrong here. Depth buffer?

			vertices[v + j].color = color;
		}

		v += 3; // next triangle
	}
	al_draw_prim(&vertices, null, null, 0, v, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);

}

void drawObject(ref Object3D obj, ref ALLEGRO_TRANSFORM cameraTransform) {	
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
	
	vec3f lightDir = vec3f(-lx, -ly, -lz).normalize(); // direction from object to light source
	
	vec3f[] vertBuf = transformVertices(obj.mesh.vertices, t);
	
	enum VERTEX_BUFFER_SIZE = 8192;
	ALLEGRO_VERTEX[VERTEX_BUFFER_SIZE] vertices;
	assert(VERTEX_BUFFER_SIZE > obj.mesh.faces.length * 3, "Vertex buffer size is too small for the number of faces");
	
	int v = 0;
	
	for (int i = 0; i < obj.mesh.faces.length; i++) {
		int[] face = obj.mesh.faces[i];
		// calculate light from angle of normal vector of face with light source
		
		// TODO: move to Mesh/Face
		vec3f normal = (vertBuf[face[1]] - vertBuf[face[0]]).crossProductVector(vertBuf[face[2]] - vertBuf[face[0]]);
		
		if (normal.z < 0) {
			continue; // skip back faces
		}

		// TODO: move normalize function to utility class
		double light = 0.3 + 0.7 * normal.dotProduct(lightDir) / (normal.length() * lightDir.length());

		int textureIndex = obj.faceTextures[i] % 8;

		for(int j = 0; j < 3; j++) {
			vertices[v + j].x = vertBuf[face[j]].x;
			vertices[v + j].y = vertBuf[face[j]].y;
			vertices[v + j].z = 0; //vertBuf[face[j]].position.z; TODO: something goes wrong here. Depth buffer?

			// the following leads to merged / overwritten tex coords
			// vertices[v + j].u = vertBuf[face[j]].texCoord.x;
			// vertices[v + j].v = vertBuf[face[j]].texCoord.y;
			vertices[v + j].color = al_map_rgb_f(light, light, light); // set color based on light intensity
		}

		// hard-resetting texture coords for each triangle
		// we will need to do away with shared vertices if we want to make this more efficient
		if (i % 2 == 0) { // take opposite triangles half the time...
			vertices[v + 0].u = textureIndex * 64; vertices[v + 0].v = 0;
			vertices[v + 1].u = textureIndex * 64 + 64; vertices[v + 1].v = 0;
			vertices[v + 2].u = textureIndex * 64 + 64; vertices[v + 2].v = 64;
		}
		else {
			vertices[v + 0].u = textureIndex * 64; vertices[v + 0].v = 64;
			vertices[v + 1].u = textureIndex * 64; vertices[v + 1].v = 0;
			vertices[v + 2].u = textureIndex * 64 + 64; vertices[v + 2].v = 64;
		}

		v += 3; // next triangle
	}
	al_draw_prim(&vertices, null, obj.texture.ptr, 0, v, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);

	// draw a triangle around selected face
	if (obj.selectedFace >= 0 && obj.selectedFace < obj.mesh.faces.length) {
		int[] face = obj.mesh.faces[obj.selectedFace];
		vec3f normal = (vertBuf[face[1]] - vertBuf[face[0]]).crossProductVector(vertBuf[face[2]] - vertBuf[face[0]]);
		
		if (normal.z >= 0) {
			vec3f v0 = vertBuf[face[0]];
			vec3f v1 = vertBuf[face[1]];
			vec3f v2 = vertBuf[face[2]];

			al_draw_triangle(
				v0.x, v0.y, 
				v1.x, v1.y, 
				v2.x, v2.y, 
				Color.YELLOW,
				2.0 // line thickness
			);
		}
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

class World : Component {

	Bitmap texture;
	Object3D[] objects;
	Object3D planet;
	CameraController cameraControl;
	Bitmap speciesTexture;
	RenderSpecies renderSpecies;
	SphereGrid sphereGrid;
	Sprite[] sprites;

	this(MainLoop window, ref Mesh meshData, SphereGrid sphereGrid) {
		super(window, "world");
		this.initResources();
		cameraControl = new CameraController(window, this);
		renderSpecies = new RenderSpecies(window);

		// copy texture indexes from faceGrid;
		int[] faceTextures = new int[meshData.faces.length];
		for (int i = 0; i < meshData.faces.length; i++) {
			faceTextures[i] = (sphereGrid.getCell(i).biotope) % 8;
		}

		planet = new Object3D(meshData,
			vec3f(0, 0, 0), // position 
			vec3f(400, 400, 400), // scale
			0, // angle 
			window.resources.bitmaps["biotope"],
			faceTextures
		);

		this.objects = [ planet ];
		this.sphereGrid = sphereGrid;

		selectedFace.onChange.add((e) {
			planet.selectedFace = e.newValue;
		});
	}

	void renderAllSpecies() {
		renderSpecies.startRender();
		for (int i = 0; i < START_SPECIES.length; i++) {
			int x = (i % 48) * 32 + 10;
			int y = (i / 48) * 32 + 10;
			renderSpecies.renderSpecies(
				START_SPECIES[i], 
				x, y, 
				0.5, // scale
				counter // timer
			);
		}
		renderSpecies.endRender();
	}

	final void initResources() {
		texture = window.resources.bitmaps["biotope"];
		speciesTexture = window.resources.bitmaps["Bacteria"];
	}

	override void draw(GraphicsContext gc) {
		al_clear_depth_buffer(1000);
		al_set_clipping_rectangle(this.x, this.y, this.w, this.h);
		
		ref ALLEGRO_TRANSFORM cameraTransform = cameraControl.getTransform();

		if (showAlbedoMap) {
			drawHeatmap(planet, cameraTransform, sphereGrid, (Cell cell) {
				float albedo = cell.albedo * 1.6 - 0.4; // scale up a bit
				if (albedo < 0) albedo = 0;
				if (albedo > 1) albedo = 1;
				return al_map_rgb_f(albedo, albedo, albedo); // grayscale based on albedo
			});
		}
		else if (showHeatmap) {
			drawHeatmap(planet, cameraTransform, sphereGrid, (Cell cell) {
				double temp = cell.temperature;
				double hue = (330 - temp) / 200.0 * 360.0;
				if (hue < 0) hue = 0;
				if (hue > 360) hue = 360;
				return al_color_hsv(hue, 1.0, 0.5); 
			});
		}
		else {
			foreach(obj; objects) {
				drawObject(obj, cameraTransform);
			}

			// TODO: redundant code, move to Object3D
			ALLEGRO_TRANSFORM t;
			al_identity_transform(&t);
			al_scale_transform_3d(&t, planet.scale.x, planet.scale.y, planet.scale.z);
			al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, planet.rotation);
			al_translate_transform_3d(&t, planet.position.x, planet.position.y, planet.position.z);

			al_compose_transform(&t, &cameraTransform); // compose with camera transform

			renderSpecies.renderSprites(START_SPECIES, sprites, planet.mesh, t, counter, cameraControl.camera.zoom);
		}

		// this.renderAllSpecies();
		al_reset_clipping_rectangle();
	}

	int counter;
	override void update() {

		counter++;

		planet.rotation += 0.0005;
		if (planet.rotation > 2 * PI) {
			planet.rotation -= 2 * PI;
		}
	}

	Model!int selectedFace;

	public override bool onKey(int code, int c, int mod) {
		if (code == ALLEGRO_KEY_TAB) {
			import std.random : uniform;
			selectedFace.set(to!int(uniform(0, planet.mesh.faces.length)));
			return true;
		}
		return cameraControl.onKey(code, c, mod);
	}

	override void onMouseDown(Point p) {
		// pick one at random for now.
		// import std.random : uniform;
		// planet.selectedFace = to!int(uniform(0, planet.mesh.faces.length));
		// selectedFace.set(planet.selectedFace);

		// get planet transform
		// TODO: copied code

		ALLEGRO_TRANSFORM t;
		al_identity_transform(&t);
		al_scale_transform_3d(&t, planet.scale.x, planet.scale.y, planet.scale.z);
		al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, planet.rotation);
		al_translate_transform_3d(&t, planet.position.x, planet.position.y, planet.position.z);
		ALLEGRO_TRANSFORM cameraTransform = cameraControl.getTransform();
		al_compose_transform(&t, &cameraTransform); // compose with camera transform

		vec3f[] vertBuf = transformVertices(planet.mesh.vertices, t);
		// find face under mouse
		for (int i = 0; i < planet.mesh.faces.length; i++) {
			int[] face = planet.mesh.faces[i];

			vec3f normal = (vertBuf[face[1]] - vertBuf[face[0]]).crossProductVector(vertBuf[face[2]] - vertBuf[face[0]]);			
			if (normal.z < 0) {
				continue; // skip back faces
			}

			vec2f v0 = vec2f(vertBuf[face[0]].x, vertBuf[face[0]].y);
			vec2f v1 = vec2f(vertBuf[face[1]].x, vertBuf[face[1]].y);
			vec2f v2 = vec2f(vertBuf[face[2]].x, vertBuf[face[2]].y);

			// check if point is inside triangle
			if (pointInTriangle(vec2f(p.x, p.y), v0, v1, v2)) {
				planet.selectedFace = i;
				selectedFace.set(planet.selectedFace);
				return;
			}
		}


	}

	bool showHeatmap;
	void toggleHeatmap() {
		showHeatmap = !showHeatmap;
		if (showHeatmap) {
			showAlbedoMap = false;
		}
	}

	bool showAlbedoMap;
	void toggleAlbedoOverlay() {
		showAlbedoMap = !showAlbedoMap;
		if (showAlbedoMap) {
			showHeatmap = false;
		}
	}

}

bool pointInTriangle(vec2f P, vec2f A, vec2f B, vec2f C) {
	// Barycentric coordinates method
	// Compute vectors
	vec2f v0 = C - A;
	vec2f v1 = B - A;
	vec2f v2 = P - A;

	// Compute dot products
	float dot00 = v0.dotProduct(v0);
	float dot01 = v0.dotProduct(v1);
	float dot02 = v0.dotProduct(v2);
	float dot11 = v1.dotProduct(v1);
	float dot12 = v1.dotProduct(v2);

	// Compute barycentric coordinates
	float denom = dot00 * dot11 - dot01 * dot01;
	if (denom == 0.0) return false; // Degenerate triangle

	float invDenom = 1.0 / denom;
	float u = (dot11 * dot02 - dot01 * dot12) * invDenom;
	float v = (dot00 * dot12 - dot01 * dot02) * invDenom;

	// Check if point is in triangle
	return (u >= 0) && (v >= 0) && (u + v <= 1);
}

unittest {
	import std.stdio;
	import std.math;

	// Test pointInTriangle
	assert(!pointInTriangle(vec2f(1, 1),    vec2f(0, 1), vec2f(1, 0), vec2f(0, 0)));
	assert(pointInTriangle(vec2f(0.2, 0.2), vec2f(0, 1), vec2f(1, 0), vec2f(0, 0)));
}