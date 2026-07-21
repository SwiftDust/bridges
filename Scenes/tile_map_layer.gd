extends TileMapLayer

signal map_changed()

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
var visual_bridges: Dictionary = {}
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


func _get_path_key(idx1: int, idx2: int) -> String:
	return str(min(idx1, idx2)) + "-" + str(max(idx1, idx2))


func get_total_placed_bridges() -> int:
	var total = 0
	for path_key in visual_bridges:
		var bridge_node = visual_bridges[path_key]
		if bridge_node.width > 20:
			total += 2
		else:
			total += 1
	return total


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
	var start_idx = _coords_to_index(from_pos)
	var end_idx = _coords_to_index(to_pos)
	var path_key = _get_path_key(start_idx, end_idx)
	
	var step_x = sign(to_pos.x - from_pos.x)
	var step_y = sign(to_pos.y - from_pos.y)
	var direction = Vector2i(step_x, step_y)
	
	var sample_pos = from_pos + direction
	var sample_idx = _coords_to_index(sample_pos)
	var current_val = current_map[sample_idx].to_int()
	
	var is_horizontal = (from_pos.y == to_pos.y)
	var next_state_str: String = "0"
	var action: String = "create" # "create", "upgrade", or "erase"
	
	# on every action it cycles from single bridge to double bridge to sea and back
	if current_val == 0:
		next_state_str = str(solution_bridge_index.SingleBridgeX if is_horizontal else solution_bridge_index.SingleBridgeY)
		action = "create"
	elif current_val == solution_bridge_index.SingleBridgeX or current_val == solution_bridge_index.SingleBridgeY:
		next_state_str = str(solution_bridge_index.DoubleBridgeX if is_horizontal else solution_bridge_index.DoubleBridgeY)
		action = "upgrade"
	else:
		next_state_str = "0"
		action = "erase"
	
	var draw_pos = from_pos + direction
	while draw_pos != to_pos:
		var idx = _coords_to_index(draw_pos)
		current_map[idx] = next_state_str
		draw_pos += direction
	
	if action == "erase":
		if visual_bridges.has(path_key):
			visual_bridges[path_key].queue_free()
			visual_bridges.erase(path_key)
	elif action == "create":
		var bridge = bridge_scene.instantiate()
		add_child(bridge)
		
		var start_pixel = map_to_local(from_pos)
		var end_pixel = map_to_local(to_pos)
		
		if from_pos.x == to_pos.x:
			start_pixel.y += 20
			end_pixel.y -= 20
		if from_pos.y == to_pos.y:
			start_pixel.x += 20
			end_pixel.x -= 20
		
		bridge.clear_points()
		bridge.add_point(start_pixel)
		bridge.add_point(end_pixel)

		visual_bridges[path_key] = bridge
	elif action == "upgrade":
		if visual_bridges.has(path_key):
			var bridge_node = visual_bridges[path_key]
			bridge_node.set_double_bridge()
	map_changed.emit()


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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
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
			#get_viewport().set_input_as_handled()
		elif is_unselected or is_selected:
			if !currently_selected:
				set_cell(mouse_pos, tile_type.SelectedIsland, Vector2i(0, 0), 0)
				currently_selected = true
				currently_selected_pos = mouse_pos
			elif currently_selected_pos == mouse_pos:
				currently_selected = false
				set_cell(mouse_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
			#get_viewport().set_input_as_handled()
		
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
				and (new_cell_id == tile_type.UnselectedIsland or new_cell_id == tile_type.SelectedIsland)
				and mouse_pos != currently_selected_pos
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
				is_hovering = false
