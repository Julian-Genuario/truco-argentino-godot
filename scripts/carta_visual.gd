class_name CartaVisual
extends Control

## Carta visual con baraja española para el Truco.
## Dibuja la carta completa usando _draw() con palos españoles
## (espada, basto, oro, copa) dibujados a mano.

signal carta_clickeada(indice: int)

# Datos de la carta
var numero: int = 0
var palo_str: String = ""
var indice: int = -1
var es_oculta: bool = false
var es_mesa: bool = false
var es_slot_vacio: bool = false
var es_jugador: bool = true

# Hover con animacion suave
var _hover: bool = false
var _hover_progress: float = 0.0  # 0.0 = normal, 1.0 = full hover
var _hover_tween: Tween = null

const PALO_COLOR: Dictionary = {
	"espada": Color(0.2, 0.4, 0.8),
	"basto": Color(0.15, 0.55, 0.2),
	"oro": Color(0.85, 0.7, 0.1),
	"copa": Color(0.8, 0.15, 0.25),
}

const PALO_COLOR_OSCURO: Dictionary = {
	"espada": Color(0.12, 0.25, 0.55),
	"basto": Color(0.08, 0.35, 0.12),
	"oro": Color(0.65, 0.5, 0.05),
	"copa": Color(0.6, 0.08, 0.12),
}

const NUMERO_NOMBRE: Dictionary = {
	1: "1", 2: "2", 3: "3", 4: "4", 5: "5",
	6: "6", 7: "7", 10: "S", 11: "C", 12: "R",
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
	cv.mouse_entered.connect(func(): cv._set_hover(true))
	cv.mouse_exited.connect(func(): cv._set_hover(false))
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
# HOVER ANIMADO
# ============================================================

func _set_hover(value: bool) -> void:
	_hover = value
	if _hover_tween:
		_hover_tween.kill()
	_hover_tween = create_tween()
	var target: float = 1.0 if value else 0.0
	_hover_tween.tween_property(self, "_hover_progress", target, 0.15).set_trans(Tween.TRANS_SINE)

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
		_dibujar_carta_oculta()
	else:
		_dibujar_carta_visible()


func _dibujar_slot_vacio() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.1, 0.2, 0.12, 0.25), true)
	draw_rect(rect, Color(0.3, 0.5, 0.35, 0.35), false, 1.5)
	_dibujar_texto_centrado("-", size / 2.0, 20, Color(0.4, 0.5, 0.4, 0.4))


func _dibujar_carta_oculta() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)

	# Sombra
	draw_rect(Rect2(Vector2(3, 3), size), Color(0, 0, 0, 0.4), true)

	# Fondo rojo oscuro
	draw_rect(rect, Color(0.55, 0.08, 0.08), true)

	# Marco interior
	var m: float = 6.0
	draw_rect(Rect2(Vector2(m, m), size - Vector2(m * 2, m * 2)), Color(0.7, 0.15, 0.15), false, 1.5)

	# Rombo central decorativo
	var cx: float = size.x / 2.0
	var cy: float = size.y / 2.0
	var d: float = 20.0
	var puntos: PackedVector2Array = PackedVector2Array([
		Vector2(cx, cy - d), Vector2(cx + d * 0.7, cy),
		Vector2(cx, cy + d), Vector2(cx - d * 0.7, cy),
	])
	draw_colored_polygon(puntos, Color(0.8, 0.2, 0.2))
	draw_polyline(puntos + PackedVector2Array([puntos[0]]), Color(0.9, 0.6, 0.2, 0.8), 1.5)

	# Lineas cruzadas
	var m2: float = 14.0
	draw_line(Vector2(m2, m2), Vector2(size.x - m2, size.y - m2), Color(0.8, 0.25, 0.2, 0.3), 1.0)
	draw_line(Vector2(size.x - m2, m2), Vector2(m2, size.y - m2), Color(0.8, 0.25, 0.2, 0.3), 1.0)

	# Borde dorado
	draw_rect(rect, Color(0.85, 0.65, 0.15), false, 2.0)


