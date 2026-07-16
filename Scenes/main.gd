extends Node2D

@onready var tile_map = $TileMapLayer

var level_arr: PackedStringArray = []


func _ready() -> void:
	var levels_dir = ResourceLoader.list_directory("res://Levels")
	for level_dir in levels_dir:
		var level_file = FileAccess.open("res://Levels/" + level_dir + "/level.txt", FileAccess.READ).get_as_text()
		level_arr = level_file.strip_edges().split()
	
	
	tile_map.draw_map(level_arr)


func _process(delta: float) -> void:
	pass
