class_name CartaVisual
extends Control

## Carta visual de baraja española para el Truco.
## Dibuja la carta con palos repetidos segun el numero (pips),
## figuras con silueta (Sota, Caballo, Rey), y estilo clasico.

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

const PALO_COLOR: Dictionary = {
	"espada": Color(0.2, 0.35, 0.75),
	"basto": Color(0.18, 0.5, 0.2),
	"oro": Color(0.82, 0.65, 0.08),
	"copa": Color(0.75, 0.12, 0.2),
}

const PALO_COLOR_OSCURO: Dictionary = {
	"espada": Color(0.12, 0.22, 0.5),
	"basto": Color(0.08, 0.32, 0.1),
	"oro": Color(0.6, 0.45, 0.04),
	"copa": Color(0.5, 0.06, 0.1),
}

# Nombre de las figuras
const NOMBRE_FIGURA: Dictionary = {
	10: "SOTA",
	11: "CABALLO",
	12: "REY",
}

# ============================================================
# FACTORY METHODS
# ============================================================

static func crear_carta_jugador(carta: Carta, idx: int) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.indice = idx
	cv.es_jugador = true
	cv.custom_minimum_size = Vector2(105, 155)
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
	cv.custom_minimum_size = Vector2(105, 155)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

static func crear_carta_mesa(carta: Carta, jugador: bool) -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.numero = carta.numero
	cv.palo_str = GameData.PALO_NOMBRE.get(carta.palo, "?")
	cv.es_mesa = true
	cv.es_jugador = jugador
	cv.custom_minimum_size = Vector2(80, 118)
	cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return cv

static func crear_slot_vacio() -> CartaVisual:
	var cv: CartaVisual = CartaVisual.new()
	cv.es_slot_vacio = true
	cv.custom_minimum_size = Vector2(80, 118)
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
	_hover_tween.tween_property(self, "_hover_progress", 1.0 if value else 0.0, 0.15).set_trans(Tween.TRANS_SINE)

func _process(_delta: float) -> void:
	if not es_oculta and not es_slot_vacio and not es_mesa:
		queue_redraw()

# ============================================================
# DIBUJO PRINCIPAL
# ============================================================

func _draw() -> void:
	if es_slot_vacio:
		_dibujar_slot_vacio()
	elif es_oculta:
		_dibujar_carta_oculta()
	else:
		_dibujar_carta_visible()

func _dibujar_slot_vacio() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.15, 0.1, 0.3), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.4, 0.3, 0.3), false, 1.5)

func _dibujar_carta_oculta() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(Rect2(Vector2(3, 3), size), Color(0, 0, 0, 0.4), true)
	# Fondo rojo clasico
	draw_rect(rect, Color(0.5, 0.06, 0.06), true)
	# Borde interior
	var m: float = 5.0
	draw_rect(Rect2(Vector2(m, m), size - Vector2(m * 2, m * 2)), Color(0.65, 0.12, 0.12), false, 1.5)
	# Patron de rombos
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	for oy in [-1, 0, 1]:
		for ox in [-1, 0, 1]:
			var pos: Vector2 = Vector2(cx + ox * 18.0, cy + oy * 22.0)
			_dibujar_rombo(pos, 7.0, Color(0.7, 0.18, 0.18))
	# Borde dorado
	draw_rect(rect, Color(0.8, 0.6, 0.12), false, 2.0)

func _dibujar_rombo(c: Vector2, d: float, color: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(0, -d), c + Vector2(d * 0.6, 0),
		c + Vector2(0, d), c + Vector2(-d * 0.6, 0),
	])
	draw_colored_polygon(pts, color)

# ============================================================
# CARTA VISIBLE
# ============================================================

