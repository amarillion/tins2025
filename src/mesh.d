module mesh;

import helix.util.vec;

struct Mesh {
	vec3d[] vertices;
	int[3][] faces;

	this(vec3d[] vertices, int[3][] faces) {
		this.vertices = vertices;
		this.faces = faces;
	}
}
