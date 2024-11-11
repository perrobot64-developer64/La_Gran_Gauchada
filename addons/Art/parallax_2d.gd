extends ParallaxBackground

# Velocidad de movimiento
var speed_y: float = 50.0  # Velocidad en el eje Y

func _ready() -> void:
	# Configurar el mirroring solo en el eje Y en todas las capas
	for parallax_layer in get_children():
		if parallax_layer is ParallaxLayer:
			# Asegurarse de que el ParallaxLayer tiene un hijo con textura
			if parallax_layer.get_child_count() > 0:
				var child: Sprite2D = parallax_layer.get_child(0) as Sprite2D
				if child.texture:
					var texture_size_y: float = child.texture.get_size().y
					# Configura el mirroring solo en el eje Y
					parallax_layer.motion_mirroring = Vector2(0.0, texture_size_y)

func _process(delta: float) -> void:
	# Mover cada ParallaxLayer para crear el efecto de desplazamiento infinito
	for parallax_layer in get_children():
		if parallax_layer is ParallaxLayer:
			# Actualizar la posición del motion_offset en Y
			parallax_layer.motion_offset.y -= speed_y * delta  # Mover en el eje Y
			
			# Reiniciar el motion_offset en Y para evitar desbordamientos y saltos
			var texture_size_y: float = parallax_layer.motion_mirroring.y
			if parallax_layer.motion_offset.y <= -texture_size_y:
				parallax_layer.motion_offset.y += texture_size_y
