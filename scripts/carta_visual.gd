class_name CartaVisual
extends Control

## Carta visual con diseño profesional para el Truco.
## Dibuja la carta completa usando _draw() para maximo control visual.

signal carta_clickeada(indice: int)

# Datos de la carta
var numero: int = 0
var palo_str: String = ""
var indice: int = -1
var es_oculta: bool = false
var es_mesa: bool = false
var es_slot_vacio: bool = false
var es_jugador: bool = true

# Hover
var _hover: bool = false

# Simbolos de palos (caracteres Unicode estilizados)
const PALO_SIMBOLO: Dictionary = {
	"espada": "\u2694",
	"basto": "\u2663",
	"oro": "\u2B50",
	"copa": "\u2665",
}

const PALO_COLOR: Dictionary = {
	"espada": Color(0.25, 0.45, 0.85),
	"basto": Color(0.2, 0.65, 0.3),
	"oro": Color(0.9, 0.75, 0.1),
	"copa": Color(0.85, 0.2, 0.3),
}

const PALO_COLOR_OSCURO: Dictionary = {
	"espada": Color(0.15, 0.3, 0.6),
	"basto": Color(0.1, 0.45, 0.2),
	"oro": Color(0.7, 0.55, 0.05),
	"copa": Color(0.65, 0.1, 0.15),
}

const NUMERO_NOMBRE: Dictionary = {
	1: "1",
	2: "2",
	3: "3",
	4: "4",
	5: "5",
	6: "6",
	7: "7",
	10: "10",
	11: "11",
	12: "12",
}

# ============================================================
# FACTORY METHODS
# ============================================================

static func crear_carta_jugador(carta: Carta, idx: int) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.indice = idx
	cv.es_oculta = false
	cv.es_mesa = false
	cv.es_slot_vacio = false
	cv.es_jugador = true
	cv.custom_minimum_size = Vector2(105, 150)
	cv.mouse_filter = Control.MOUSE_FILTER_STOP
	cv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cv.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			cv.carta_clickeada.emit(cv.indice)
	)
	cv.mouse_entered.connect(func(): cv._hover = true; cv.queue_redraw())
	cv.mouse_exited.connect(func(): cv._hover = false; cv.queue_redraw())
	return cv


static func crear_carta_oculta() -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.es_oculta = true
	cv.es_mesa = false
	cv.es_slot_vacio = false
	cv.custom_minimum_size = Vector2(105, 150)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv


static func crear_carta_mesa(carta: Carta, jugador: bool) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.es_oculta = false
	cv.es_mesa = true
	cv.es_slot_vacio = false
	cv.es_jugador = jugador
	cv.custom_minimum_size = Vector2(80, 115)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv


static func crear_slot_vacio() -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.es_slot_vacio = true
	cv.custom_minimum_size = Vector2(80, 115)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

# ============================================================
# DIBUJO
# ============================================================

func _draw() -> void:
	if es_slot_vacio:
		_dibujar_slot_vacio()
	elif es_oculta:
		_dibujar_carta_oculta()
	else:
		_dibujar_carta_visible()


func _dibujar_slot_vacio() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var r: float = 8.0

	# Fondo semi-transparente
	draw_rect(rect, Color(0.1, 0.2, 0.12, 0.25), true)

	# Borde punteado (simulado con lineas)
	var border_color: Color = Color(0.3, 0.5, 0.35, 0.35)
	draw_rect(rect, border_color, false, 1.5)

	# Texto central
	_dibujar_texto_centrado("-", size / 2.0, 20, Color(0.4, 0.5, 0.4, 0.4))


func _dibujar_carta_oculta() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	# Sombra
	var sombra: Rect2 = Rect2(Vector2(3, 3), size)
	draw_rect(sombra, Color(0, 0, 0, 0.4), true)

	# Fondo principal - patron rojo oscuro
	draw_rect(rect, Color(0.55, 0.08, 0.08), true)

	# Marco interior decorativo
	var margen: float = 6.0
	var inner: Rect2 = Rect2(Vector2(margen, margen), size - Vector2(margen * 2, margen * 2))
	draw_rect(inner, Color(0.7, 0.15, 0.15), false, 1.5)

	# Patron decorativo - rombo central
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	var d: float = 20.0
	var puntos: PackedVector2Array = PackedVector2Array([
		Vector2(cx, cy - d),
		Vector2(cx + d * 0.7, cy),
		Vector2(cx, cy + d),
		Vector2(cx - d * 0.7, cy),
	])
	draw_colored_polygon(puntos, Color(0.8, 0.2, 0.2))
	draw_polyline(puntos + PackedVector2Array([puntos[0]]), Color(0.9, 0.6, 0.2, 0.8), 1.5)

	# Lineas decorativas cruzadas
	var m2: float = 14.0
	draw_line(Vector2(m2, m2), Vector2(size.x - m2, size.y - m2), Color(0.8, 0.25, 0.2, 0.3), 1.0)
	draw_line(Vector2(size.x - m2, m2), Vector2(m2, size.y - m2), Color(0.8, 0.25, 0.2, 0.3), 1.0)

	# Borde exterior dorado
	draw_rect(rect, Color(0.85, 0.65, 0.15), false, 2.0)


