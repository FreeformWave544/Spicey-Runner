extends Control

func _ready() -> void:
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

func lose():
	get_tree().paused = true
	$GameOver.show()

func pause():
	get_tree().paused = !get_tree().paused

func _unhandled_input(_event: InputEvent) -> void: if Input.is_action_just_pressed("ui_cancel"):
	pause()
