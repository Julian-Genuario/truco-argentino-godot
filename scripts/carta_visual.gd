class_name CartaVisual
extends Control

## Carta de baraja española - diseño limpio y claro.
## Numero grande + nombre del palo + color distintivo.
## Prioridad: que se lea de un vistazo que carta es.

signal carta_clickeada(indice: int)

var numero: int = 0
var palo_str: String = ""
var indice: int = -1
var es_oculta: bool = false
var es_mesa: bool = false
var es_slot_vacio: bool = false
var es_jugador: bool = true

var _hover: bool = false
var _hover_progress: float = 0.0
var _hover_tween: Tween = null

# Colores claros y bien diferenciados para cada palo
const PALO_COLOR: Dictionary = {
	"espada": Color(0.15, 0.35, 0.8),
	"basto": Color(0.1, 0.55, 0.15),
	"oro": Color(0.85, 0.65, 0.0),
	"copa": Color(0.8, 0.1, 0.15),
}

# Nombre corto para mostrar en la carta
const PALO_LABEL: Dictionary = {
	"espada": "ESPADA",
	"basto": "BASTO",
	"oro": "ORO",
	"copa": "COPA",
}

# Nombre de figuras
const FIGURA_LABEL: Dictionary = {
	10: "SOTA",
	11: "CABALLO",
	12: "REY",
}

# ============================================================
# FACTORY
# ============================================================

static func crear_carta_jugador(carta: Carta, idx: int) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.indice = idx
	cv.es_jugador = true
	cv.custom_minimum_size = Vector2(100, 145)
	cv.mouse_filter = Control.MOUSE_FILTER_STOP
	cv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cv.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			cv.carta_clickeada.emit(cv.indice)
	)
	cv.mouse_entered.connect(func(): cv._set_hover(true))
	cv.mouse_exited.connect(func(): cv._set_hover(false))
	return cv

static func crear_carta_oculta() -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.es_oculta = true
	cv.custom_minimum_size = Vector2(100, 145)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

static func crear_carta_mesa(carta: Carta, jugador: bool) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.es_mesa = true
	cv.es_jugador = jugador
	cv.custom_minimum_size = Vector2(78, 112)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

static func crear_slot_vacio() -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.es_slot_vacio = true
	cv.custom_minimum_size = Vector2(78, 112)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

# ============================================================
# HOVER
# ============================================================

func _set_hover(value: bool) -> void:
	_hover = value
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(self, "_hover_progress", 1.0 if value else 0.0, 0.12).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	if not es_oculta and not es_slot_vacio and not es_mesa:
		queue_redraw()

# ============================================================
# DIBUJO
# ============================================================

func _draw() -> void:
	if es_slot_vacio:
		_dibujar_slot_vacio()
	elif es_oculta:
		_dibujar_dorso()
	else:
		_dibujar_frente()

func _dibujar_slot_vacio() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.1, 0.25), true)
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.2, 0.35, 0.25, 0.2), false, 1.0)

func _dibujar_dorso() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	# Sombra
	draw_rect(Rect2(Vector2(2, 2), size), Color(0, 0, 0, 0.35), true)
	# Fondo rojo
	draw_rect(r, Color(0.6, 0.05, 0.05), true)
	# Borde interior
	var m: float = 5.0
	draw_rect(Rect2(Vector2(m, m), size - Vector2(m * 2, m * 2)), Color(0.75, 0.15, 0.15), false, 1.5)
	# Patron central simple - X
	var m2: float = 12.0
	draw_line(Vector2(m2, m2), Vector2(size.x - m2, size.y - m2), Color(0.75, 0.2, 0.15, 0.4), 1.0)
	draw_line(Vector2(size.x - m2, m2), Vector2(m2, size.y - m2), Color(0.75, 0.2, 0.15, 0.4), 1.0)
	# Rombo central
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	_dibujar_rombo(Vector2(cx, cy), 14.0, Color(0.8, 0.2, 0.15))
	# Borde dorado
	draw_rect(r, Color(0.8, 0.6, 0.1), false, 2.0)

func _dibujar_rombo(c: Vector2, d: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -d), c + Vector2(d * 0.6, 0),
		c + Vector2(0, d), c + Vector2(-d * 0.6, 0),
	]), color)

# ============================================================
# FRENTE DE LA CARTA
# ============================================================