func _dibujar_carta_visible() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var col: Color = PALO_COLOR.get(palo_str, Color.WHITE)
	var col_osc: Color = PALO_COLOR_OSCURO.get(palo_str, Color.GRAY)
	var hp: float = _hover_progress

	# Sombra
	var so: float = (3.0 if not es_mesa else 2.0) + hp * 3.0
	draw_rect(Rect2(Vector2(so, so), size), Color(0, 0, 0, 0.3 + hp * 0.1), true)

	# Glow hover
	if hp > 0.01 and not es_mesa:
		var g: float = hp * 4.0
		draw_rect(Rect2(Vector2(-g, -g - hp * 5), size + Vector2(g * 2, g * 2 + hp * 5)), Color(1, 0.92, 0.6, 0.15 * hp), true)

	# Fondo crema/pergamino
	var bg: Color = Color(lerp(0.95, 0.98, hp), lerp(0.91, 0.95, hp), lerp(0.82, 0.87, hp))
	draw_rect(rect, bg, true)

	# Borde interior decorativo
	var bm: float = 4.0
	draw_rect(Rect2(Vector2(bm, bm), size - Vector2(bm * 2, bm * 2)), Color(col.r, col.g, col.b, 0.12), false, 0.8)

	# Zona del cuerpo de la carta (donde van los palos)
	var margen_top: float = size.y * 0.18
	var margen_bot: float = size.y * 0.18
	var cuerpo_rect: Rect2 = Rect2(Vector2(bm + 2, margen_top), Vector2(size.x - bm * 2 - 4, size.y - margen_top - margen_bot))

	# Lineas separadoras finas arriba y abajo del cuerpo
	draw_line(Vector2(bm + 2, margen_top), Vector2(size.x - bm - 2, margen_top), Color(col.r, col.g, col.b, 0.15), 0.8)
	draw_line(Vector2(bm + 2, size.y - margen_bot), Vector2(size.x - bm - 2, size.y - margen_bot), Color(col.r, col.g, col.b, 0.15), 0.8)

	# === NUMERO Y PALO EN ESQUINAS ===
	var num_text: String = str(numero) if numero <= 7 else NOMBRE_FIGURA.get(numero, str(numero)).substr(0, 1)
	var ns: int = 18 if not es_mesa else 14
	var pip_s: float = 7.0 if not es_mesa else 5.0

	# Esquina superior izquierda
	_dibujar_texto(num_text, Vector2(8, 15 if not es_mesa else 12), ns, col_osc)
	_dibujar_palo(Vector2(13, 24 if not es_mesa else 19), pip_s, col)

	# Esquina inferior derecha (invertida visualmente)
	_dibujar_texto(num_text, Vector2(size.x - 18 if not es_mesa else size.x - 14, size.y - 10 if not es_mesa else size.y - 8), ns, col_osc)
	_dibujar_palo(Vector2(size.x - 13, size.y - (24 if not es_mesa else 19)), pip_s, col)

	# === CUERPO: PIPS O FIGURA ===
	var pip_escala: float = 12.0 if not es_mesa else 9.0

	if numero >= 10:
		_dibujar_figura(cuerpo_rect, col, col_osc)
	else:
		_dibujar_pips(cuerpo_rect, pip_escala, col)

	# === BORDE EXTERIOR ===
	var bc: Color
	if es_mesa:
		bc = Color(0.2, 0.7, 0.3) if es_jugador else Color(0.7, 0.2, 0.2)
	else:
		bc = Color(lerp(0.65, 0.85, hp), lerp(0.55, 0.75, hp), lerp(0.3, 0.4, hp))
	draw_rect(rect, bc, false, 2.0 + hp * 0.5)

	# Tag en mesa
	if es_mesa:
		var tag_c: Color = Color(0.15, 0.6, 0.25) if es_jugador else Color(0.6, 0.15, 0.15)
		_dibujar_texto_centrado("VOS" if es_jugador else "IA", Vector2(size.x / 2.0, size.y - 10), 8, tag_c)

# ============================================================
# DISTRIBUCION DE PIPS (palos repetidos segun numero)
# ============================================================