func _dibujar_carta_visible() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var color_palo: Color = PALO_COLOR.get(palo_str, Color.WHITE)
	var color_oscuro: Color = PALO_COLOR_OSCURO.get(palo_str, Color.GRAY)
	var hp: float = _hover_progress

	# Sombra
	var sombra_offset: float = (3.0 if not es_mesa else 2.0) + hp * 3.0
	draw_rect(Rect2(Vector2(sombra_offset, sombra_offset), size), Color(0, 0, 0, 0.35 + hp * 0.1), true)

	# Glow de hover
	if hp > 0.01 and not es_mesa:
		var ge: float = hp * 3.0
		draw_rect(Rect2(Vector2(-ge, -ge - hp * 4.0), size + Vector2(ge * 2, ge * 2 + hp * 4.0)), Color(1, 0.95, 0.7, 0.12 * hp), true)

	# Fondo crema
	draw_rect(rect, Color(lerp(0.97, 1.0, hp), lerp(0.94, 0.97, hp), lerp(0.88, 0.92, hp)), true)

	# Franja superior e inferior con color del palo
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 4)), color_palo, true)
	draw_rect(Rect2(Vector2(0, size.y - 4), Vector2(size.x, 4)), color_palo, true)

	# Marco interior
	var m: float = 5.0
	draw_rect(Rect2(Vector2(m, m + 2), size - Vector2(m * 2, m * 2 + 4)), Color(color_palo.r, color_palo.g, color_palo.b, 0.15), false, 0.8)

	# Numero esquina superior izquierda
	var num_text: String = NUMERO_NOMBRE.get(numero, str(numero))
	var num_size: int = 22 if not es_mesa else 18
	_dibujar_texto(num_text, Vector2(10, 18 if not es_mesa else 15), num_size, color_oscuro)

	# Palo pequeño esquina superior izquierda
	var sym_s: float = 10.0 if not es_mesa else 7.0
	_dibujar_palo(Vector2(15, 30 if not es_mesa else 24), sym_s, color_palo)

	# Palo grande central
	var center: Vector2 = Vector2(size.x / 2.0, size.y * 0.48)
	var center_s: float = 22.0 if not es_mesa else 15.0
	_dibujar_palo(center, center_s, color_palo)

	# Numero grande central sutil
	var num_bg_size: int = 50 if not es_mesa else 36
	_dibujar_texto_centrado(num_text, Vector2(size.x / 2.0, size.y * 0.48), num_bg_size, Color(color_palo.r, color_palo.g, color_palo.b, 0.08))

	# Numero esquina inferior derecha
	_dibujar_texto(num_text, Vector2(size.x - 24 if not es_mesa else size.x - 20, size.y - 10 if not es_mesa else size.y - 8), num_size, color_oscuro)

	# Palo pequeño esquina inferior derecha (invertido)
	_dibujar_palo(Vector2(size.x - 15, size.y - (22 if not es_mesa else 18)), sym_s, color_palo)

	# Borde
	var borde_color: Color
	if es_mesa:
		borde_color = Color(0.2, 0.75, 0.3) if es_jugador else Color(0.75, 0.2, 0.2)
	else:
		borde_color = Color(lerp(0.7, 0.9, hp), lerp(0.6, 0.8, hp), lerp(0.35, 0.4, hp))
	draw_rect(rect, borde_color, false, 2.0 + hp * 0.5)

	# Tag en mesa
	if es_mesa:
		var tag: String = "VOS" if es_jugador else "IA"
		var tag_c: Color = Color(0.2, 0.7, 0.3) if es_jugador else Color(0.7, 0.2, 0.2)
		_dibujar_texto_centrado(tag, Vector2(size.x / 2.0, size.y - 14), 9, tag_c)

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
	# Hoja de la espada (linea vertical gruesa)
	var hoja_top: Vector2 = c + Vector2(0, -s * 1.1)
	var hoja_bot: Vector2 = c + Vector2(0, s * 0.4)
	draw_line(hoja_top, hoja_bot, color, max(s * 0.12, 1.5))
	# Punta
	draw_line(hoja_top, hoja_top + Vector2(-s * 0.1, s * 0.2), Color(color.r, color.g, color.b, 0.6), max(s * 0.08, 1.0))
	draw_line(hoja_top, hoja_top + Vector2(s * 0.1, s * 0.2), Color(color.r, color.g, color.b, 0.6), max(s * 0.08, 1.0))
	# Guarda (linea horizontal)
	var guarda_y: float = c.y + s * 0.3
	draw_line(Vector2(c.x - s * 0.5, guarda_y), Vector2(c.x + s * 0.5, guarda_y), color, max(s * 0.12, 1.5))
	# Empuñadura
	draw_line(Vector2(c.x, guarda_y), Vector2(c.x, c.y + s * 0.9), Color(color.r * 0.7, color.g * 0.7, color.b * 0.7), max(s * 0.15, 2.0))
	# Pomo
	draw_circle(Vector2(c.x, c.y + s * 0.95), s * 0.12, color)


