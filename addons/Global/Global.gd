extends Node

var is_fullscreen: bool = false  # Variable para controlar si está en pantalla completa

@warning_ignore("untyped_declaration")
func _input(event: InputEvent): # Salir del juego con ESC
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			get_tree().quit()
		elif event.keycode == KEY_F11:  # Detectar si se pulsa F11
			toggle_fullscreen()

# Método para alternar entre pantalla completa y modo ventana
func toggle_fullscreen() -> void:
	is_fullscreen = !is_fullscreen  # Alternar el estado
	
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	print("Pantalla completa:", is_fullscreen)

func _ready() -> void:
	# Establece el tamaño mínimo de la ventana
	DisplayServer.window_set_min_size(Vector2(800, 450))
