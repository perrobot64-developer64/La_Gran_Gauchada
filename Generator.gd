extends FlowContainer

@export var Board_X_Size = 8
@export var Board_Y_Size = 8

@export var Tile_X_Size: int = 50
@export var Tile_Y_Size: int = 50

@warning_ignore("unused_signal")
signal send_location

# Función para obtener el color de la pieza
func GetPieceColor(piece):
	if piece.Item_Color == 1:
		return "Blanca"
	elif piece.Item_Color == 0:
		return "Negra"
	else:
		return "Color desconocido"

func _ready():
	# Evitar números negativos
	if Board_X_Size < 0 || Board_Y_Size < 0:
		return

	var Number_X = 0
	var Number_Y = 0
	# Configurar el tablero
	while Number_Y != Board_Y_Size:
		self.size.y += Tile_Y_Size + 5
		self.size.x += Tile_X_Size + 5
		while Number_X != Board_X_Size:
			var temp = Button.new()
			temp.set_custom_minimum_size(Vector2(Tile_X_Size, Tile_Y_Size))
			temp.connect("pressed", func():
				emit_signal("send_location", temp.name))
			temp.set_name(str(Number_X) + "-" + str(Number_Y))
			add_child(temp)
			Number_X += 1
		Number_Y += 1
		Number_X = 0
	Regular_Game()

func Regular_Game():
	# Piezas blancas
	get_node("0-0").add_child(Summon("Rook", 1))  # 1 significa blanca
	get_node("1-0").add_child(Summon("Knight", 1))
	get_node("2-0").add_child(Summon("Bishop", 1))
	get_node("3-0").add_child(Summon("Queen", 1))
	get_node("4-0").add_child(Summon("King", 1))
	get_node("5-0").add_child(Summon("Bishop", 1))
	get_node("6-0").add_child(Summon("Knight", 1))
	get_node("7-0").add_child(Summon("Rook", 1))

	get_node("0-1").add_child(Summon("Pawn", 1))  # 1 significa blanca
	get_node("1-1").add_child(Summon("Pawn", 1))
	get_node("2-1").add_child(Summon("Pawn", 1))
	get_node("3-1").add_child(Summon("Pawn", 1))
	get_node("4-1").add_child(Summon("Pawn", 1))
	get_node("5-1").add_child(Summon("Pawn", 1))
	get_node("6-1").add_child(Summon("Pawn", 1))
	get_node("7-1").add_child(Summon("Pawn", 1))

	# Piezas negras
	get_node("0-7").add_child(Summon("Rook", 0))  # 0 significa negra
	get_node("1-7").add_child(Summon("Knight", 0))
	get_node("2-7").add_child(Summon("Bishop", 0))
	get_node("3-7").add_child(Summon("Queen", 0))
	get_node("4-7").add_child(Summon("King", 0))
	get_node("5-7").add_child(Summon("Bishop", 0))
	get_node("6-7").add_child(Summon("Knight", 0))
	get_node("7-7").add_child(Summon("Rook", 0))

	get_node("0-6").add_child(Summon("Pawn", 0))  # 0 significa negra
	get_node("1-6").add_child(Summon("Pawn", 0))
	get_node("2-6").add_child(Summon("Pawn", 0))
	get_node("3-6").add_child(Summon("Pawn", 0))
	get_node("4-6").add_child(Summon("Pawn", 0))
	get_node("5-6").add_child(Summon("Pawn", 0))
	get_node("6-6").add_child(Summon("Pawn", 0))
	get_node("7-6").add_child(Summon("Pawn", 0))

func Summon(Piece_Name: String, color: int):
	var Piece
	match Piece_Name:
		"Pawn":
			Piece = Pawn.new()
			Piece.name = "Pawn"
		"King":
			Piece = King.new()
			Piece.name = "King"
		"Queen":
			Piece = Queen.new()
			Piece.name = "Queen"
		"Knight":
			Piece = Knight.new()
			Piece.name = "Knight"
		"Rook":
			Piece = Rook.new()
			Piece.name = "Rook"
		"Bishop":
			Piece = Bishop.new()
			Piece.name = "Bishop"
	
	# Asignamos el color de la pieza
	Piece.Item_Color = color
	
	# Establecer la posición de la pieza en el centro de la casilla
	Piece.position = Vector2(Tile_X_Size / 2.0, Tile_Y_Size / 2.0)
	return Piece
