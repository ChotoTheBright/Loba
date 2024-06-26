extends Node2D
export (int) var grid_unit_size = 64
export (int) var player_speed = 2
export (int) var view_distance = 34
#view distance is the "blocks" multiplied by grid_unit_size (ie. 64 * 34 equals 2176 pixels)
onready var control = get_tree().get_nodes_in_group("control")[0]
onready var tiles = get_tree().get_nodes_in_group("tiles")[0]
onready var player_ref= get_tree().get_nodes_in_group("player")[0]
onready var player_starting_pos_ref = get_tree().get_nodes_in_group("startpos")[0]
onready var wall_texture = tiles.get_tileset().tile_get_texture(0)
onready var border_texture = tiles.get_tileset().tile_get_texture(1)
onready var floor_texture = tiles.get_tileset().tile_get_texture(2)
onready var sky_texture = preload("res://images/sky.png")
onready var ceil_texture = preload("res://images/ceilingblack.png")
onready var texture_list : Array = [wall_texture,border_texture]
const FOV = 55
const ANGLE0 = 0
var PROJECTION_PLANE_WIDTH = 320
var PROJECTION_PLANE_HEIGHT = 200
var PROJECTION_X_CENTER = PROJECTION_PLANE_WIDTH / 2 #half the screen width
var PROJECTION_Y_CENTER = PROJECTION_PLANE_HEIGHT / 2 #half the screen height
var ANGLE60 = PROJECTION_PLANE_WIDTH
var ANGLE30 = floor(ANGLE60/2)
var ANGLE15 = floor(ANGLE30/2)
var ANGLE90 = floor(ANGLE30*3)
var ANGLE180 = floor(ANGLE90*2)
var ANGLE270 = floor(ANGLE90*3)
var ANGLE360 = floor(ANGLE60*6)
var ANGLE5 = floor(ANGLE30/6)
var ANGLE10 = floor(ANGLE5*2)
var ANGLE45 = floor(ANGLE15*3)
# warning-ignore:integer_division
var PROJECTION_PLANE_DISTANCE = floor(PROJECTION_X_CENTER / tan(deg2rad(FOV / 2)))
var PROJECTION_TO_360_RATIO = floor(ANGLE360 / 360)
# Trigonometry tables for fast calculation ("i" indicates the table is inverse)
# I don't actually know trig, I followed people way smarter than I am. :D
# further reading: https://github.com/permadi-com/ray-cast
var f_sin_table = []
var f_i_sin_table = []
var f_cos_table = []
var f_i_cos_table = []
var f_tan_table = []
var f_i_tan_table = []
var f_fish_dict = {}
var f_x_step_table = []
var f_y_step_table = []
var player = {"position": Vector2(0, 0),"rotation": ANGLE90}
# debug
var debug_first_ray
var debug_last_ray
var debug_ray_intersection  
var map_representation = [] # Array of all coords with a wall tile 
var flr_representation = [] # Array of all coords with a floor tile 
var brdr_representation = [] # Array of all coords with a border tile
#"View" window
onready var player_view_area = Rect2(0, 0, 0, 0)
onready var _tile_data = Vector2.ONE * grid_unit_size
onready var point = Vector2(0,0)

func arcToRad(angle):
	return ((angle*PI)/ANGLE180)

func _ready():
	for y in range(_tile_data.y):
		for x in range(_tile_data.x):
			point = Vector2(x, y)
			pass
	pass

  # player starting pos.
	player_ref.position = player_starting_pos_ref.position
	player.position.x = player_ref.position.x
	player.position.y = player_ref.position.y

# populate lookup tables with radian values
	var radian
	for i in range(0, ANGLE360 + 1):
		radian = arcToRad(i) + (0.0001)
		f_sin_table.append(sin(radian))
		f_i_sin_table.append(1.0/f_sin_table[i])
		f_cos_table.append(cos(radian))
		f_i_cos_table.append(1.0/f_cos_table[i])
		f_tan_table.append(tan(radian))
		f_i_tan_table.append(1.0/f_tan_table[i])

		# Facing LEFT
		if(i >= ANGLE90 && i < ANGLE270):
			f_x_step_table.append(grid_unit_size/f_tan_table[i])
			if f_x_step_table[i] > 0:
				f_x_step_table[i] = -f_x_step_table[i]
		# Facing RIGHT
		else:
			f_x_step_table.append(grid_unit_size/f_tan_table[i])
			if f_x_step_table[i] < 0:
				f_x_step_table[i] = -f_x_step_table[i]
		# Facing DOWN
		if (i >= ANGLE0 && i < ANGLE180):
			f_y_step_table.append(grid_unit_size*f_tan_table[i])
			if f_y_step_table[i] < 0:
				f_y_step_table[i] = -f_y_step_table[i]
		# Facing UP
		else:
			f_y_step_table.append(grid_unit_size*f_tan_table[i])
			if f_y_step_table[i] > 0:
				f_y_step_table[i] = -f_y_step_table[i]

	# Fishbowl distortion fix?
	for i in range(-ANGLE30, ANGLE30 + 1):
		radian = arcToRad(i)
		f_fish_dict[int(i+ANGLE30)] = (1.0/cos(radian))

