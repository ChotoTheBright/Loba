extends Node

export var W : int = 256
export var H : int = 256
export var WarpScale : int = 75
export var WarpOffset : float = 0.0
var walls = []


func _ready():
	WarpScale.set_range(0,300)
	pass

func _process(delta):
	pass
