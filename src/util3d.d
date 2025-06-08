module util3d;

import allegro5.allegro;
import helix.util.vec;

/** apply an allegro transform to an array of vec3f */
vec3f[] transformVertices(in vec3f[] vertBuf, ALLEGRO_TRANSFORM t) {
	vec3f[] result = vertBuf.dup;
	for (int i = 0; i < vertBuf.length; i++) {
		float x = vertBuf[i].x, y = vertBuf[i].y, z = vertBuf[i].z; 
		al_transform_coordinates_3d(&t, &x, &y, &z);
		result[i] = vec3f(x, y, z);
	}
	return result;
}
