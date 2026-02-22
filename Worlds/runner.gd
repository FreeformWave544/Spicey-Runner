extends Node2D

@export var modules: Array[PackedScene]
@export var module_offset: float=1152.0
@export var modules_to_keep_ahead: int=10
@export var scroll_speed: float=150.0
@export var follow_strength: float=0.25
@export var camera_smoothness: float=2.5
const POOL_SIZE := 100
var gameSpeed := Vector2(0,0)
var ScrollDirection := 1.0
var modules_in := 0
var module_container: Node2D
var last_module_end_x := 0.0
var player: Node2D
var world_scroll_x := 0.0
var BaseScroll := 0.0
var invert := false
var canSpin := true
var timeSurvived := 0.0
var module_pool: Array[Node2D]=[]

func _ready() -> void:
	BaseScroll = scroll_speed
	module_container = $ModuleContainer
	player = find_child("Player")
	await get_tree().create_timer(0.1).timeout
	_init_pool()
	if name != "Level": return
	spawn_modules(modules_to_keep_ahead, 666)
	$ModuleContainer/START.queue_free()

func _init_pool() -> void:
	if modules.is_empty():
		push_warning("No modules assigned.")
		return
	for i in range(POOL_SIZE):
		var module: Node2D = modules.pick_random().instantiate()
		module.visible = false
		module.process_mode = Node.PROCESS_MODE_DISABLED
		module_container.add_child(module)
		module_pool.append(module)

func spawn_modules(count:int = 1, start_offset := 0.0) -> void:
	if module_pool.is_empty(): _init_pool()
	if modules_in == 0 and start_offset > 0.0: last_module_end_x = start_offset
	for i in range(count):
		if module_pool.is_empty(): return
		var module = module_pool.pop_back()
		module.visible = true
		module.process_mode = Node.PROCESS_MODE_INHERIT
		module.position.x = last_module_end_x
		last_module_end_x += module_offset

func _recycle_module(module:Node2D) -> void:
	module.visible = false
	module.process_mode = Node.PROCESS_MODE_DISABLED
	module_pool.append(module)

func _process(delta:float) -> void:
	if not player or not player.canMove: return
	timeSurvived += delta
	$Score.text = "Time: %.2f" % timeSurvived
	var ramp = lerp(1.0, 2.0, clamp(timeSurvived / 120.0, 0.0, 1.0))
	var speed = BaseScroll * ramp * ScrollDirection
	world_scroll_x += speed * delta
	var target_x := -world_scroll_x + (player.position.x * follow_strength)
	module_container.position.x = lerp(module_container.position.x, target_x, camera_smoothness * delta)

func togglePlane() -> void:
	if not canSpin: return
	canSpin = false
	invert = !invert
	player.spin(invert)

func _on_deathzone_area_entered(area:Area2D) -> void:
	if area.name == "START":
		spawn_modules(modules_to_keep_ahead, 666)
		area.queue_free()
	elif area.is_in_group("moduleEND"):
		modules_in += 1
		if modules_in >= modules_to_keep_ahead:
			modules_in = 0
			spawn_modules(modules_to_keep_ahead)
		var p := area.get_parent()
		_recycle_module(p)
		spawn_modules(1)

func _on_deathzone_body_entered(body:Node2D)->void:
	if body is Player:
		$UI/GameOver/Label.text = "Score: %.2f\nDistance: %.2f\nTime: %.2f" % [(world_scroll_x + 0.5 * (world_scroll_x/timeSurvived)) / 50.0, world_scroll_x, timeSurvived]
		$UI.lose()

func screen_shake(time := 0.5,intensity := 0.5):
	var timer := get_tree().create_timer(time)
	while timer.time_left>0.0:
		$Camera2D.offset = Vector2(randf_range(-5,5) * intensity, randf_range(-5,5) * intensity)
		$Camera2D.rotation_degrees = randf_range(-2,2) * intensity
		if !is_inside_tree():return
		await get_tree().process_frame
	$Camera2D.rotation_degrees=0
	$Camera2D.offset=Vector2.ZERO
