module giftwrap;


import mesh;
import std.algorithm;
import std.container;
import std.conv;
import std.range;
import helix.util.vec;

alias Face = int[3];
alias Edge = int[2];
import std.stdio : writeln;
import std.container.dlist;

// After: https://github.com/moharastegaran/gift_wrapping_3d/blob/main/convex_hull.py

int findNextPoint(vec3d[] points, int i1, int i2) {
	vec3d p1 = points[i1];
	vec3d p2 = i2 >= 0 ? points[i2] : points[i1] - vec3d(1,1,0);

	vec3d bestPoint;
	int bestPointIndex = -1;
	vec3d edgeDelta = p2 - p1;

	foreach (i; 0 .. to!int(points.length)) {
		if (i == i1 || i == i2) continue;
		if (bestPointIndex < 0) {
			bestPoint = points[i];
			bestPointIndex = i;
		}
		else {
			// These vector calculations give the signed volume of the tetrahedron (p1, p2, best_point, p).
			// The volume is positive if p is to the left of the plane defined by the triangle (p1,p2,best_point)
			// This means p is a better choice than before.
			auto p = points[i];
			vec3d v = p - p1;
			v = v - project(v, edgeDelta);
			vec3d u = bestPoint - p1;
			u = u - project(u, edgeDelta);
			vec3d cross = u.crossProductVector(v);
			if (cross.dotProduct(edgeDelta) > 0) {
				bestPoint = p;
				bestPointIndex = i;
			}
		}
	}

	return bestPointIndex;
}


auto giftWrap3D(vec3d[] points) {


	Face[] hull = [];
	Edge[] edges_available = [];
	bool[Edge] edges_processed;

	// A function to create an edge indicating that it has been processed. 
	// If the reverse of this edge has not been processed before, then add that to the queue.
	void addEdge(Edge e) {
		edges_processed[e] = true;
		Edge reverse = [e[1], e[0]];
		if (reverse !in edges_processed) {
			edges_available ~= reverse;
		}
	}

	{
		// Step 1: Find lowest point, use defined natural ordering 
		int p0 = to!int(points.minIndex());

	//     fp2 = find_next_point(points, fp1, None)
		int p1 = findNextPoint(points, p0, -1);
		addEdge([p1, p0]);
	}

	while (!edges_available.empty) {
		Edge edge = edges_available.front;
		edges_available.popFront();
		
		int p1 = edge[0];
		int p2 = edge[1];

		if (edge !in edges_processed) {
			// Get next point
			int p3 = findNextPoint(points, p1, p2);

			// Add the face to the convex hull, and its edges to the queue.
			hull ~= [p1, p2, p3];
			addEdge([p1, p2]);
			addEdge([p2, p3]);
			addEdge([p3, p1]);
		}
	}
	return Mesh(points, hull);
}