func _dibujar_pips(area: Rect2, s: float, color: Color) -> void:
	var cx: float = area.position.x + area.size.x / 2.0
	var cy: float = area.position.y + area.size.y / 2.0
	var w: float = area.size.x
	var h: float = area.size.y
	var lx: float = area.position.x + w * 0.25  # columna izq
	var rx: float = area.position.x + w * 0.75  # columna der
	var top: float = area.position.y + h * 0.12
	var bot: float = area.position.y + h * 0.88
	var mid: float = cy

	# Posiciones de pips segun numero de la carta
	var posiciones: Array[Vector2] = []
	match numero:
		1:
			# As: un palo grande central
			_dibujar_palo(Vector2(cx, cy), s * 2.0, color)
			return
		2:
			posiciones = [Vector2(cx, top), Vector2(cx, bot)]
		3:
			posiciones = [Vector2(cx, top), Vector2(cx, mid), Vector2(cx, bot)]
		4:
			posiciones = [Vector2(lx, top), Vector2(rx, top), Vector2(lx, bot), Vector2(rx, bot)]
		5:
			posiciones = [Vector2(lx, top), Vector2(rx, top), Vector2(cx, mid), Vector2(lx, bot), Vector2(rx, bot)]
		6:
			posiciones = [Vector2(lx, top), Vector2(rx, top), Vector2(lx, mid), Vector2(rx, mid), Vector2(lx, bot), Vector2(rx, bot)]
		7:
			posiciones = [
				Vector2(lx, top), Vector2(rx, top),
				Vector2(cx, area.position.y + h * 0.32),
				Vector2(lx, mid), Vector2(rx, mid),
				Vector2(lx, bot), Vector2(rx, bot),
			]

	for pos in posiciones:
		_dibujar_palo(pos, s, color)

# ============================================================
# FIGURAS (Sota, Caballo, Rey)
# ============================================================

func _dibujar_figura(area: Rect2, color: Color, color_osc: Color) -> void:
	var cx: float = area.position.x + area.size.x / 2.0
	var cy: float = area.position.y + area.size.y / 2.0
	var w: float = area.size.x
	var h: float = area.size.y
	var s: float = min(w, h) * 0.35

	# Fondo decorativo de la figura
	var fig_rect: Rect2 = Rect2(Vector2(cx - s * 1.1, cy - s * 1.4), Vector2(s * 2.2, s * 2.8))
	draw_rect(fig_rect, Color(color.r, color.g, color.b, 0.06), true)
	draw_rect(fig_rect, Color(color.r, color.g, color.b, 0.15), false, 0.8)

	match numero:
		10: # Sota (paje/infante)
			_dibujar_sota(Vector2(cx, cy), s, color, color_osc)
		11: # Caballo
			_dibujar_caballo(Vector2(cx, cy), s, color, color_osc)
		12: # Rey
			_dibujar_rey(Vector2(cx, cy), s, color, color_osc)

	# Palo pequeño abajo de la figura
	_dibujar_palo(Vector2(cx, cy + s * 1.15), s * 0.4, color)

func _dibujar_sota(c: Vector2, s: float, color: Color, _co: Color) -> void:
	# Cabeza
	draw_circle(c + Vector2(0, -s * 0.7), s * 0.3, Color(0.85, 0.72, 0.55))
	draw_arc(c + Vector2(0, -s * 0.7), s * 0.3, 0, TAU, 16, Color(color.r, color.g, color.b, 0.5), 1.0)
	# Sombrero/gorra
	draw_line(c + Vector2(-s * 0.35, -s * 0.95), c + Vector2(s * 0.35, -s * 0.95), color, max(s * 0.15, 2.0))
	draw_line(c + Vector2(-s * 0.2, -s * 0.95), c + Vector2(-s * 0.15, -s * 1.15), color, max(s * 0.1, 1.5))
	draw_line(c + Vector2(-s * 0.15, -s * 1.15), c + Vector2(s * 0.15, -s * 1.15), color, max(s * 0.1, 1.5))
	# Ojos
	draw_circle(c + Vector2(-s * 0.1, -s * 0.75), s * 0.04, Color(0.2, 0.15, 0.1))
	draw_circle(c + Vector2(s * 0.1, -s * 0.75), s * 0.04, Color(0.2, 0.15, 0.1))
	# Cuerpo (tunica)
	var tunica: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.3, -s * 0.4),
		c + Vector2(s * 0.3, -s * 0.4),
		c + Vector2(s * 0.4, s * 0.65),
		c + Vector2(-s * 0.4, s * 0.65),
	])
	draw_colored_polygon(tunica, Color(color.r * 0.9, color.g * 0.9, color.b * 0.9, 0.7))
	draw_polyline(tunica + PackedVector2Array([tunica[0]]), color, 1.0)
	# Espada/objeto en mano
	draw_line(c + Vector2(s * 0.25, -s * 0.2), c + Vector2(s * 0.35, s * 0.5), Color(0.5, 0.5, 0.55), max(s * 0.06, 1.0))

