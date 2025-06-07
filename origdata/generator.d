#!/usr/bin/env -S rdmd -I../dtwist/src -I~/prg/alleg/DAllegro5/ -L-L/home/martijn/prg/alleg/DAllegro5
module origdata.generator;

import std.string;

import allegro5.allegro;
import allegro5.allegro_image;
import allegro5.allegro_color;
import std.random;

import helix.allegro.bitmap;

import std.math;
import core.internal.container.common;

Bitmap readSpriteSheet(string filename) {
	auto file = Bitmap.load(filename);
	assert(file !is null, "Could not load file: " ~ filename);
	return file;
}



Bitmap convertStack(Bitmap images, int num) {
	int tileHeight = images.h;
	int tileWidth = tileHeight; // assuming square tiles
	int tileNum = images.w / images.h;

	// create a new bitmap with extra margin
	Bitmap result = Bitmap.create(tileWidth * 4 * num, tileHeight * 4);
	al_set_target_bitmap(result.ptr);
	al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

	Bitmap temp = Bitmap.create(tileWidth * 4, tileHeight * 4);

	float angle = 0.0f;
	foreach(a; 0..num) {	
		Bitmap dest = result.subBitmap(tileWidth * 4 * a, 0, tileWidth * 4, tileHeight * 4);

		foreach(i; 0..tileNum) {
			Bitmap tile = images.subBitmap(i * tileWidth, 0, tileWidth, tileHeight);
			al_set_target_bitmap(temp.ptr);
			al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

			// rotate and make scale double size
			al_draw_scaled_rotated_bitmap(tile.ptr, 
				tileWidth / 2, tileHeight / 2, 
				tileWidth * 2, tileHeight * 2, 
				2.0f, 2.0f,
				angle * PI / 180.0, 0);
			
			// now scale by 50% vertically with offset:
			al_set_target_bitmap(dest.ptr);
			al_draw_scaled_bitmap(temp.ptr, 
				0, 0, 
				tileWidth * 4, tileHeight * 4, 
				0, (tileNum - i) * 2, 
				tileWidth * 4, tileHeight * 2, 
				0);
			al_draw_scaled_bitmap(temp.ptr, 
				0, 0, 
				tileWidth * 4, tileHeight * 4, 
				0, (tileNum - i) * 2 - 1, 
				tileWidth * 4, tileHeight * 2, 
				0);
		}
		angle += (360.0f / num);

	}
	return result;
}

void generateSingle(Bitmap spriteSheet, int x, int y) {
	ALLEGRO_BITMAP *current = al_get_target_bitmap();

	Bitmap temp = Bitmap.create(64, 64);
	int tileSize = 64;
	int[] rowOrder = [3, 0, 1, 2];
	foreach (row; rowOrder) {
		int randomIdx = uniform(0, 4); // random index from 0 to 3
		Bitmap tile = spriteSheet.subBitmap(randomIdx * tileSize, row * tileSize, tileSize, tileSize);
		al_set_target_bitmap(temp.ptr);
		al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));
		// draw the tile at the center of the temp bitmap
		al_draw_bitmap(tile.ptr, 0, 0, 0);

		ALLEGRO_COLOR shade1 = al_map_rgba_f(uniform(0.0f, 1.0f), uniform(0.0f, 1.0f), uniform(0.0f, 1.0f), 0.5);
		ALLEGRO_COLOR shade2 = al_map_rgba_f(uniform(0.0f, 1.0f), uniform(0.0f, 1.0f), uniform(0.0f, 1.0f), 0.5);
	
		for(int i = 0; i < tileSize; i++) {
			for(int j = 0; j < tileSize; j++) {
				
				ALLEGRO_COLOR color = al_get_pixel(tile.ptr, i, j);
				
				// replace red color with random color
				if (color.r > 0.7 && color.g < 0.3 && color.b < 0.3) {
					float brightness = color.r;
					al_put_pixel(i, j, al_map_rgba_f(
						shade1.r * brightness,
						shade1.g * brightness,
						shade1.b * brightness,
						color.a
					));
				}

				// replace green color with random color
				if (color.r < 0.3 && color.g > 0.7 && color.b < 0.3) {
					float brightness = color.g;
					al_put_pixel(i, j, al_map_rgba_f(
						shade2.r * brightness,
						shade2.g * brightness,
						shade2.b * brightness,
						color.a
					));
				}

			}
		}
		al_set_target_bitmap(current);

		// TODO: set shader to replace colors
		al_draw_bitmap(temp.ptr, x, y, 0);
	}

}

Bitmap generate(Bitmap spriteSheet, int w, int h) {
	int tileHeight = 64;
	int tileWidth = 64;
	
	// create a new bitmap with extra margin
	Bitmap result = Bitmap.create(tileWidth * w, tileHeight * h);
	al_set_target_bitmap(result.ptr);
	al_clear_to_color(al_map_rgba_f(0, 0, 0, 0));

	foreach(i; 0..w) {
		foreach(j; 0..h) {
			generateSingle(spriteSheet, i * 64, j * 64);
		}
	}
	
	return result;	
}

int main(string[] args) {
	assert(args.length == 3, "Usage: ./generator.d <infile> <outfile>");
	string infile = args[1];
	string outfile = args[2];

	al_run_allegro(
	{
		al_init();
		al_init_image_addon();

		Bitmap spriteSheet = readSpriteSheet(infile);

		Bitmap result = generate(spriteSheet, 8, 8);
		
		al_save_bitmap(toStringz(outfile), result.ptr);
		return 0;
	});
	return 0;
}