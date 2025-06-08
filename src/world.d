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
import renderSpecies;
import startSpecies;

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

vec3f[] transformVertices(in vec3f[] vertBuf, ALLEGRO_TRANSFORM t) {
	vec3f[] result = vertBuf.dup;;
	for (int i = 0; i < vertBuf.length; i++) {
		float x = vertBuf[i].x, y = vertBuf[i].y, z = vertBuf[i].z; 
		al_transform_coordinates_3d(&t, &x, &y, &z);
		result[i] = vec3f(x, y, z);
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

		int textureIndex = i % 8;

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
		vertices[v + 0].u = textureIndex * 64; vertices[v + 0].v = 0;
		vertices[v + 1].u = textureIndex * 64 + 64; vertices[v + 1].v = 0;
		vertices[v + 2].u = textureIndex * 64; vertices[v + 2].v = 64;

		v += 3; // next triangle
	}
	al_draw_prim(&vertices, null, obj.texture.ptr, 0, v - 3, ALLEGRO_PRIM_TYPE.ALLEGRO_PRIM_TRIANGLE_LIST);
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
	CameraController cameraControl;
	Bitmap speciesTexture;
	RenderSpecies renderSpecies;

	this(MainLoop window) {
		super(window, "world");
		this.initResources();
		cameraControl = new CameraController(window, this);
		renderSpecies = new RenderSpecies(window);

		auto meshData = generateFibonacciSpehereMesh(numPoints);
		Object3D obj = Object3D(meshData,
			vec3f(0, 0, 0), // position 
			vec3f(400, 400, 400), // scale
			0, // angle 
			window.resources.bitmaps["biotope"]
		);

		this.objects = [ obj ];
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

		foreach(obj; objects) {
			drawObject(obj, cameraTransform);
		}

		// this.renderAllSpecies();
		al_reset_clipping_rectangle();
	}

	int numPoints = 1024;

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