func _dibujar_caballo(c: Vector2, s: float, color: Color, _co: Color) -> void:
	# Cabeza del jinete
	draw_circle(c + Vector2(-s * 0.1, -s * 0.85), s * 0.22, Color(0.85, 0.72, 0.55))
	draw_arc(c + Vector2(-s * 0.1, -s * 0.85), s * 0.22, 0, TAU, 16, Color(color.r, color.g, color.b, 0.5), 1.0)
	# Ojos jinete
	draw_circle(c + Vector2(-s * 0.15, -s * 0.88), s * 0.03, Color(0.2, 0.15, 0.1))
	# Cuerpo jinete
	var jinete: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.25, -s * 0.6),
		c + Vector2(s * 0.05, -s * 0.6),
		c + Vector2(s * 0.15, -s * 0.15),
		c + Vector2(-s * 0.35, -s * 0.15),
	])
	draw_colored_polygon(jinete, Color(color.r, color.g, color.b, 0.6))
	# Caballo - cuerpo
	var caballo: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.3, -s * 0.1),
		c + Vector2(s * 0.45, -s * 0.2),
		c + Vector2(s * 0.5, s * 0.25),
		c + Vector2(s * 0.35, s * 0.6),
		c + Vector2(-s * 0.15, s * 0.6),
		c + Vector2(-s * 0.35, s * 0.3),
	])
	draw_colored_polygon(caballo, Color(0.6, 0.45, 0.3, 0.8))
	draw_polyline(caballo + PackedVector2Array([caballo[0]]), Color(0.4, 0.28, 0.15), 1.0)
	# Cabeza del caballo
	draw_circle(c + Vector2(s * 0.45, -s * 0.35), s * 0.18, Color(0.55, 0.4, 0.25))
	# Ojo caballo
	draw_circle(c + Vector2(s * 0.48, -s * 0.38), s * 0.03, Color(0.15, 0.1, 0.05))
	# Patas
	draw_line(c + Vector2(-s * 0.15, s * 0.6), c + Vector2(-s * 0.2, s * 0.85), Color(0.5, 0.35, 0.2), max(s * 0.08, 1.5))
	draw_line(c + Vector2(s * 0.25, s * 0.6), c + Vector2(s * 0.2, s * 0.85), Color(0.5, 0.35, 0.2), max(s * 0.08, 1.5))

func _dibujar_rey(c: Vector2, s: float, color: Color, _co: Color) -> void:
	# Corona
	var corona: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.3, -s * 0.85),
		c + Vector2(-s * 0.25, -s * 1.1),
		c + Vector2(-s * 0.1, -s * 0.9),
		c + Vector2(0, -s * 1.15),
		c + Vector2(s * 0.1, -s * 0.9),
		c + Vector2(s * 0.25, -s * 1.1),
		c + Vector2(s * 0.3, -s * 0.85),
	])
	draw_colored_polygon(corona, Color(0.85, 0.7, 0.1))
	draw_polyline(corona, Color(0.65, 0.5, 0.05), 1.0)
	# Gemas en la corona
	draw_circle(c + Vector2(0, -s * 1.05), s * 0.05, Color(0.8, 0.15, 0.15))
	draw_circle(c + Vector2(-s * 0.18, -s * 0.95), s * 0.04, Color(0.2, 0.5, 0.8))
	draw_circle(c + Vector2(s * 0.18, -s * 0.95), s * 0.04, Color(0.2, 0.5, 0.8))
	# Cabeza
	draw_circle(c + Vector2(0, -s * 0.6), s * 0.28, Color(0.85, 0.72, 0.55))
	draw_arc(c + Vector2(0, -s * 0.6), s * 0.28, 0, TAU, 16, Color(color.r, color.g, color.b, 0.4), 1.0)
	# Ojos
	draw_circle(c + Vector2(-s * 0.09, -s * 0.64), s * 0.035, Color(0.2, 0.15, 0.1))
	draw_circle(c + Vector2(s * 0.09, -s * 0.64), s * 0.035, Color(0.2, 0.15, 0.1))
	# Barba
	var barba: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.15, -s * 0.42),
		c + Vector2(s * 0.15, -s * 0.42),
		c + Vector2(s * 0.08, -s * 0.25),
		c + Vector2(0, -s * 0.2),
		c + Vector2(-s * 0.08, -s * 0.25),
	])
	draw_colored_polygon(barba, Color(0.55, 0.4, 0.25, 0.7))
	# Manto/capa real
	var manto: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.4, -s * 0.3),
		c + Vector2(s * 0.4, -s * 0.3),
		c + Vector2(s * 0.5, s * 0.75),
		c + Vector2(-s * 0.5, s * 0.75),
	])
	draw_colored_polygon(manto, Color(color.r, color.g, color.b, 0.7))
	draw_polyline(manto + PackedVector2Array([manto[0]]), color, 1.0)
	# Detalle del manto: franja de armiño
	draw_line(c + Vector2(-s * 0.38, -s * 0.25), c + Vector2(s * 0.38, -s * 0.25), Color(0.9, 0.85, 0.75), max(s * 0.08, 1.5))
	# Cetro
	draw_line(c + Vector2(s * 0.3, -s * 0.2), c + Vector2(s * 0.35, s * 0.6), Color(0.8, 0.65, 0.1), max(s * 0.06, 1.5))
	draw_circle(c + Vector2(s * 0.3, -s * 0.22), s * 0.06, Color(0.85, 0.7, 0.1))