func _dibujar_frente() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	var col: Color = PALO_COLOR.get(palo_str, Color.WHITE)
	var hp: float = _hover_progress
	var mesa: bool = es_mesa

	# Sombra
	var so: float = (2.0 if mesa else 3.0) + hp * 2.0
	draw_rect(Rect2(Vector2(so, so), size), Color(0, 0, 0, 0.3), true)

	# Glow hover
	if hp > 0.01 and not mesa:
		draw_rect(Rect2(Vector2(-3, -5) * hp, size + Vector2(6, 8) * hp), Color(1, 0.9, 0.6, 0.12 * hp), true)

	# Fondo crema
	draw_rect(r, Color(lerp(0.96, 1.0, hp), lerp(0.93, 0.97, hp), lerp(0.85, 0.9, hp)), true)

	# Franja de color del palo arriba y abajo
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 3)), col, true)
	draw_rect(Rect2(Vector2(0, size.y - 3), Vector2(size.x, 3)), col, true)

	# === NUMERO GRANDE CENTRAL ===
	var num_str: String = str(numero)
	var es_figura: bool = numero >= 10
	var num_font_size: int
	if mesa:
		num_font_size = 32 if not es_figura else 24
	else:
		num_font_size = 42 if not es_figura else 30

	var centro_y: float = size.y * 0.42
	_txt_centrado(num_str, Vector2(size.x / 2.0, centro_y), num_font_size, col)

	# === NOMBRE DE FIGURA (si aplica) ===
	if es_figura:
		var fig_name: String = FIGURA_LABEL.get(numero, "")
		var fig_size: int = 10 if mesa else 12
		_txt_centrado(fig_name, Vector2(size.x / 2.0, centro_y + (18 if not mesa else 14)), fig_size, Color(col.r, col.g, col.b, 0.7))

	# === NOMBRE DEL PALO ===
	var palo_label: String = PALO_LABEL.get(palo_str, palo_str.to_upper())
	var palo_font: int = 10 if mesa else 12
	var palo_y: float = size.y * 0.72 if not es_figura else size.y * 0.68
	_txt_centrado(palo_label, Vector2(size.x / 2.0, palo_y), palo_font, Color(col.r, col.g, col.b, 0.8))

	# === SIMBOLO DEL PALO (forma geometrica simple) ===
	var sym_y: float = size.y * 0.82 if not es_figura else size.y * 0.8
	var sym_s: float = 10.0 if mesa else 13.0
	_dibujar_simbolo_palo(Vector2(size.x / 2.0, sym_y), sym_s, col)

	# === ESQUINA SUPERIOR IZQUIERDA: numero chico + simbolo ===
	var corner_num_s: int = 13 if mesa else 15
	_txt(num_str, Vector2(6, 14 if not mesa else 12), corner_num_s, col)
	_dibujar_simbolo_palo(Vector2(13, 23 if not mesa else 19), 5.0 if mesa else 6.0, col)

	# === ESQUINA INFERIOR DERECHA ===
	_txt(num_str, Vector2(size.x - 17 if not mesa else size.x - 14, size.y - 8 if not mesa else size.y - 6), corner_num_s, col)
	_dibujar_simbolo_palo(Vector2(size.x - 13, size.y - (18 if not mesa else 15)), 5.0 if mesa else 6.0, col)

	# === BORDE ===
	var bc: Color
	if mesa:
		bc = Color(0.15, 0.65, 0.25) if es_jugador else Color(0.65, 0.15, 0.15)
	else:
		bc = Color(lerp(0.6, 0.85, hp), lerp(0.5, 0.7, hp), lerp(0.3, 0.4, hp))
	draw_rect(r, bc, false, 2.0 + hp * 0.5)

	# Tag en mesa
	if mesa:
		var tag: String = "VOS" if es_jugador else "IA"
		var tc: Color = Color(0.1, 0.55, 0.2) if es_jugador else Color(0.55, 0.1, 0.1)
		_txt_centrado(tag, Vector2(size.x / 2.0, size.y - 8), 8, tc)

# ============================================================
# SIMBOLOS DE PALO - formas geometricas simples y claras
# ============================================================

func _dibujar_simbolo_palo(c: Vector2, s: float, color: Color) -> void:
	match palo_str:
		"espada":
			# Espada: linea vertical con cruz
			draw_line(c + Vector2(0, -s), c + Vector2(0, s * 0.8), color, max(s * 0.15, 1.5))
			draw_line(c + Vector2(-s * 0.45, s * 0.1), c + Vector2(s * 0.45, s * 0.1), color, max(s * 0.12, 1.2))
			# Punta
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(0, -s * 1.2),
				c + Vector2(-s * 0.15, -s * 0.85),
				c + Vector2(s * 0.15, -s * 0.85),
			]), color)
		"basto":
			# Basto: linea gruesa vertical con bolita arriba
			draw_line(c + Vector2(0, -s * 0.5), c + Vector2(0, s), color, max(s * 0.22, 2.0))
			draw_circle(c + Vector2(0, -s * 0.7), s * 0.25, color)
			# Hojita
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(s * 0.1, -s * 0.1),
				c + Vector2(s * 0.55, -s * 0.4),
				c + Vector2(s * 0.15, -s * 0.35),
			]), Color(0.15, 0.6, 0.15))
		"oro":
			# Oro: circulo dorado con punto central
			draw_circle(c, s * 0.75, color)
			draw_arc(c, s * 0.75, 0, TAU, 16, Color(color.r * 0.6, color.g * 0.5, 0.0), max(s * 0.08, 1.0))
			draw_circle(c, s * 0.3, Color(min(color.r + 0.15, 1.0), min(color.g + 0.1, 1.0), 0.1))
		"copa":
			# Copa: trapecio + tallo + base
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(-s * 0.5, -s * 0.8),
				c + Vector2(s * 0.5, -s * 0.8),
				c + Vector2(s * 0.2, s * 0.0),
				c + Vector2(-s * 0.2, s * 0.0),
			]), color)
			draw_line(c, c + Vector2(0, s * 0.5), color, max(s * 0.1, 1.2))
			draw_line(c + Vector2(-s * 0.35, s * 0.55), c + Vector2(s * 0.35, s * 0.55), color, max(s * 0.1, 1.2))

# ============================================================
# TEXTO
# ============================================================

func _txt(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _txt_centrado(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var f: Font = ThemeDB.fallback_font
	var ts: Vector2 = f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(f, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
