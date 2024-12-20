extends Control

var Selected_Node = ""
var Turn = 0
var Location_X = ""
var Location_Y = ""
var pos = Vector2(25, 25)
var Areas: PackedStringArray
var Special_Area: PackedStringArray

var Start_Y = -1  # Valor inicial de Start_Y
var Item_Color = 0  # 0 para piezas blancas, 1 para piezas negras
var Double_Start = true  # Indicador de si se permite el movimiento de dos casillas
var game_over = false


var timer_paused: bool = false  # Indica si el temporizador está pausado
@onready var pause_button = $PauseButton  # Referencia al botón de pausa
@onready var fade = $fade
var next_scene = ""
@onready var tiempo_label = $TiempoLabel
@onready var timer = $Timer  # Asegúrate de que el temporizador está configurado en el editor
# Temporizador
var timer_start_time: float = 0.0
var timer_running: bool = false

# Nuevas variables para almacenar las fichas capturadas
var captured_white_pieces = []  # Lista de fichas blancas capturadas
var captured_black_pieces = []  # Lista de fichas negras capturadas
var positions_history = []  # Para el historial de posiciones del tablero
var partida_duracion = 0
var partida_activa = false

func _on_flow_send_location(location: String):
	if game_over:
		return  # No permitir más movimientos si el juego terminó
	
	var number = 0
	Location_X = ""
	var node = get_node("Flow/" + location)
	
	# Procesar coordenadas X e Y
	while location.substr(number, 1) != "-":
		Location_X += location.substr(number, 1)
		number += 1
	Location_Y = location.substr(number + 1)
	
	if Selected_Node == "" and node.get_child_count() != 0 and node.get_child(0).Item_Color == Turn:
		Selected_Node = location
		Get_Moveable_Areas()
	elif Selected_Node != "" and node.get_child_count() != 0 and node.get_child(0).Item_Color == Turn and node.get_child(0).name == "Rook":
		# Enroque
		for i in Areas:
			if i == node.name:
				var king = get_node("Flow/" + Selected_Node).get_child(0)
				var rook = node.get_child(0)
				king.reparent(get_node("Flow/" + Special_Area[1]))
				rook.reparent(get_node("Flow/" + Special_Area[0]))
				king.position = pos
				rook.position = pos
				Update_Game(king.get_parent())
	# En Passant
	elif Selected_Node != "" and node.get_child_count() != 0 and node.get_child(0).Item_Color != Turn and node.get_child(0).name == "Pawn" and Special_Area.size() != 0 and Special_Area[0] == node.name and node.get_child(0).get("En_Passant") == true:
		for i in Special_Area:
			if i == node.name:
				var pawn = get_node("Flow/" + Selected_Node).get_child(0)
				node.get_child(0).free()
				pawn.reparent(get_node("Flow/" + Special_Area[1]))
				pawn.position = pos
				Update_Game(pawn.get_parent())
	elif Selected_Node != "" and node.get_child_count() != 0 and node.get_child(0).Item_Color == Turn:
		# Re-selección
		Selected_Node = location
		Get_Moveable_Areas()
	elif Selected_Node != "" and node.get_child_count() != 0 and node.get_child(0).Item_Color != Turn:
		# Captura de pieza
		for i in Areas:
			if i == node.name:
				var Piece = get_node("Flow/" + Selected_Node).get_child(0)
				# Condiciones de victoria
