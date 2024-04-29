extends TileMap

#this should be the same size as the map tiles you are using.
export(Vector2) var map_size = Vector2.ONE * 64 #<-- var returns the num you put here, ie 64
onready var control = get_tree().get_nodes_in_group("control")[0]
onready var _walls = get_used_cells_by_id(0)

func _ready():
	add_wall_tiles(_walls)

func add_wall_tiles(tile_list = []):
	for y in range(map_size.y):
		for x in range(map_size.x):
			var point = Vector2(x, y)
			if point in tile_list:
				control.map_representation.append(([int(point.x),int(point.y)]))
			pass
