extends TileMapLayer


@export var GRID_SIZE_X = 9
@export var GRID_SIZE_Y = 5



func draw_map(islands: Array):
	for i in range(0, len(islands)):
		print(Vector2i(i / GRID_SIZE_Y, i % GRID_SIZE_Y))
		if islands[i] != "0":
			set_cell(Vector2i(i / GRID_SIZE_Y, i % GRID_SIZE_Y), 1, Vector2i(0,0), 0) # draw island
		else:
			set_cell(Vector2i(i / GRID_SIZE_Y, i % GRID_SIZE_Y), 0, Vector2i(0,0), 0) # draw sea
