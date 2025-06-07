module primitives3d;

import std.math;
import std.array;

import helix.util.vec;
import mesh;
import giftwrap;

auto generateFibonacciSpherePoints(int samples) {
	vec3d[] points = [];

	double phi = PI * (sqrt(5.0) - 1.0); // golden angle in radians

	foreach (i; 0 .. samples) {
		double y = 1.0 - (i / cast(double)(samples - 1)) * 2.0; // y goes from 1 to -1
		double radius = sqrt(1.0 - y * y); // radius at y

		double theta = phi * i; // golden angle increment

		double x = cos(theta) * radius;
		double z = sin(theta) * radius;

		points ~= vec3d(x, y, z);
	}

	return points;
}

auto generateFibonacciSpehereMesh(int samples) {
	vec3d[] points = generateFibonacciSpherePoints(samples);
	int[][] faces = [];

	// foreach (i; 0 .. samples - 1) {
	// 	int next = (i + 1) % samples;
	// 	faces ~= [i, next, (i + samples / 2) % samples];
	// }
	// faces ~= [0, 1, 4]; // just a simple triangle for now
	// faces ~= [0, 1, 3];
	// faces ~= [0, 2, 4];
	// faces ~= [0, 2, 5];
	// faces ~= [0, 3, 5];
	// faces ~= [3, 4, 6];
	
	// return Mesh(points, faces);

	import giftwrap;
	return giftWrap3D(points);
}

/** pyramid, so with a square base and an apex */
Mesh generatePyramidMesh() {
	return Mesh([
		vec3d(0, 1, 0), // apex
		vec3d(-1, -1, -1), // base vertex 1
		vec3d(1, -1, -1), // base vertex 2
		vec3d(1, -1, 1), // base vertex 3
		vec3d(-1, -1, 1) // base vertex 4
	], [
		[0, 1, 2],
		[0, 2, 3],
		[0, 3, 4],
		[0, 4, 1]
	]);
}

Mesh generateCubeMesh() {
	return Mesh([
		vec3d(-1, -1, -1), // 0
		vec3d(1, -1, -1), // 1
		vec3d(1, 1, -1), // 2
		vec3d(-1, 1, -1), // 3
		vec3d(-1, -1, 1), // 4
		vec3d(1, -1, 1), // 5
		vec3d(1, 1, 1), // 6
		vec3d(-1, 1, 1) // 7
	], [
		[0, 1, 2],
		[0, 2, 3],
		[4, 5, 6],
		[4, 6, 7],
		[0, 4, 5],
		[0, 5, 1],
		[2, 6, 7],
		[2, 7, 3],
		[0, 3, 7],
		[0, 7, 4],
		[1, 5, 6],
		[1, 6, 2]
	]);
}