func _draw():
	_draw_sky()
	_cast_rays()

func _process(_delta):
	update()

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_left"):
		_rotate_left(delta)
	if Input.is_action_just_pressed("ui_right"):
		_rotate_right(delta)

	player_ref.rotation_degrees = floor(player.rotation / PROJECTION_TO_360_RATIO)

	var player_x_dir = f_cos_table[player.rotation]
	var player_y_dir = f_sin_table[player.rotation]

	if Input.is_action_pressed("ui_up"):
		_move_forward(player_x_dir, player_y_dir)
	if Input.is_action_pressed("ui_down"):
		_move_backwards(player_x_dir, player_y_dir)

	player_ref.position.x = floor(player_ref.position.x)
	player_ref.position.y = floor(player_ref.position.y)
	player.position.x = player_ref.position.x
	player.position.y = player_ref.position.y

	player_view_area = Rect2(player.position.x - (view_distance/2 * grid_unit_size),player.position.y - (view_distance/2 * grid_unit_size),view_distance * grid_unit_size,view_distance * grid_unit_size)

func _rotate_right(_delta):
	player.rotation += ANGLE45#ANGLE5
	if player.rotation >= ANGLE360:
		player.rotation -= ANGLE360

func _rotate_left(_delta):
	player.rotation -= ANGLE45#ANGLE5
	if player.rotation < ANGLE0:
		player.rotation += ANGLE360

func _move_forward(player_x_dir, player_y_dir):
	player_ref.move_and_collide(Vector2(round(player_x_dir * player_speed),round(player_y_dir * player_speed)))

func _move_backwards(player_x_dir, player_y_dir):
	player_ref.move_and_collide(-Vector2(round(player_x_dir * player_speed),round(player_y_dir * player_speed)))

func _draw_wall(ray_distance, ray_index, texture_offset, _x, _y):
	var projected_slice_height = grid_unit_size * PROJECTION_PLANE_DISTANCE / ray_distance
#	var _point = Vector2(x, y)
#	if _point: #if point in 
#		pass

	draw_texture_rect_region(wall_texture, 
	Rect2(ray_index, PROJECTION_Y_CENTER - int(projected_slice_height / 2),1,projected_slice_height),
	Rect2(floor(texture_offset), 0, 1, grid_unit_size))

func _draw_floor(ray_distance, ray_index):
	var projected_slice_height = grid_unit_size * PROJECTION_PLANE_DISTANCE / ray_distance
	var btm_of_wall = PROJECTION_Y_CENTER+(projected_slice_height/PI) #<-- thanks, Laura <3
	var top_of_wall = PROJECTION_Y_CENTER-(projected_slice_height/PI)
	draw_texture_rect_region(floor_texture, 
	Rect2(ray_index,btm_of_wall,grid_unit_size,top_of_wall),
	Rect2(ray_index,0,1,grid_unit_size))

func _draw_sky():
	#casts a flat textured box over the scene. does not scroll or rotate.
	draw_texture_rect(sky_texture,Rect2(0, 0,PROJECTION_PLANE_WIDTH - int(grid_unit_size * PROJECTION_PLANE_WIDTH),grid_unit_size * PROJECTION_Y_CENTER/64),true)

func _cast_rays():
	var ray_degree = player.rotation
	ray_degree -= ANGLE30
	if ray_degree < 0:
		ray_degree = ANGLE360 + ray_degree
	var ray_index = 0

	while ray_index <= PROJECTION_PLANE_WIDTH:
		var ray_data = _cast_ray(
		player.position,ray_degree,
		ray_index == 0,ray_index == PROJECTION_PLANE_WIDTH)
		if ray_data:
			var ray_distance = ray_data['ray_distance']
			if ray_distance:
				ray_distance /= f_fish_dict[ray_index]
				#this is where the rendering occurs
				_draw_floor(ray_distance, ray_index)
				_draw_wall(ray_distance, ray_index, round(ray_data['texture_offset']), map_representation, map_representation) #_border_texture
			ray_degree += 1
		if ray_degree >= ANGLE360:
			ray_degree -= ANGLE360
		ray_index += 1

func _cast_ray(player_position, ray_degree, _is_first_ray, _is_last_ray):
	var horizontal_ray_collision = _get_horizontal_ray_collision(player_position, ray_degree)
	var vertical_ray_collision = _get_vertical_ray_collision(player_position, ray_degree)
	var ray_collision = null

	if horizontal_ray_collision and not vertical_ray_collision:
		ray_collision = horizontal_ray_collision
	elif vertical_ray_collision and not horizontal_ray_collision:
		ray_collision = vertical_ray_collision
	elif vertical_ray_collision and horizontal_ray_collision:
		if horizontal_ray_collision['distance'] < vertical_ray_collision['distance']:
			ray_collision = horizontal_ray_collision
		else:
			ray_collision = vertical_ray_collision

	if ray_collision:
		return {'ray_distance': ray_collision['distance'],'texture_offset': ray_collision['texture_offset']}#, 'texture': ray_collision['texture']

