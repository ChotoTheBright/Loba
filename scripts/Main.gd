extends Node2D

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var debug = get_tree().get_nodes_in_group("debug")[0]
onready var tiles = get_tree().get_nodes_in_group("tiles")[0]
onready var _proj = $Projection
onready var _start = $StartPosition
onready var _hud = $HUD
var hudvis : bool
var map_representation = []
var x : int = 10
var y : int = 15

func _ready():
	_proj.player.position = _start.position
# this method can still be used if you prefer to populate the map with Static Bodies
#				for n in _obsta.get_children(): 
#					map_representation.append([int(n.position.x / _proj.grid_unit_size),int(n.position.y / _proj.grid_unit_size)])
	tiles.add_wall_tiles(tiles._walls)
	_proj.map_representation = map_representation
	_hud.hide()

func _process(_delta):
	if Input.is_action_just_pressed('ui_show_hide_hud'):
		if hudvis == true:
			debug.update_player_angle($HUD/Player.rotation_degrees)
			debug.update_player_position(_proj.player.position)
			debug.update_ray(_proj.debug_first_ray, _proj.debug_last_ray)
			_hud.hide()
			hudvis = false
		else: 
			_hud.show()
			hudvis = true