# Verifica si el rey de las blancas o las negras ha sido capturado
				if node.get_child(0).name == "King":
					var king = node.get_child(0)
					
					# Verifica si es el rey de las blancas o de las negras
					if king.Item_Color == 1:  # Si el color es 1, es el rey blanco
						print("¡Victoria! Las blancas han ganado.")
						$win.visible = true
						$win/AnimationPlayer.play("win blancas")  # Suponiendo que 'win negras' es la animación para la victoria de las blancas
						$Button.visible = true
						game_over = true
					elif king.Item_Color == 0:  # Si el color es 0, es el rey negro
						print("¡Victoria! Las negras han ganado.")
						$win.visible = true
						$win/AnimationPlayer.play("win negras")  # Suponiendo que 'win blancas' es la animación para la victoria de las negras
						$Button.visible = true
						game_over = true

					stop_timer()


				# Almacenar la ficha capturada
				var captured_piece = node.get_child(0)
				store_captured_piece(captured_piece)
				
				captured_piece.free()
				Piece.reparent(node)
				Piece.position = pos
				Update_Game(node)
	elif Selected_Node != "" and node.get_child_count() == 0:
		# Mover pieza
		for i in Areas:
			if i == node.name:
				var Piece = get_node("Flow/" + Selected_Node).get_child(0)
				Piece.reparent(node)
				Piece.position = pos
				Update_Game(node)
				on_piece_moved()
	if not partida_activa:
		pass

	#if partida_activa:
		#detener_partida()


@warning_ignore("unused_parameter")
func Update_Game(node):
	Selected_Node = ""
	Turn = (Turn + 1) % 2
	Clear_Areas(get_node("Flow"))
	Areas.clear()
	Special_Area.clear()
	Update_Pieces_Visibility()

func store_captured_piece(captured_piece):
	# Crear una copia profunda de la pieza capturada
	var duplicated_piece = captured_piece.duplicate(true)
	duplicated_piece.set_position(Vector2.ZERO)  # Asegúrate de que la posición sea coherente para el contenedor

	# Añadir la ficha capturada a la lista correspondiente
	if captured_piece.Item_Color == 0:  # Pieza blanca
		captured_white_pieces.append(duplicated_piece)
	else:  # Pieza negra
		captured_black_pieces.append(duplicated_piece)

	# Liberar la pieza original del tablero
	captured_piece.queue_free()

	# Actualizar visualización de piezas capturadas
	update_captured_display()


func update_captured_display():
	var white_container = get_node("CapturedWhite")
	var black_container = get_node("CapturedBlack")

	if white_container == null or black_container == null:
		print("Error: No se encontraron los contenedores de piezas capturadas.")
		return

	# Limpia los contenedores eliminando a todos sus hijos
	for child in white_container.get_children():
		child.queue_free()
	for child in black_container.get_children():
		child.queue_free()

	# Define la distancia entre las fichas en la fila
	var spacing = 30

	# Agrega las piezas capturadas actuales a los contenedores en fila
	for i in range(captured_white_pieces.size()):
		var new_piece = captured_white_pieces[i].duplicate(true)
		new_piece.position = Vector2(i * spacing, 0)  # Posiciona en fila
		white_container.add_child(new_piece)

	for i in range(captured_black_pieces.size()):
		var new_piece = captured_black_pieces[i].duplicate(true)
		new_piece.position = Vector2(i * spacing, 0)  # Posiciona en fila
		black_container.add_child(new_piece)

func Get_Moveable_Areas():
	var Flow = get_node("Flow")
	Areas.clear()
	Special_Area.clear()
	var Piece = get_node("Flow/" + Selected_Node).get_child(0)
	
	# Obtener áreas movibles según el tipo de pieza
	if Piece.name == "Pawn":
		Get_Pawn(Piece, Flow)
	elif Piece.name == "Bishop":
		Get_Diagonals(Flow)
	elif Piece.name == "King":
		Get_Around(Piece)
	elif Piece.name == "Queen":
		Get_Diagonals(Flow)
		Get_Rows(Flow)
	elif Piece.name == "Rook":
		Get_Rows(Flow)
	elif Piece.name == "Knight":
		Get_Horse()

	# Cambiar el color de las casillas disponibles
	Highlight_Areas(Flow)

func Clear_Areas(Flow):
	# Reiniciar colores de todas las casillas
	for child in Flow.get_children():
		child.modulate = Color(1, 1, 1)  # Color original (blanco)