func _dibujar_carta_visible() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var color_palo: Color = PALO_COLOR.get(palo_str, Color.WHITE)
	var color_oscuro: Color = PALO_COLOR_OSCURO.get(palo_str, Color.GRAY)

	# Sombra
	var sombra_offset: float = 3.0 if not es_mesa else 2.0
	var sombra: Rect2 = Rect2(Vector2(sombra_offset, sombra_offset), size)
	draw_rect(sombra, Color(0, 0, 0, 0.35), true)

	# Hover - elevar carta
	if _hover and not es_mesa:
		var hover_rect: Rect2 = Rect2(Vector2(-1, -3), size + Vector2(2, 3))
		draw_rect(hover_rect, Color(1, 0.95, 0.7, 0.15), true)

	# Fondo principal - crema elegante
	var bg_color: Color = Color(0.97, 0.94, 0.88) if not _hover else Color(1.0, 0.97, 0.92)
	draw_rect(rect, bg_color, true)

	# Franja superior con color del palo
	var franja: Rect2 = Rect2(Vector2.ZERO, Vector2(size.x, 4))
	draw_rect(franja, color_palo, true)

	# Franja inferior
	var franja_inf: Rect2 = Rect2(Vector2(0, size.y - 4), Vector2(size.x, 4))
	draw_rect(franja_inf, color_palo, true)

	# Marco interior fino
	var m: float = 5.0
	var inner: Rect2 = Rect2(Vector2(m, m + 2), size - Vector2(m * 2, m * 2 + 4))
	draw_rect(inner, Color(color_palo.r, color_palo.g, color_palo.b, 0.15), false, 0.8)

	# Numero - esquina superior izquierda
	var num_text: String = NUMERO_NOMBRE.get(numero, str(numero))
	var num_size: int = 22 if not es_mesa else 18
	_dibujar_texto(num_text, Vector2(10, 18 if not es_mesa else 15), num_size, color_oscuro)

	# Simbolo palo - esquina superior izquierda debajo del numero
	var sym: String = PALO_SIMBOLO.get(palo_str, "?")
	var sym_size: int = 14 if not es_mesa else 11
	_dibujar_texto(sym, Vector2(12, 36 if not es_mesa else 28), sym_size, color_palo)

	# Simbolo grande central
	var center_y: float = size.y * 0.5
	var center_size: int = 38 if not es_mesa else 28
	_dibujar_texto_centrado(sym, Vector2(size.x / 2.0, center_y), center_size, color_palo)

	# Numero grande central (detras del simbolo, sutil)
	var num_bg_size: int = 50 if not es_mesa else 36
	_dibujar_texto_centrado(num_text, Vector2(size.x / 2.0, center_y), num_bg_size, Color(color_palo.r, color_palo.g, color_palo.b, 0.1))

	# Numero invertido - esquina inferior derecha
	_dibujar_texto(num_text, Vector2(size.x - 24 if not es_mesa else size.x - 20, size.y - 10 if not es_mesa else size.y - 8), num_size, color_oscuro)

	# Borde de la carta
	var borde_color: Color
	if es_mesa:
		borde_color = Color(0.2, 0.75, 0.3) if es_jugador else Color(0.75, 0.2, 0.2)
	else:
		borde_color = Color(0.7, 0.6, 0.35) if not _hover else Color(0.9, 0.8, 0.4)
	draw_rect(rect, borde_color, false, 2.0 if not _hover else 2.5)

	# Indicador de quien la tiro en mesa
	if es_mesa:
		var tag_text: String = "VOS" if es_jugador else "IA"
		var tag_color: Color = Color(0.2, 0.7, 0.3) if es_jugador else Color(0.7, 0.2, 0.2)
		_dibujar_texto_centrado(tag_text, Vector2(size.x / 2.0, size.y - 14), 9, tag_color)


func _dibujar_texto(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _dibujar_texto_centrado(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var draw_pos: Vector2 = Vector2(pos.x - text_size.x / 2.0, pos.y + text_size.y / 4.0)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
