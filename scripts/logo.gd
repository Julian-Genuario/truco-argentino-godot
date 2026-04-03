class_name Logo
extends Control

## Logo del juego "Quiero Vale 4" dibujado con _draw().
## Incluye cartas decorativas, titulo estilizado y subtitulo.

var _time: float = 0.0
var _cartas_decorativas: Array = []

func _ready() -> void:
	custom_minimum_size = Vector2(600, 320)
	# Generar cartas decorativas de fondo
	_cartas_decorativas = [
		{"num": "1", "palo": "\u2694", "rot": -0.2, "x": 0.18, "y": 0.35, "color": Color(0.25, 0.45, 0.85)},
		{"num": "7", "palo": "\u2B50", "rot": 0.15, "x": 0.82, "y": 0.35, "color": Color(0.9, 0.75, 0.1)},
		{"num": "4", "palo": "\u2665", "rot": -0.08, "x": 0.35, "y": 0.4, "color": Color(0.85, 0.2, 0.3)},
		{"num": "3", "palo": "\u2663", "rot": 0.12, "x": 0.65, "y": 0.4, "color": Color(0.2, 0.65, 0.3)},
	]


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0

	# Cartas decorativas de fondo (detras del titulo)
	for c in _cartas_decorativas:
		_dibujar_carta_deco(c)

	# Resplandor detras del titulo
	var glow_alpha: float = 0.08 + sin(_time * 1.5) * 0.03
	var glow_rect: Rect2 = Rect2(cx - 280, cy - 60, 560, 90)
	draw_rect(glow_rect, Color(1, 0.85, 0.3, glow_alpha), true)

	# Fondo del titulo - banner oscuro
	var banner_rect: Rect2 = Rect2(cx - 270, cy - 55, 540, 80)
	draw_rect(banner_rect, Color(0.08, 0.06, 0.04, 0.85), true)

	# Bordes dorados del banner
	draw_rect(banner_rect, Color(0.85, 0.65, 0.15, 0.9), false, 3.0)

	# Linea dorada superior e inferior decorativa
	draw_line(Vector2(cx - 250, cy - 48), Vector2(cx + 250, cy - 48), Color(0.85, 0.65, 0.15, 0.5), 1.0)
	draw_line(Vector2(cx - 250, cy + 18), Vector2(cx + 250, cy + 18), Color(0.85, 0.65, 0.15, 0.5), 1.0)

	# Titulo principal: "QUIERO VALE 4"
	var font: Font = ThemeDB.fallback_font

	# Sombra del texto
	var titulo: String = "QUIERO VALE 4"
	var titulo_size: int = 52
	var t_size: Vector2 = font.get_string_size(titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, titulo_size)
	var t_pos: Vector2 = Vector2(cx - t_size.x / 2.0, cy + 5)

	# Sombra
	draw_string(font, t_pos + Vector2(3, 3), titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, titulo_size, Color(0, 0, 0, 0.6))

	# Texto principal con color dorado brillante
	var pulse: float = 0.9 + sin(_time * 2.0) * 0.1
	var titulo_color: Color = Color(1.0 * pulse, 0.85 * pulse, 0.25, 1.0)
	draw_string(font, t_pos, titulo, HORIZONTAL_ALIGNMENT_LEFT, -1, titulo_size, titulo_color)

	# Subtitulo: "EL JUEGO DE TRUCO ARGENTINO"
	var sub: String = "EL JUEGO DE TRUCO ARGENTINO"
	var sub_size: int = 16
	var s_size: Vector2 = font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size)
	var s_pos: Vector2 = Vector2(cx - s_size.x / 2.0, cy + 40)
	draw_string(font, s_pos, sub, HORIZONTAL_ALIGNMENT_LEFT, -1, sub_size, Color(0.75, 0.7, 0.6, 0.9))

	# Decoraciones laterales del banner - diamantes
	_dibujar_diamante(Vector2(cx - 260, cy - 15), 8.0, Color(0.85, 0.65, 0.15, 0.7))
	_dibujar_diamante(Vector2(cx + 260, cy - 15), 8.0, Color(0.85, 0.65, 0.15, 0.7))

	# Lineas laterales
	draw_line(Vector2(cx - 300, cy - 15), Vector2(cx - 272, cy - 15), Color(0.85, 0.65, 0.15, 0.5), 2.0)
	draw_line(Vector2(cx + 272, cy - 15), Vector2(cx + 300, cy - 15), Color(0.85, 0.65, 0.15, 0.5), 2.0)


func _dibujar_carta_deco(c: Dictionary) -> void:
	var px: float = size.x * c.x
	var py: float = size.y * c.y
	var w: float = 60.0
	var h: float = 85.0

	# Transformar para rotacion
	draw_set_transform(Vector2(px, py), c.rot, Vector2.ONE)

	# Sombra
	draw_rect(Rect2(Vector2(-w/2 + 2, -h/2 + 2), Vector2(w, h)), Color(0, 0, 0, 0.3), true)

	# Fondo carta
	draw_rect(Rect2(Vector2(-w/2, -h/2), Vector2(w, h)), Color(0.92, 0.89, 0.82, 0.6), true)

	# Borde
	draw_rect(Rect2(Vector2(-w/2, -h/2), Vector2(w, h)), Color(c.color.r, c.color.g, c.color.b, 0.5), false, 1.5)

	# Franja color
	draw_rect(Rect2(Vector2(-w/2, -h/2), Vector2(w, 3)), Color(c.color.r, c.color.g, c.color.b, 0.6), true)

	# Numero
	var font: Font = ThemeDB.fallback_font
	var num_size: Vector2 = font.get_string_size(c.num, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(font, Vector2(-num_size.x/2, 0), c.num, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(c.color.r, c.color.g, c.color.b, 0.7))

	# Simbolo
	var sym_size: Vector2 = font.get_string_size(c.palo, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	draw_string(font, Vector2(-sym_size.x/2, 18), c.palo, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(c.color.r, c.color.g, c.color.b, 0.6))

	# Reset transform
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


func _dibujar_diamante(pos: Vector2, d: float, color: Color) -> void:
	var puntos: PackedVector2Array = PackedVector2Array([
		Vector2(pos.x, pos.y - d),
		Vector2(pos.x + d * 0.7, pos.y),
		Vector2(pos.x, pos.y + d),
		Vector2(pos.x - d * 0.7, pos.y),
	])
	draw_colored_polygon(puntos, color)