func Highlight_Areas(Flow):
	# Reiniciar colores de todas las casillas
	Clear_Areas(Flow)

	# Cambiar color de las áreas seleccionadas
	for area in Areas:
		var square = Flow.get_node(area)
		if square:
			if square.get_child_count() == 0 or (square.get_child_count() == 1 and square.get_child(0).Item_Color != Turn):
				square.modulate = Color(0, 1, 1)  # Verde

	var new_areas = PackedStringArray()
	for area in Areas:
		var can_add = true
		for child in Flow.get_children():
			if child.get_child_count() != 0 and child.get_child(0).Item_Color == Turn:
				if child.name == area:
					can_add = false
					break
		if can_add:
			new_areas.append(area)

	Areas = new_areas

func Get_Pawn(Piece, Flow):
	$AnimationPlayer_cha_b.play("peon")

	# Movimiento de los peones blancos (de abajo hacia arriba)
	if Piece.Item_Color == 0:  # Pieza blanca
		# Verifica si la casilla de enfrente está vacía para permitir el movimiento
		if not Is_Null(Location_X + "-" + str(int(Location_Y) - 1)) and Flow.get_node(Location_X + "-" + str(int(Location_Y) - 1)).get_child_count() == 0:
			Areas.append(Location_X + "-" + str(int(Location_Y) - 1))
		
		# Si está en su posición inicial, permite mover dos casillas (Y = 6)
		if int(Location_Y) == 6:
			if not Is_Null(Location_X + "-" + str(int(Location_Y) - 2)) and Flow.get_node(Location_X + "-" + str(int(Location_Y) - 2)).get_child_count() == 0:
				Areas.append(Location_X + "-" + str(int(Location_Y) - 2))

		# Si el peón ha llegado a la casilla Y = 4, desactivamos el movimiento doble
		if int(Location_Y) <= 4:
			Piece.Double_Start = false

		# Casillas de ataque en diagonal
		if not Is_Null(str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)) and Flow.get_node(str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)).get_child_count() == 1:
			Areas.append(str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1))
		if not Is_Null(str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)) and Flow.get_node(str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)).get_child_count() == 1:
			Areas.append(str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1))

	# Movimiento de los peones negros (de arriba hacia abajo)
	else:  # Pieza negra
		# Verifica si la casilla de enfrente está vacía para permitir el movimiento
		if not Is_Null(Location_X + "-" + str(int(Location_Y) + 1)) and Flow.get_node(Location_X + "-" + str(int(Location_Y) + 1)).get_child_count() == 0:
			Areas.append(Location_X + "-" + str(int(Location_Y) + 1))
		
		# Si está en su posición inicial, permite mover dos casillas (Y = 1)
		if int(Location_Y) == 1:
			if not Is_Null(Location_X + "-" + str(int(Location_Y) + 2)) and Flow.get_node(Location_X + "-" + str(int(Location_Y) + 2)).get_child_count() == 0:
				Areas.append(Location_X + "-" + str(int(Location_Y) + 2))

		# Si el peón ha llegado a la casilla Y = 4, desactivamos el movimiento doble
		if int(Location_Y) >= 4:
			Piece.Double_Start = false

		# Casillas de ataque en diagonal
		if not Is_Null(str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)) and Flow.get_node(str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)).get_child_count() == 1:
			Areas.append(str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1))
		if not Is_Null(str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)) and Flow.get_node(str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)).get_child_count() == 1:
			Areas.append(str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1))

func Get_Around(Piece):#reyna
	$AnimationPlayer_cha_b.play("reyna")
	# Single Rows
	if not Is_Null(Location_X + "-" + str(int(Location_Y) + 1)):
		Areas.append(Location_X + "-" + str(int(Location_Y) + 1))
	if not Is_Null(Location_X + "-" + str(int(Location_Y) - 1)):
		Areas.append(Location_X + "-" + str(int(Location_Y) - 1))
	if not Is_Null(str(int(Location_X) + 1) + "-" + Location_Y):
		Areas.append(str(int(Location_X) + 1) + "-" + Location_Y)
	if not Is_Null(str(int(Location_X) - 1) + "-" + Location_Y):
		Areas.append(str(int(Location_X) - 1) + "-" + Location_Y)
	# Diagonal
	if not Is_Null(str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1)):
		Areas.append(str(int(Location_X) + 1) + "-" + str(int(Location_Y) + 1))
	if not Is_Null(str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1)):
		Areas.append(str(int(Location_X) - 1) + "-" + str(int(Location_Y) + 1))
	if not Is_Null(str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1)):
		Areas.append(str(int(Location_X) + 1) + "-" + str(int(Location_Y) - 1))
	if not Is_Null(str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1)):
		Areas.append(str(int(Location_X) - 1) + "-" + str(int(Location_Y) - 1))
	# Castling, if that is the case
	if Piece.Castling == true:
		Castle()

