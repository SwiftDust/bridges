extends Node2D


@onready var tile_map = $TileMapLayer

var level_1 = {} # TODO: load this in via a text file

func _ready() -> void:
	tile_map.draw_map([Vector2(0, 0), Vector2(1, 1), Vector2(2, 2)])

func _process(delta: float) -> void:
	pass
