extends TileMapLayer


@export var label_scene: PackedScene
@export var GRID_SIZE_X = 9
@export var GRID_SIZE_Y = 5

var label: Node
var currently_selected: bool = false
var currently_selected_pos: Vector2i
enum tile_type {
	Sea = 0,
	UnselectedIsland = 1,
	SelectedIsland = 8
}


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
	if event is InputEventMouseButton:
		var mouse_pos = local_to_map(event.position)
		var is_unselected = get_cell_source_id(mouse_pos) == tile_type.UnselectedIsland
		var is_selected = get_cell_source_id(mouse_pos) == tile_type.SelectedIsland
		
		if event.pressed and (is_unselected or is_selected):
			if !currently_selected:
				set_cell(mouse_pos, tile_type.SelectedIsland, Vector2i(0, 0), 0)
				currently_selected = true
				currently_selected_pos = mouse_pos
			elif currently_selected_pos == mouse_pos:
				currently_selected = false
				set_cell(mouse_pos, tile_type.UnselectedIsland, Vector2i(0, 0), 0)
