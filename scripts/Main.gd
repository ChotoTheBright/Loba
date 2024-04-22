extends Node2D

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var debug = get_tree().get_nodes_in_group("debug")[0]
onready var _proj = $Projection
onready var _start = $StartPosition
onready var _hud = $HUD
#onready var _tiles = $HUD/Obstacles/TileMap
onready var _obsta = $HUD/Obstacles
var hudvis : bool

func _ready():
	_proj.player.position = _start.position
	var map_representation = []
	for n in _obsta.get_children():
		map_representation.append([int(n.position.x / _proj.grid_unit_size),int(n.position.y / _proj.grid_unit_size)])
	_proj.map_representation = map_representation
	_hud.hide()

func _process(_delta):
	if Input.is_action_just_pressed('ui_show_hide_hud'):
		if hudvis:
			_hud.hide()
			hudvis = false
		else: 
			_hud.show()
			hudvis = true


	if hudvis == true:
		debug.update_player_angle($HUD/Player.rotation_degrees)
		debug.update_player_position(_proj.player.position)
		debug.update_ray(_proj.debug_first_ray, _proj.debug_last_ray)