func Get_Rows(Flow):#rey
	$AnimationPlayer_cha_b.play("rey")
	var Add_X = 1
	# Getting the horizontal rows first.
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + Location_Y):
		Areas.append(str(int(Location_X) + Add_X) + "-" + Location_Y)
		if Flow.get_node(str(int(Location_X) + Add_X) + "-" + Location_Y).get_child_count() != 0:
			break
		Add_X += 1
	Add_X = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + Location_Y):
		Areas.append(str(int(Location_X) - Add_X) + "-" + Location_Y)
		if Flow.get_node(str(int(Location_X) - Add_X) + "-" + Location_Y).get_child_count() != 0:
			break
		Add_X += 1
	var Add_Y = 1
	# Now we are getting the vertical rows.
	while not Is_Null(Location_X + "-" + str(int(Location_Y) + Add_Y)):
		Areas.append(Location_X + "-" + str(int(Location_Y) + Add_Y))
		if Flow.get_node(Location_X + "-" + str(int(Location_Y) + Add_Y)).get_child_count() != 0:
			break
		Add_Y += 1
	Add_Y = 1
	while not Is_Null(Location_X + "-" + str(int(Location_Y) - Add_Y)):
		Areas.append(Location_X + "-" + str(int(Location_Y) - Add_Y))
		if Flow.get_node(Location_X + "-" + str(int(Location_Y) - Add_Y)).get_child_count() != 0:
			break
		Add_Y += 1
	
func Get_Diagonals(Flow):
	$AnimationPlayer_cha_b.play("alfil")
	var Add_X = 1
	var Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		Areas.append(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) + Add_Y)).get_child_count() != 0:
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y)):
		Areas.append(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y))
		if Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) + Add_Y)).get_child_count() != 0:
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		Areas.append(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if Flow.get_node(str(int(Location_X) + Add_X) + "-" + str(int(Location_Y) - Add_Y)).get_child_count() != 0:
			break
		Add_X += 1
		Add_Y += 1
	Add_X = 1
	Add_Y = 1
	while not Is_Null(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y)):
		Areas.append(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y))
		if Flow.get_node(str(int(Location_X) - Add_X) + "-" + str(int(Location_Y) - Add_Y)).get_child_count() != 0:
			break
		Add_X += 1
		Add_Y += 1

func Get_Horse():
	$AnimationPlayer_cha_b.play("caballo")
	var The_X = 2
	var The_Y = 1
	var number = 0
	while number != 8:
		# So this one is interesting. This is most likely the cleanest code here.
		# Get the numbers, replace the numbers, and loop until it stops.
		if not Is_Null(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y)):
			Areas.append(str(int(Location_X) + The_X) + "-" + str(int(Location_Y) + The_Y))
		number += 1
		match number:
			1:
				The_X = 1
				The_Y = 2
			2:
				The_X = -2
				The_Y = 1
			3:
				The_X = -1
				The_Y = 2
			4:
				The_X = 2
				The_Y = -1
			5:
				The_X = 1
				The_Y = -2
			6:
				The_X = -2
				The_Y = -1
			7:
				The_X = -1
				The_Y = -2

