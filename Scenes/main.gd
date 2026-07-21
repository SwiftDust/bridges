extends Node2D


@onready var tile_map = $TileMapLayer
@onready var hud = $HUD

var level_arr: PackedStringArray = []
var current_map: PackedStringArray = []
var solution_arr: PackedStringArray = []

enum solution_bridge_index { 
	SingleBridgeX = -1,
	DoubleBridgeX = -2,
	SingleBridgeY = -3,
	DoubleBridgeY = -4,
}


func _find_bridge_count(bridge: int) -> int:
	if (
		bridge == solution_bridge_index.SingleBridgeX 
		or bridge == solution_bridge_index.SingleBridgeY
	):
		return 1
	elif (
		bridge == solution_bridge_index.DoubleBridgeX
		or bridge == solution_bridge_index.DoubleBridgeY
	):
		return 2
	else:
		return 0


func _ready() -> void:
	var levels_dir = ResourceLoader.list_directory("res://Levels")
	for level_dir in levels_dir:
		var level_file = FileAccess.open("res://Levels/" + level_dir + "/level.txt", FileAccess.READ).get_as_text()
		level_arr = level_file.strip_edges().split()
		
		var solution_file = FileAccess.open("res://Levels/" + level_dir + "/solution.txt", FileAccess.READ).get_as_text()
		var solution = solution_file.strip_edges()
		
		var re := RegEx.new()
		re.compile(r"-?\d")
		
		for match in re.search_all(solution):
			solution_arr.append(match.get_string())
	
	tile_map.draw_map(level_arr)
	current_map = level_arr
	tile_map.current_map = current_map
	
	var total = 0
	
	for bridge in solution_arr:
		total += _find_bridge_count(int(bridge))
	
	hud.set_bridges_placed(0, total)


func _process(delta: float) -> void:
	if current_map == solution_arr:
		pass # you win!


func _on_tile_map_layer_map_changed() -> void:
	current_map = tile_map.current_map
	var count = tile_map.get_total_placed_bridges()
	var total = 0
	
	for bridge in solution_arr:
		total += _find_bridge_count(int(bridge))
	
	hud.set_bridges_placed(count, total)