# ============================================================
# DIBUJO DE PALOS ESPAÑOLES
# ============================================================

func _dibujar_palo(centro: Vector2, escala: float, color: Color) -> void:
	match palo_str:
		"espada":
			_dibujar_espada(centro, escala, color)
		"basto":
			_dibujar_basto(centro, escala, color)
		"oro":
			_dibujar_oro(centro, escala, color)
		"copa":
			_dibujar_copa(centro, escala, color)

func _dibujar_espada(c: Vector2, s: float, color: Color) -> void:
	# Hoja
	var hoja_top: Vector2 = c + Vector2(0, -s * 1.0)
	var hoja_bot: Vector2 = c + Vector2(0, s * 0.3)
	draw_line(hoja_top, hoja_bot, Color(0.6, 0.65, 0.7), max(s * 0.12, 1.5))
	# Filo (brillo)
	draw_line(hoja_top + Vector2(1, 0), hoja_bot + Vector2(1, 0), Color(0.8, 0.85, 0.9, 0.4), max(s * 0.05, 0.8))
	# Punta triangular
	draw_colored_polygon(PackedVector2Array([
		hoja_top + Vector2(0, -s * 0.15),
		hoja_top + Vector2(-s * 0.08, s * 0.05),
		hoja_top + Vector2(s * 0.08, s * 0.05),
	]), Color(0.65, 0.7, 0.75))
	# Guarda
	var gy: float = c.y + s * 0.25
	draw_line(Vector2(c.x - s * 0.4, gy), Vector2(c.x + s * 0.4, gy), color, max(s * 0.1, 1.5))
	# Curvas de la guarda
	draw_arc(Vector2(c.x - s * 0.3, gy), s * 0.1, -PI * 0.5, PI * 0.5, 8, color, max(s * 0.06, 1.0))
	draw_arc(Vector2(c.x + s * 0.3, gy), s * 0.1, PI * 0.5, PI * 1.5, 8, color, max(s * 0.06, 1.0))
	# Empuñadura
	draw_line(Vector2(c.x, gy), Vector2(c.x, c.y + s * 0.8), Color(0.45, 0.3, 0.15), max(s * 0.13, 2.0))
	# Pomo
	draw_circle(Vector2(c.x, c.y + s * 0.85), s * 0.1, color)

func _dibujar_basto(c: Vector2, s: float, color: Color) -> void:
	# Tronco principal
	var top: Vector2 = c + Vector2(0, -s * 0.9)
	var bot: Vector2 = c + Vector2(0, s * 0.9)
	# Tronco con forma ligeramente curva (mas grueso arriba)
	draw_line(top, bot, Color(0.45, 0.3, 0.12), max(s * 0.2, 2.5))
	draw_line(top, bot, color, max(s * 0.14, 2.0))
	# Veta de madera
	draw_line(top + Vector2(s * 0.03, s * 0.1), bot + Vector2(-s * 0.02, -s * 0.1), Color(0.35, 0.22, 0.08, 0.3), max(s * 0.04, 0.8))
	# Nudos
	var n1: Vector2 = top.lerp(bot, 0.35)
	var n2: Vector2 = top.lerp(bot, 0.65)
	draw_circle(n1, s * 0.09, Color(0.35, 0.22, 0.08))
	draw_circle(n2, s * 0.07, Color(0.35, 0.22, 0.08))
	# Hojas
	_dibujar_hoja(n1, s * 0.3, 0.5, Color(0.25, 0.6, 0.15))
	_dibujar_hoja(n2, s * 0.25, 2.2, Color(0.2, 0.55, 0.12))