func Castle():
	# This is the castling section right here, used if a person wants to castle.
	var Flow = get_node("Flow")
	var X_Counter = 1
	# These are very similar to gathering a row, except we want free tiles and a rook
	# Counting up
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter += 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) + 2) + "-" + Location_Y)
	# Counting down
	X_Counter = -1
	while not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child_count() == 0:
		X_Counter -= 1
	if not Is_Null(str(int(Location_X) + X_Counter) + "-" + Location_Y) && Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).name == "Rook":
		if Flow.get_node(str(int(Location_X) + X_Counter) + "-" + Location_Y).get_child(0).Castling == true:
			Areas.append(str(int(Location_X) + X_Counter) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 1) + "-" + Location_Y)
			Special_Area.append(str(int(Location_X) - 2) + "-" + Location_Y)

# One function that shortens everything. Its also a pretty good way to see if we went off the board or not.
func Is_Null(Location):
	if get_node_or_null("Flow/" + Location) == null:
		return true
	else:
		return false 

func _ready():
	
	$fade.connect("animation_finished", Callable(self, "_on_fade_finished"))
	$Button.visible = false
	$win.visible = false
	# Inicialización
	timer_start_time = 0.0
	timer_running = false

# Esta función se llama cuando se mueve una ficha
func on_piece_moved():
	if not timer_running:
		start_timer()

# Inicia el temporizador
func start_timer():
	timer_start_time = Time.get_ticks_msec() / 1000.0  # Tiempo actual en segundos
	timer_running = true
	print("El temporizador ha comenzado.")

# Obtiene el tiempo transcurrido
func get_elapsed_time() -> float:
	if timer_running:
		return Time.get_ticks_msec() / 1000.0 - timer_start_time
	return 0.0

# Se ejecuta en cada cuadro para actualizar el tiempo
@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	if timer_running:
		actualizar_tiempo_label()

# Actualiza el label con la duración actual de la partida en formato de minutos y segundos
func actualizar_tiempo_label():
	@warning_ignore("shadowed_variable")
	var partida_duracion = get_elapsed_time()
	@warning_ignore("integer_division")
	var minutos = int(partida_duracion) / 60
	var segundos = int(partida_duracion) % 60
	tiempo_label.text = str(minutos) + ":" + str(segundos).pad_zeros(2)
	
# Detiene el temporizador
func stop_timer():
	if timer_running:
		timer_running = false
		print("El temporizador se ha detenido. Tiempo total: ", get_elapsed_time(), " segundos.")
	timer.stop()
	timer_paused = true
	pause_button.disabled = true  # Desactiva el botón de pausa

func Update_Pieces_Visibility():
	var Flow = get_node("Flow")
	
	# Iterar a través de todas las casillas en el tablero
	for square in Flow.get_children():
		if square.get_child_count() > 0:
			var piece = square.get_child(0)
			
			# Comprobar si la pieza es blanca o negra y cambiar su visibilidad según el turno
			if piece.Item_Color == 0:  # Pieza blanca
				$Blancas.visible = (Turn == 0)  # Solo visible si es el turno de las blancas
				$Blancas/AnimationPlayer.play("turno")
			else:  # Pieza negra
				$Negras.visible = (Turn == 1)  # Solo visible si es el turno de las negras
				$Negras/AnimationPlayer.play("turno")

func _on_button_pressed() -> void:
	get_tree().reload_current_scene()
	print("reintentar")
	pass # Replace with function body.


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

func _on_pause_button_pressed():
	if game_over:
		return

	timer_paused = not timer_paused
	get_tree().paused = timer_paused  # Esto pausa todo el árbol de nodos excepto los nodos marcados como "Process in Pause".
	if timer_paused:
		print("Juego pausado")
		pause_button.text = "Reanudar"  # Cambiar texto del botón
	else:
		pause_button.text = "Pausar"  # Cambiar texto del botón
		print("Juego reanudado")
		


# Función para pausar o reanudar el juego
func set_game_paused(paused: bool):
	for child in get_node("Flow").get_children():
		if child.get_child_count() > 0:
			for piece in child.get_children():
				piece.set_process(!paused)  # Pausar o reanudar el procesamiento de piezas
