extends TileMapLayer

@export var label_scene: PackedScene
@export var GRID_SIZE_X = 9
@export var GRID_SIZE_Y = 5

var label: Node
var currently_selected: bool = false
var currently_selected_pos: Vector2i
var currently_hovered_pos: Vector2i = Vector2i(-1, -1)
var is_selected: bool
var is_unselected: bool
enum tile_type {
	Sea = 0,
	UnselectedIsland = 1,
	BridgeXIslandL = 2,
	BridgeXIslandR = 3,
	BridgeX = 4,
	BridgeY = 5,
	BridgeYIslandU = 6,
	BridgeYIslandD = 7,
	SelectedIsland = 8,
}


func is_first_island_in_direction(from_pos: Vector2i, to_pos: Vector2i):
	var step_x = sign(to_pos.x - from_pos.x)
	var step_y = sign(to_pos.y - from_pos.y)
	var direction = Vector2i(step_x, step_y)
	
	var check_pos = from_pos + direction
	
	while check_pos != to_pos:
		var cell_id = get_cell_source_id(check_pos)
		
		if cell_id == tile_type.UnselectedIsland or cell_id == tile_type.SelectedIsland:
			return false
		
		check_pos += direction
	
	return true


func draw_bridges_in_direction(from_pos: Vector2i, to_pos: Vector2i):
	var step_x = sign(to_pos.x - from_pos.x)
	var step_y = sign(to_pos.y - from_pos.y)
	var direction = Vector2i(step_x, step_y)
	
	var draw_pos = from_pos + direction
	
	if step_x == 0: # moves vertically, so should use Y variant of bridges
		var first_tile = tile_type.BridgeYIslandD if step_y > 0\
				else tile_type.BridgeYIslandU
		var last_tile = tile_type.BridgeYIslandU if step_y > 0\
				else tile_type.BridgeYIslandD
		set_cell(draw_pos, first_tile, Vector2i(0, 0), 0)
		set_cell(draw_pos, last_tile, Vector2i(0, 0), 0)
		
		while draw_pos.y + 1 != to_pos.y - 1:
			set_cell(draw_pos, tile_type.BridgeY, Vector2i(0, 0), 0)
	else: # moves horizontally
		var first_tile = tile_type.BridgeXIslandL if step_y > 0\
				else tile_type.BridgeXIslandR
		var last_tile = tile_type.BridgeXIslandR if step_y > 0\
				else tile_type.BridgeXIslandL
		set_cell(draw_pos, first_tile, Vector2i(0, 0), 0)
		set_cell(draw_pos, last_tile, Vector2i(0, 0), 0)
		
		while draw_pos.x + 1 != to_pos.x - 1:
			set_cell(draw_pos, tile_type.BridgeX, Vector2i(0, 0), 0)
	


func draw_map(islands: Array):
	for i in range(0, len(islands)):
		var tile_pos = Vector2i(i / floor(GRID_SIZE_Y), i % GRID_SIZE_Y)
		
		if islands[i] != "0":
			set_cell(tile_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
			
			label = label_scene.instantiate()
			add_child(label)
			label.position.x = map_to_local(tile_pos).x - 10
			label.position.y = map_to_local(tile_pos).y - 22.5
			label.text = islands[i]
		else:
			set_cell(tile_pos, tile_type.Sea, Vector2i(0, 0), 0)


func _unhandled_input(event: InputEvent) -> void:
	# TODO: Have a hovered version of tile, too, instead of instantly selecting
	if event is InputEventMouseButton:
		var mouse_pos = local_to_map(event.position)
		is_unselected = get_cell_source_id(mouse_pos) == tile_type.UnselectedIsland
		is_selected = get_cell_source_id(mouse_pos) == tile_type.SelectedIsland
		
		if event.pressed and (is_unselected or is_selected):
			if !currently_selected:
				set_cell(mouse_pos, tile_type.SelectedIsland, Vector2i(0, 0), 0)
				currently_selected = true
				currently_selected_pos = mouse_pos
			elif currently_selected_pos == mouse_pos:
				currently_selected = false
				set_cell(mouse_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
				
	if event is InputEventMouseMotion:
		var mouse_pos = local_to_map(event.position)
		var can_be_selected = false
		
		if mouse_pos != currently_hovered_pos:
			if currently_hovered_pos != Vector2i(-1, -1):
				var old_cell_id = get_cell_source_id(currently_hovered_pos)
				if old_cell_id == tile_type.SelectedIsland:
					set_cell(currently_hovered_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
				
			var new_cell_id = get_cell_source_id(mouse_pos)
				
			if (
				currently_selected
				and new_cell_id == tile_type.UnselectedIsland
			):
				can_be_selected = (
					currently_selected_pos.x == mouse_pos.x
					or currently_selected_pos.y == mouse_pos.y
				)
				if can_be_selected and is_first_island_in_direction(currently_selected_pos, mouse_pos):
					set_cell(mouse_pos, tile_type.SelectedIsland, Vector2i(0, 0), 0)
					currently_hovered_pos = mouse_pos
			else:
				currently_hovered_pos = Vector2i(-1, -1)
			
