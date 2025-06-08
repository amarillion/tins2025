module sphereGrid;

import mesh;
import cell;
import helix.util.vec;
import std.conv : to;
import std.range;

alias Edge = int[2];
alias Face = int[3];

// TODO: generalize on T = Cell. Problem, how do I pass the constructor?
class SphereGrid {

	const Mesh mesh;

	this(in Mesh mesh) {
		this.mesh = mesh;
		initCells();
	}

	private Cell[][Cell] neighborMap;
	private Cell[] cells;

	// TODO: constructor function, move out of class to generalize.
	private Cell createCell(vec3f[3] triangle) {
		
		// TODO:
		// calculate average latitude based on triangle vertices
		// double avgy = (triangle[0].y + triangle[1].y + triangle[2].y) / 3.0;
		// import std.math : PI, asin;
		// double lat = asin(avgy) * 180.0 / PI;


		return new Cell(0, 0, 10);
	}
	
	private void initCells() {
		Cell[][Edge] edgeMap;

		void addEdge(Edge edge, Cell cell) {
			// normalize edge
			if (edge[0] > edge[1]) {
				edge = [edge[1], edge[0]];
			}

			if (edge in edgeMap) {
				edgeMap[edge] ~= cell;
			}
			else {
				edgeMap[edge] = [cell];
			}
		}

		cells = new Cell[mesh.faces.length];
		for (int i = 0; i < mesh.faces.length; i++) {
			Face face = mesh.faces[i];
			vec3f[3] area = [mesh.vertices[face[0]], mesh.vertices[face[1]], mesh.vertices[face[2]]];
			cells[i] = createCell(area);
			for(int j = 0; j < face.length; j++) {
				Edge edge = [face[j], face[(j + 1) % face.length]];
				addEdge(edge, cells[i]);
			}
		}

		// convert edgeMap to neighbor map
		foreach (edge, cellList; edgeMap) {
			if (cellList.length < 2) continue; // no neighbors
			foreach (i, cell; cellList) {
				foreach (j, neighborCell; cellList) {
					if (i == j) continue; // skip self
					if (cell in neighborMap) {
						neighborMap[cell] ~= neighborCell;
					}
					else {
						neighborMap[cell] = [neighborCell];
					}
				}
			}
		}
	}

	Cell getCell(int index) {
		assert(index >= 0 && index < cells.length, "Index out of range: " ~ to!string(index));
		return cells[index];
	}

	Cell[] getAdjacent(Cell cell) {
		if (cell in neighborMap) {
			return neighborMap[cell];
		}
		else {
			return []; // no neighbors
		}
	}

	@property size() const {
		return cells.length;
	}

	Cell[] eachNode() {
		return cells;
	}
}