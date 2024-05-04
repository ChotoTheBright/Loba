extends Node2D

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var debug = get_tree().get_nodes_in_group("debug")[0]
onready var tiles = get_tree().get_nodes_in_group("tiles")[0]
onready var _proj = get_tree().get_nodes_in_group("projection")[0]
onready var _start = $StartPosition
onready var _hud = $HUD
var hudvis : bool
onready var map_representation = []
onready var flr_representation = []
onready var brdr_representation = []

func _ready():
	_proj.player.position = _start.position
	#see bottom of script for old method (uses static bodies)#
	tiles.add_tiles(tiles.walls, tiles.grnd, tiles.brdr)
	_proj.map_representation = map_representation
	_proj.flr_representation = flr_representation
	_proj.brdr_representation = brdr_representation
	_hud.hide()

func _process(_delta):
	if Input.is_action_just_pressed('ui_show_hide_hud'):
		if hudvis == true:
			_hud.hide()
			hudvis = false
		else: 
			_hud.show()
			hudvis = true

	if hudvis:
		debug.update_player_angle($HUD/Player.rotation_degrees)
		debug.update_player_position(player.position)
		debug.update_ray(_proj.debug_first_ray, _proj.debug_last_ray)


#var x : int = 10
#var y : int = 15
#	tiles.add_wall_tiles(tiles.walls)
#	tiles.add_grnd_tiles(tiles.grnd)
## this method can still be used if you prefer to populate the map with Static Bodies. :)
#				for n in _obsta.get_children(): 
#					map_representation.append([int(n.position.x / _proj.grid_unit_size),int(n.position.y / _proj.grid_unit_size)])
