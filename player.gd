extends CharacterBody2D
class_name Player

@export var JUMP_VELOCITY := -400.0
@export var gravity := 900.0

var canMove := true

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ray: RayCast2D = $Sprite/RayCast2D

enum Flooring { REGULAR, ICY, BOUNCY }
var currentFloor := Flooring.REGULAR
var previous_floor := Flooring.REGULAR

func _physics_process(delta: float) -> void:
	if not canMove:
		return

	var level = get_parent()
	var input_dir := Input.get_axis("left", "right")

	# Gravity + jump
	if not level.invert:
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		velocity.y += gravity * delta if not is_on_floor() else 0.0
	else:
		if Input.is_action_just_pressed("jump") and is_on_ceiling():
			velocity.y = -JUMP_VELOCITY
		velocity.y -= gravity * delta if not is_on_ceiling() else 0.0

	if input_dir > 0:
		level.ScrollDirection = 1
	elif input_dir < 0:
		level.ScrollDirection = -1
	if input_dir != 0:
		sprite.flip_h = input_dir < 0

	previous_floor = currentFloor
	move_and_slide()
	currentFloor = get_floor_type()

func _unhandled_input(_event) -> void:
	if not canMove:
		return

	if Input.is_action_just_pressed("flip"):
		get_parent().togglePlane()

func spin(invert: bool) -> void:
	velocity.y = -100

	var target := deg_to_rad(22) if invert else 0.0
	while not is_equal_approx(sprite.rotation, target):
		sprite.rotation = lerp(sprite.rotation, target, 0.2)
		await get_tree().process_frame

	get_parent().canSpin = true

func get_floor_type() -> Flooring:
	if not ray.is_colliding():
		return Flooring.REGULAR

	var collider := ray.get_collider()
	if collider is TileMap:
		var local = collider.to_local(ray.get_collision_point())
		var cell = collider.local_to_map(local)
		var data = collider.get_cell_tile_data(0, cell)
	return Flooring.REGULAR
