extends TileMap

#this should be the same size as the map tiles you are using.
export(Vector2) var map_size = Vector2.ONE * 64 #<-- var returns the num you put here, ie 64
onready var control = get_tree().get_nodes_in_group("control")[0]
onready var _walls = get_used_cells_by_id(0)
onready var _brdr = get_used_cells_by_id(1)
onready var _grnd = get_used_cells_by_id(2)

func _ready():
	pass

func add_wall_tiles(tile_list = []): #control.map_representation
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if point in tile_list:
				control.map_representation.append(([int(point.x),int(point.y)]))
				pass
			pass

func add_grnd_tiles(tile_list = []): #control.flr_representation
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if point in tile_list:
				control.flr_representation.append(([int(point.x),int(point.y)]))
				pass
			pass

func add_border_tiles(tile_list = []): #control.brdr_representation
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x,y)
			if point in tile_list:
				control.brdr_representation.append(([int(point.x),int(point.y)]))
				pass
			pass

func add_tiles(tile_list1 = [], tile_list2 = [], tile_list3 = []): 
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if point in tile_list1:
				control.map_representation.append(([int(point.x),int(point.y)]))
			if point in tile_list2:
				control.brdr_representation.append(([int(point.x),int(point.y)]))
			if point in tile_list3:
				control.flr_representation.append(([int(point.x),int(point.y)]))
				pass
	pass