func _wall_exists(x, y):
	return map_representation.has([int(x), int(y)])

##HORIZONTAL##
func _get_horizontal_ray_collision(player_position, ray_degree):
	var is_facing_down = (ray_degree > ANGLE0 and ray_degree < ANGLE180)
	var y_intersection
	var x_intersection
	var i = 0

	while (true):
		if i == 0:
			y_intersection = _find_first_Y_h_intersection(ray_degree, player_position, is_facing_down)
			x_intersection = _find_first_X_h_intersection(ray_degree, player_position, y_intersection)

			if not is_facing_down:
				y_intersection -= 1

			var grid_x_coords = floor(x_intersection / grid_unit_size)
			var grid_y_coords = floor(y_intersection / grid_unit_size)

			if _wall_exists(grid_x_coords, grid_y_coords):
				return {'distance': (x_intersection - player_position.x) * f_i_cos_table[ray_degree],
				'texture_offset': fmod(x_intersection, grid_unit_size)}#,'texture': 
			i += 1
		else: 
			y_intersection += _find_next_Y_h_intersection(is_facing_down)
			x_intersection += _find_next_X_h_intersection(ray_degree)

			var grid_x_coords = floor(x_intersection / grid_unit_size)
			var grid_y_coords = floor(y_intersection / grid_unit_size)

			if _wall_exists(grid_x_coords, grid_y_coords): 
				return {'distance': (x_intersection - player_position.x) * f_i_cos_table[ray_degree],
				'texture_offset': fmod(x_intersection, grid_unit_size)}
			if y_intersection < player_view_area.position.y \
				or y_intersection > player_view_area.end.y \
				or x_intersection < player_view_area.position.x \
				or x_intersection > player_view_area.end.x:
					break #<-- all false

# warning-ignore:unused_argument
func _find_first_Y_h_intersection(ray_degree, player_position, is_facing_down):
	if is_facing_down:
		return (floor(player_position.y / grid_unit_size) * grid_unit_size + grid_unit_size)
	else:
		return (floor(player_position.y / grid_unit_size) * grid_unit_size)

func _find_first_X_h_intersection(ray_degree, player_position, y_intersection):
	return (f_i_tan_table[ray_degree] * (y_intersection - player_position.y)) + player_position.x

func _find_next_Y_h_intersection(is_facing_down):
	return grid_unit_size if is_facing_down else -grid_unit_size

func _find_next_X_h_intersection(ray_degree):
	return f_x_step_table[ray_degree]

##VERTICAL##
func _get_vertical_ray_collision(player_position, ray_degree):
	var is_facing_left = (ray_degree > ANGLE90 and ray_degree < ANGLE270)
	var x_intersection
	var y_intersection
	var i = 0
	while (true):
		if i == 0:
			x_intersection = _find_first_X_v_intersection(ray_degree, player_position, is_facing_left)
			y_intersection = _find_first_Y_v_intersection(ray_degree, player_position, x_intersection)

			if is_facing_left:
				x_intersection -= 1

			var grid_x_coords = floor(x_intersection / grid_unit_size)
			var grid_y_coords = floor(y_intersection / grid_unit_size)

			if _wall_exists(grid_x_coords, grid_y_coords): 
				return {'distance': (y_intersection - player_position.y) * f_i_sin_table[ray_degree],
				'texture_offset': fmod(y_intersection, grid_unit_size)}
			i += 1

		else:
			x_intersection += _find_next_X_v_intersection(is_facing_left)
			y_intersection += _find_next_Y_v_intersection(ray_degree)

			var grid_x_coords = floor(x_intersection / grid_unit_size)
			var grid_y_coords = floor(y_intersection / grid_unit_size)

			if _wall_exists(grid_x_coords, grid_y_coords): #
				return {'distance': (y_intersection - player_position.y) * f_i_sin_table[ray_degree],
				'texture_offset': fmod(y_intersection, grid_unit_size)}
			if y_intersection < player_view_area.position.y \
				or y_intersection > player_view_area.end.y \
				or x_intersection < player_view_area.position.x \
				or x_intersection > player_view_area.end.x:
					break

# warning-ignore:unused_argument
func _find_first_X_v_intersection(ray_degree, player_position, is_facing_left):
	if is_facing_left:
		return (floor(player_position.x / grid_unit_size) * grid_unit_size)
	else:
		return ((floor(player_position.x / grid_unit_size) * grid_unit_size) + grid_unit_size)

func _find_first_Y_v_intersection(ray_degree, player_position, x_intersection):
	return ((x_intersection - player_position.x) * f_tan_table[ray_degree]) + player_position.y

func _find_next_X_v_intersection(is_facing_left):
	return -grid_unit_size if is_facing_left else grid_unit_size

func _find_next_Y_v_intersection(ray_degree):
	return f_y_step_table[ray_degree]

