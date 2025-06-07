module mesh;

import helix.util.vec;
import std.algorithm;
import std.array;
import helix.allegro.bitmap;

struct Vertex {
	vec3f position;
	vec2f texCoord;

	this(vec3f position, vec2f texCoord) {
		this.position = position;
		this.texCoord = texCoord;
	}
}

struct Mesh {
	Vertex[] vertices;
	int[3][] faces;

	this(vec3f[] vertices, int[3][] faces) {
		this.vertices = vertices.map!(v => Vertex(v, vec2f(0.0f, 0.0f))).array;
		this.faces = faces;
	}
}
