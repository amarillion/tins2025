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

struct PointsObj {
	vec3f[] points;
	vec3f position;
	vec3f scale;
	double rotation; // in radians

	this(vec3f[] points, vec3f position, vec3f scale, double rotation) {
		this.points = points;
		this.position = position;
		this.scale = scale;
		this.rotation = rotation;
	}
}

vec3f[] transformVec3f(in vec3f[] vertBuf, ALLEGRO_TRANSFORM t) {
	auto result = new vec3f[vertBuf.length];
	for(int i = 0; i < vertBuf.length; i++) {
		float x = vertBuf[i].x, y = vertBuf[i].y, z = vertBuf[i].z; 
		al_transform_coordinates_3d(&t, &x, &y, &z);
		result[i] = vec3f(x, y, z);
	}
	return result;
}

void drawPoints(PointsObj obj) {
	ALLEGRO_TRANSFORM t;
	al_identity_transform(&t);
	al_scale_transform_3d(&t, obj.scale.x, obj.scale.y, obj.scale.z);
	al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, obj.rotation);
	al_translate_transform_3d(&t, obj.position.x, obj.position.y, obj.position.z);

	vec3f[] vertBuf = transformVec3f(obj.points, t);
	for (int i = 0; i < vertBuf.length; i++) {
		al_draw_filled_circle(vertBuf[i].x, vertBuf[i].y, 3.0, al_map_rgb(0, 255, 0)); // green color for points
	}
}

void drawWireFrame(Object3D obj) {
	ALLEGRO_TRANSFORM t;
	al_identity_transform(&t);
	al_scale_transform_3d(&t, obj.scale.x, obj.scale.y, obj.scale.z);
	al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, obj.rotation);
	al_translate_transform_3d(&t, obj.position.x, obj.position.y, obj.position.z);

	auto vertBuf = transformVec3f(obj.mesh.vertices, t);

	for (int i = 0; i < obj.mesh.faces.length; i++) {
		int[] face = obj.mesh.faces[i];
		al_draw_triangle(
			vertBuf[face[0]].x, vertBuf[face[0]].y,
			vertBuf[face[1]].x, vertBuf[face[1]].y,
			vertBuf[face[2]].x, vertBuf[face[2]].y,
			al_map_rgb(255, 0, 0), 2.0 // red color with line thickness of 2
		);
	}
}

void drawObject(Object3D obj, ref ALLEGRO_TRANSFORM cameraTransform) {

	ALLEGRO_TRANSFORM t;
	al_identity_transform(&t);
	al_scale_transform_3d(&t, obj.scale.x, obj.scale.y, obj.scale.z);
	al_rotate_transform_3d(&t, 0.0f, 1.0f, 0.0f, obj.rotation);
	al_translate_transform_3d(&t, obj.position.x, obj.position.y, obj.position.z);

	al_compose_transform(&t, &cameraTransform); // compose with camera transform

	auto vertBuf = transformVec3f(obj.mesh.vertices, t);

	vec3f lightSource = vec3f(0, 0, 1000); // light source position (above the object)
	
	// transform light source position with camera transform
	float lx = lightSource.x, ly = lightSource.y, lz = lightSource.z;
	al_transform_coordinates_3d(&cameraTransform, &lx, &ly, &lz);
	
	vec3f lightDir = vec3f(-lx, -ly, -lz);
	lightDir.normalize(); // direction from object to light source

	// vec3f lightDir = vec3f(0.5, -0.5, 1); // light source direction (downwards)
	

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
		
		al_draw_filled_triangle(
			vertBuf[face[0]].x, vertBuf[face[0]].y,
			vertBuf[face[1]].x, vertBuf[face[1]].y,
			vertBuf[face[2]].x, vertBuf[face[2]].y,
			al_map_rgb_f(
				light, light, light // color based on light intensity
			)
		);
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
		// al_translate_transform_3d(&t, 0.0f, 0.0f, -camera.distance);

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
	PointsObj[] pointsObj = [];
	CameraController cameraControl;

	this(MainLoop window) {
		super(window, "world");
		this.initResources();
		cameraControl = new CameraController(window, this);
		
		this.objects = [
			Object3D(
				generateFibonacciSpehereMesh(numPoints), 
					vec3f(0, 0, 0), // position 
					vec3f(400, 400, 400), // scale
					0, // angle 
					window.resources.bitmaps["biotope"]
				),
		];
	}

	final void initResources() {
		texture = window.resources.bitmaps["biotope"];
	}

	override void draw(GraphicsContext gc) {
		al_set_clipping_rectangle(this.x, this.y, this.w, this.h);
		
		ref ALLEGRO_TRANSFORM cameraTransform = cameraControl.getTransform();

		foreach(obj; objects) {
			drawObject(obj, cameraTransform);
		}

		// foreach(obj; pointsObj) {
		// 	drawPoints(obj);
		// }

		al_reset_clipping_rectangle();
	}

	int numPoints = 256;

	override void update() {
		// TODO: use animators
		foreach(ref obj; objects) {
			obj.rotation += 0.002; // Rotate each object for demonstration
		}
	}

	public override bool onKey(int code, int c, int mod) {
		return cameraControl.onKey(code, c, mod);
	}
}