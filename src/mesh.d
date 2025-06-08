module mesh;

import helix.util.vec;
import std.algorithm;
import std.array;
import helix.allegro.bitmap;

struct Mesh {
	vec3f[] vertices;
	int[3][] faces;

	this(vec3f[] vertices, int[3][] faces) {
		this.vertices = vertices;
		this.faces = faces;
	}
}
