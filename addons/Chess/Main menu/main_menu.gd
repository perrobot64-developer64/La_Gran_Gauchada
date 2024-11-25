extends Node2D

# Referencia al nodo AnimationPlayer que controla el fade
var fade = $fade

# Variable para almacenar la escena a la que se quiere cambiar
var next_scene = ""

func _ready() -> void:
	# Conectar la señal animation_finished al método _on_fade_finished
	$fade.connect("animation_finished", Callable(self, "_on_fade_finished"))

func _on_jugar_pressed() -> void:
	# Configura la próxima escena y comienza la animación de fade
	next_scene = "res://addons/Art/board.tscn"
	$fade.play("out")  # Asegúrate de tener una animación llamada 'fade_out'


func _on_creditos_pressed() -> void:
	# Configura la próxima escena y comienza la animación de fade
	next_scene = "res://addons/Chess/Creditos/creditos.tscn"
	$fade.play("out")


func _on_salir_pressed() -> void:
	# Comienza la animación de fade antes de salir
	next_scene = "quit"
	$fade.play("out")


func _on_fade_finished(anim_name: String) -> void:
	# Verifica que la animación terminada sea 'fade_out'
	if anim_name == "out":
		if next_scene == "quit":
			get_tree().quit()
		else:
			get_tree().change_scene_to_file(next_scene)