func _dibujar_hoja(pos: Vector2, s: float, angulo: float, color: Color) -> void:
	var dir: Vector2 = Vector2(cos(angulo), sin(angulo))
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var punta: Vector2 = pos + dir * s
	var pts: PackedVector2Array = PackedVector2Array([
		pos, pos + dir * s * 0.5 + perp * s * 0.25,
		punta, pos + dir * s * 0.5 - perp * s * 0.25,
	])
	draw_colored_polygon(pts, color)
	# Nervadura central
	draw_line(pos, punta, Color(color.r * 0.7, color.g * 0.8, color.b * 0.5, 0.5), max(s * 0.08, 0.8))

func _dibujar_oro(c: Vector2, s: float, color: Color) -> void:
	# Moneda exterior
	draw_circle(c, s * 0.65, color)
	# Borde de la moneda
	draw_arc(c, s * 0.65, 0, TAU, 20, Color(color.r * 0.7, color.g * 0.55, 0.02), max(s * 0.06, 1.0))
	# Anillo interior
	draw_arc(c, s * 0.45, 0, TAU, 16, Color(color.r * 0.75, color.g * 0.6, 0.04, 0.6), max(s * 0.04, 0.8))
	# Sol central
	draw_circle(c, s * 0.22, Color(min(color.r * 1.2, 1.0), color.g * 0.9, 0.2))
	# Rayos
	for i in range(8):
		var a: float = i * TAU / 8.0
		var desde: Vector2 = c + Vector2(cos(a), sin(a)) * s * 0.26
		var hasta: Vector2 = c + Vector2(cos(a), sin(a)) * s * 0.42
		draw_line(desde, hasta, Color(color.r * 0.85, color.g * 0.65, 0.04, 0.5), max(s * 0.05, 0.8))
	# Brillo
	draw_arc(c + Vector2(-s * 0.15, -s * 0.15), s * 0.2, -PI * 0.8, -PI * 0.2, 6, Color(1, 1, 0.85, 0.3), max(s * 0.05, 0.8))

func _dibujar_copa(c: Vector2, s: float, color: Color) -> void:
	# Caliz
	var copa: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.45, -s * 0.75),
		c + Vector2(s * 0.45, -s * 0.75),
		c + Vector2(s * 0.2, s * 0.0),
		c + Vector2(-s * 0.2, s * 0.0),
	])
	draw_colored_polygon(copa, color)
	draw_polyline(copa + PackedVector2Array([copa[0]]), Color(color.r * 0.6, color.g * 0.4, color.b * 0.4), max(s * 0.04, 0.8))
	# Brillo del caliz
	draw_line(copa[0] * 0.85 + copa[3] * 0.15, copa[0] * 0.3 + copa[3] * 0.7, Color(1, 1, 1, 0.2), max(s * 0.05, 0.8))
	# Contenido (vino)
	var vino: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.38, -s * 0.55),
		c + Vector2(s * 0.38, -s * 0.55),
		c + Vector2(s * 0.28, -s * 0.15),
		c + Vector2(-s * 0.28, -s * 0.15),
	])
	draw_colored_polygon(vino, Color(0.5, 0.05, 0.1, 0.4))
	# Tallo
	draw_line(Vector2(c.x, c.y), Vector2(c.x, c.y + s * 0.45), Color(color.r * 0.7, color.g * 0.5, color.b * 0.5), max(s * 0.08, 1.5))
	# Base ovalada
	var base_y: float = c.y + s * 0.5
	draw_line(Vector2(c.x - s * 0.3, base_y), Vector2(c.x + s * 0.3, base_y), color, max(s * 0.1, 1.5))
	draw_arc(Vector2(c.x, base_y + s * 0.05), s * 0.3, 0, PI, 8, Color(color.r * 0.7, color.g * 0.5, color.b * 0.5), max(s * 0.06, 1.0))

# ============================================================
# TEXTO
# ============================================================

func _dibujar_texto(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	draw_string(ThemeDB.fallback_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _dibujar_texto_centrado(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var ts: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, Vector2(pos.x - ts.x / 2.0, pos.y + ts.y / 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
