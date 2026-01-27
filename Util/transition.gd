extends CanvasLayer

@export var fadeColor: Color
@export var speed: float = 0.1  # How fast to lerp each step (0 < speed < 1)
var fading := false

func start_transition(color: Color = fadeColor) -> bool:
	if fading:
		return false
	fading = true
	while abs($ColorRect.color.a - color.a) > 0.01:
		$ColorRect.color = lerp($ColorRect.color, color, speed)
		await get_tree().create_timer(0.016).timeout  # ~60 FPS
	# Ensure final color is set exactly
	$ColorRect.color = color
	return true

func return_to_original() -> bool:
	if !fading: return false
	var target = Color(0, 0, 0, 0)
	await get_tree().create_timer(0.1).timeout
	while abs($ColorRect.color.a - target.a) > 0.01:
		$ColorRect.color = lerp($ColorRect.color, target, speed)
		await get_tree().create_timer(0.016).timeout
	$ColorRect.color = target
	fading = false
	return true

func flicker(delay := 0.05, count := 50, color: Color = Color(1, 0, 0, 0.8)):
	for i in range(count):
		if $ColorRect.color == color:
			$ColorRect.color = Color(0, 0, 0, 0)
		else:
			$ColorRect.color = color
		await get_tree().create_timer(delay).timeout

func fade_to_scene(target_scene: String, color: Color = fadeColor) -> void:
	await start_transition(color)
	get_tree().call_deferred("change_scene_to_file", target_scene)
	await return_to_original()

func fade_to_location(target_location: Vector3, subject, color: Color = fadeColor) -> bool:
	await start_transition(color)
	subject.global_position = target_location
	await return_to_original()
	return true