func _dibujar_basto(c: Vector2, s: float, color: Color) -> void:
	# Tronco principal (diagonal)
	var top: Vector2 = c + Vector2(-s * 0.15, -s * 0.9)
	var bot: Vector2 = c + Vector2(s * 0.15, s * 0.9)
	draw_line(top, bot, color, max(s * 0.22, 2.5))
	# Color mas claro para simular madera
	draw_line(top + Vector2(s * 0.03, 0), bot + Vector2(s * 0.03, 0), Color(color.r + 0.15, color.g + 0.15, color.b, 0.4), max(s * 0.08, 1.0))
	# Nudos del basto
	var nudo1: Vector2 = top.lerp(bot, 0.3)
	var nudo2: Vector2 = top.lerp(bot, 0.65)
	draw_circle(nudo1, s * 0.1, Color(color.r * 0.7, color.g * 0.7, color.b * 0.5))
	draw_circle(nudo2, s * 0.08, Color(color.r * 0.7, color.g * 0.7, color.b * 0.5))
	# Hojas pequeñas
	draw_line(nudo1, nudo1 + Vector2(s * 0.3, -s * 0.15), Color(0.2, 0.7, 0.15, 0.7), max(s * 0.06, 1.0))
	draw_line(nudo2, nudo2 + Vector2(-s * 0.25, -s * 0.12), Color(0.2, 0.7, 0.15, 0.7), max(s * 0.06, 1.0))


func _dibujar_oro(c: Vector2, s: float, color: Color) -> void:
	# Moneda exterior
	draw_circle(c, s * 0.7, color)
	# Borde interior
	draw_arc(c, s * 0.55, 0, TAU, 24, Color(color.r * 0.75, color.g * 0.6, color.b * 0.1), max(s * 0.06, 1.0))
	# Centro de la moneda (sol)
	draw_circle(c, s * 0.25, Color(color.r * 1.1, color.g * 0.9, color.b * 0.3))
	# Rayos del sol
	for i in range(8):
		var angulo: float = i * TAU / 8.0
		var desde: Vector2 = c + Vector2(cos(angulo), sin(angulo)) * s * 0.3
		var hasta: Vector2 = c + Vector2(cos(angulo), sin(angulo)) * s * 0.5
		draw_line(desde, hasta, Color(color.r * 0.9, color.g * 0.7, 0.05, 0.6), max(s * 0.05, 1.0))


func _dibujar_copa(c: Vector2, s: float, color: Color) -> void:
	# Caliz (trapecio invertido arriba)
	var copa_pts: PackedVector2Array = PackedVector2Array([
		c + Vector2(-s * 0.5, -s * 0.8),  # arriba izq
		c + Vector2(s * 0.5, -s * 0.8),   # arriba der
		c + Vector2(s * 0.2, s * 0.0),    # abajo der
		c + Vector2(-s * 0.2, s * 0.0),   # abajo izq
	])
	draw_colored_polygon(copa_pts, color)
	draw_polyline(copa_pts + PackedVector2Array([copa_pts[0]]), Color(color.r * 0.7, color.g * 0.5, color.b * 0.5), max(s * 0.05, 1.0))
	# Brillo del caliz
	draw_line(copa_pts[0].lerp(copa_pts[3], 0.15), copa_pts[0].lerp(copa_pts[3], 0.7), Color(1, 1, 1, 0.2), max(s * 0.06, 1.0))
	# Tallo
	draw_line(Vector2(c.x, c.y), Vector2(c.x, c.y + s * 0.5), Color(color.r * 0.8, color.g * 0.6, color.b * 0.6), max(s * 0.1, 1.5))
	# Base
	draw_line(Vector2(c.x - s * 0.35, c.y + s * 0.5), Vector2(c.x + s * 0.35, c.y + s * 0.5), color, max(s * 0.12, 1.5))
	draw_line(Vector2(c.x - s * 0.25, c.y + s * 0.6), Vector2(c.x + s * 0.25, c.y + s * 0.6), Color(color.r * 0.8, color.g * 0.6, color.b * 0.6), max(s * 0.08, 1.0))

# ============================================================
# TEXTO
# ============================================================

func _dibujar_texto(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _dibujar_texto_centrado(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var draw_pos: Vector2 = Vector2(pos.x - text_size.x / 2.0, pos.y + text_size.y / 4.0)
	draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
