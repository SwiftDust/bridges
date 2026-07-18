extends TileMapLayer

signal map_changed(new_value: PackedStringArray)

@export var label_scene: PackedScene
@export var bridge_scene: PackedScene
@export var GRID_SIZE_X = 9
@export var GRID_SIZE_Y = 5

var label: Node
var current_map: PackedStringArray = []
var currently_selected: bool = false
var currently_selected_pos: Vector2i
var currently_hovered_pos: Vector2i = Vector2i(-1, -1)
var is_selected: bool
var is_unselected: bool
var is_hovering: bool
enum tile_type {
	Sea = 0,
	UnselectedIsland = 1,
	SelectedIsland = 8,
}
enum solution_bridge_index { 
	SingleBridgeX = -1,
	DoubleBridgeX = -2,
	SingleBridgeY = -3,
	DoubleBridgeY = -4,
} # according to `hashiwokakero` documentation


func _ready() -> void:
	current_map.resize(GRID_SIZE_X * GRID_SIZE_Y)


func _coords_to_index(pos: Vector2i) -> int:
	return pos.x * GRID_SIZE_Y + pos.y


func is_first_island_in_direction(from_pos: Vector2i, to_pos: Vector2i):
	var step_x = sign(to_pos.x - from_pos.x)
	var step_y = sign(to_pos.y - from_pos.y)
	var direction = Vector2i(step_x, step_y)
	
	var check_pos = from_pos + direction
	
	while check_pos != to_pos:
		var cell_id = get_cell_source_id(check_pos)
		
		if cell_id == tile_type.UnselectedIsland or cell_id == tile_type.SelectedIsland:
			return false
		
		var idx = _coords_to_index(check_pos)
		if idx >= 0 and idx < current_map.size():
			var value = current_map[idx]
			if value != "0" and value.to_int() < 0:
				return false # bridge exists already
		
		check_pos += direction
	
	return true


func draw_bridges_in_direction(from_pos: Vector2i, to_pos: Vector2i):
	var bridge_value: String
	if from_pos.y == to_pos.y:
		bridge_value = str(solution_bridge_index.SingleBridgeX)
	else:
		bridge_value = str(solution_bridge_index.SingleBridgeY)
	
	var step_x = sign(to_pos.x - from_pos.x)
	var step_y = sign(to_pos.y - from_pos.y)
	var direction = Vector2i(step_x, step_y)
	
	var draw_pos = from_pos + direction
	while draw_pos != to_pos:
		var idx = _coords_to_index(draw_pos)
		if idx >= 0 and idx < current_map.size():
			current_map[idx] = bridge_value
		draw_pos += direction
	
	map_changed.emit(current_map)
	
	var bridge = bridge_scene.instantiate()
	add_child(bridge)
	
	var start_pixel = map_to_local(from_pos)
	var end_pixel = map_to_local(to_pos)
	
	bridge.clear_points();
	bridge.add_point(start_pixel)
	bridge.add_point(end_pixel)


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
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = local_to_map(get_local_mouse_position())
		is_unselected = get_cell_source_id(mouse_pos) == tile_type.UnselectedIsland
		is_selected = get_cell_source_id(mouse_pos) == tile_type.SelectedIsland
		
		if is_hovering and (is_unselected or is_selected):
			draw_bridges_in_direction(currently_selected_pos, mouse_pos)
			
			set_cell(currently_selected_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
			set_cell(mouse_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
			
			is_hovering = false
			currently_selected = false
			currently_hovered_pos = Vector2i(-1, -1)
		elif is_unselected or is_selected:
			if !currently_selected:
				set_cell(mouse_pos, tile_type.SelectedIsland, Vector2i(0, 0), 0)
				currently_selected = true
				currently_selected_pos = mouse_pos
			elif currently_selected_pos == mouse_pos:
				currently_selected = false
				set_cell(mouse_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
		
	if event is InputEventMouseMotion:
		var mouse_pos = local_to_map(get_local_mouse_position())
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
					is_hovering = true
			else:
				currently_hovered_pos = Vector2i(-1, -1)
			
