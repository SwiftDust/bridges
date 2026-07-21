extends CanvasLayer

@onready var label = $Count


func set_bridges_placed(count: int, total: int) -> void:
	if count < 10:
		label.text = "0%s/%s" % [count, total]
	else:
		label.text = "%s/%s" % [count, total]
