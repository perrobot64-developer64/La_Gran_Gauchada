extends Node2D

@onready var fade = $fade
var next_scene = ""
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$fade.connect("animation_finished", Callable(self, "_on_fade_finished"))
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_atras_pressed() -> void:
	next_scene = "res://addons/Chess/Main menu/main_menu.tscn"
	$fade.play("out")
	pass # Replace with function body.
	

func _on_fade_finished(anim_name: String) -> void:
	# Verifica que la animación terminada sea 'fade_out'
	if anim_name == "out":
		if next_scene == "main_menu":
			get_tree().quit()
		else:
			get_tree().change_scene_to_file(next_scene)
