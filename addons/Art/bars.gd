extends ParallaxBackground

# Velocidad de movimiento
var speed_x: float = 50.0  # Velocidad en el eje X

func _ready() -> void:
	# Configurar el mirroring solo en el eje X en todas las capas
	for parallax_layer in get_children():
		if parallax_layer is ParallaxLayer:
			# Asegurarse de que el ParallaxLayer tiene un hijo con textura
			if parallax_layer.get_child_count() > 0:
				var child: Sprite2D = parallax_layer.get_child(0) as Sprite2D
				if child.texture:
					var texture_size_x: float = child.texture.get_size().x
					# Configura el mirroring solo en el eje X
					parallax_layer.motion_mirroring = Vector2(texture_size_x, 0.0)

func _process(delta: float) -> void:
	# Mover cada ParallaxLayer para crear el efecto de desplazamiento infinito
	for parallax_layer in get_children():
		if parallax_layer is ParallaxLayer:
			# Actualizar la posición del motion_offset en X
			parallax_layer.motion_offset.x -= speed_x * delta
			
			# Reiniciar el motion_offset en X para evitar desbordamientos y saltos
			var texture_size_x: float = parallax_layer.motion_mirroring.x
			if parallax_layer.motion_offset.x <= -texture_size_x:
				parallax_layer.motion_offset.x += texture_size_x
