module sphere;

import std.math;
import std.array;

import helix.util.vec;

alias vec3d = vec!(3, double);

auto generateSpherePoints(int samples) {
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
