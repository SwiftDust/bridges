extends Line2D

@export var bridge_texture: CompressedTexture2D
@export var double_bridge_texture: CompressedTexture2D


func _ready() -> void:
	set_single_bridge()


func set_single_bridge() -> void:
	texture = bridge_texture


func set_double_bridge() -> void:
	texture = double_bridge_texture
	width *= 2
