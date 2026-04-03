class_name ComodinVisual
extends Control

## Tarjeta visual estilizada para un comodin (power-up).
## Se dibuja con _draw() para maximo control, con icono, color por categoria,
## nombre, descripcion, y efecto glow al activarse.

signal comodin_clickeado(tipo: int)

var tipo: int = -1
var nombre: String = ""
var descripcion: String = ""
var categoria: String = ""
var _hover: bool = false

# Animacion de activacion
var _activado: bool = false
var _activado_timer: float = 0.0
var _activado_duracion: float = 2.0
var _glow_intensity: float = 0.0

# Pulso sutil constante
var _pulso_time: float = 0.0

# Iconos por tipo de comodin
const ICONOS: Dictionary = {
	"El Chamuyero": "\U0001F60F",     # smirk
	"El Mano Pesada": "\u270A",       # fist
	"El Matematico": "\U0001F9EE",    # abacus
	"El Violento": "\U0001F4A5",      # explosion
	"El Adivino": "\U0001F52E",       # crystal ball
	"El Clutchero": "\u26A1",         # lightning
	"El Sacado": "\U0001F525",        # fire
	"El Mufa": "\U0001F340",          # four leaf clover
	"El Tramposo": "\U0001F0CF",      # joker card
	"El Caotico": "\U0001F3B2",       # dice
}

# Colores por categoria
const COLOR_CATEGORIA: Dictionary = {
	"bluff": Color(0.9, 0.4, 0.1),       # naranja
	"cartas": Color(0.2, 0.7, 0.4),      # verde
	"apuestas": Color(0.8, 0.2, 0.3),    # rojo
	"info": Color(0.3, 0.5, 0.9),        # azul
	"reglas": Color(0.7, 0.4, 0.9),      # violeta
	"rng": Color(0.9, 0.7, 0.1),         # amarillo
}

const COLOR_CATEGORIA_OSCURO: Dictionary = {
	"bluff": Color(0.6, 0.25, 0.05),
	"cartas": Color(0.1, 0.45, 0.25),
	"apuestas": Color(0.55, 0.1, 0.15),
	"info": Color(0.15, 0.3, 0.6),
	"reglas": Color(0.45, 0.2, 0.6),
	"rng": Color(0.6, 0.45, 0.05),
}

# ============================================================
# FACTORY
# ============================================================

static func crear(tipo_comodin: int, info: Dictionary) -> ComodinVisual:
	var cv: ComodinVisual = ComodinVisual.new()
	cv.tipo = tipo_comodin
	cv.nombre = info.get("nombre", "?")
	cv.descripcion = info.get("descripcion", "")
	cv.categoria = info.get("categoria", "cartas")
	cv.custom_minimum_size = Vector2(130, 80)
	cv.mouse_filter = Control.MOUSE_FILTER_STOP
	cv.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	cv.mouse_entered.connect(func(): cv._hover = true; cv.queue_redraw())
	cv.mouse_exited.connect(func(): cv._hover = false; cv.queue_redraw())
	cv.tooltip_text = cv.nombre + "\n" + cv.descripcion
	return cv


# ============================================================
# PROCESO
# ============================================================

func _process(delta: float) -> void:
	_pulso_time += delta * 1.5

	if _activado:
		_activado_timer += delta
		# Glow sube rapido y baja lento
		if _activado_timer < 0.3:
			_glow_intensity = _activado_timer / 0.3
		else:
			_glow_intensity = max(0.0, 1.0 - (_activado_timer - 0.3) / (_activado_duracion - 0.3))

		if _activado_timer >= _activado_duracion:
			_activado = false
			_activado_timer = 0.0
			_glow_intensity = 0.0
		queue_redraw()
	else:
		# Pulso sutil - redibujar cada ~10 frames
		if fmod(_pulso_time, 0.15) < delta * 1.5:
			queue_redraw()


func activar_efecto() -> void:
	_activado = true
	_activado_timer = 0.0
	_glow_intensity = 0.0


# ============================================================
# DIBUJO
# ============================================================

func _draw() -> void:
	var rect: Rect2 = Rect2(Vector2.ZERO, size)
	var color_cat: Color = COLOR_CATEGORIA.get(categoria, Color(0.5, 0.5, 0.5))
	var color_oscuro: Color = COLOR_CATEGORIA_OSCURO.get(categoria, Color(0.3, 0.3, 0.3))
	var pulso: float = (sin(_pulso_time) + 1.0) * 0.5  # 0..1

	# === GLOW DE ACTIVACION ===
	if _glow_intensity > 0.0:
		var glow_color: Color = Color(color_cat.r, color_cat.g, color_cat.b, _glow_intensity * 0.6)
		# Glow exterior (multiples capas)
		for i in range(3):
			var expand: float = (i + 1) * 4.0 * _glow_intensity
			var glow_rect: Rect2 = Rect2(
				Vector2(-expand, -expand),
				size + Vector2(expand * 2, expand * 2)
			)
			glow_color.a = _glow_intensity * 0.25 / (i + 1)
			draw_rect(glow_rect, glow_color, true)

	# === SOMBRA ===
	var sombra_offset: float = 2.0 if not _hover else 4.0
	draw_rect(Rect2(Vector2(sombra_offset, sombra_offset), size), Color(0, 0, 0, 0.5), true)

	# === FONDO ===
	var bg: Color
	if _hover:
		bg = Color(color_oscuro.r * 1.3, color_oscuro.g * 1.3, color_oscuro.b * 1.3, 0.95)
	elif _glow_intensity > 0.0:
		bg = Color(
			lerp(0.08, color_oscuro.r, _glow_intensity * 0.5),
			lerp(0.08, color_oscuro.g, _glow_intensity * 0.5),
			lerp(0.08, color_oscuro.b, _glow_intensity * 0.5),
			0.95
		)
	else:
		bg = Color(0.08, 0.1, 0.12, 0.95)
	draw_rect(rect, bg, true)

	# === FRANJA SUPERIOR DE COLOR ===
	var franja_h: float = 5.0
	var franja_color: Color = color_cat
	if _activado:
		franja_color = Color(
			lerp(color_cat.r, 1.0, _glow_intensity * 0.5),
			lerp(color_cat.g, 1.0, _glow_intensity * 0.5),
			lerp(color_cat.b, 1.0, _glow_intensity * 0.5)
		)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, franja_h)), franja_color, true)

	# === FRANJA INFERIOR ===
	draw_rect(Rect2(Vector2(0, size.y - 3), Vector2(size.x, 3)), Color(color_cat.r, color_cat.g, color_cat.b, 0.5), true)

	# === ICONO ===
	var icono: String = ICONOS.get(nombre, "\u2B50")
	var icono_size: int = 22
	_dibujar_texto(icono, Vector2(8, franja_h + 22), icono_size, color_cat)

	# === NOMBRE ===
	var nombre_corto: String = nombre.replace("El ", "")
	var nombre_color: Color = Color(1, 1, 1, 0.95) if _hover else Color(0.9, 0.9, 0.9, 0.85)
	if _glow_intensity > 0.0:
		nombre_color = Color(1, 1, lerp(0.9, 0.5, _glow_intensity))
	_dibujar_texto(nombre_corto, Vector2(34, franja_h + 20), 13, nombre_color)

	# === DESCRIPCION ===
	var desc_color: Color = Color(0.6, 0.65, 0.7, 0.8)
	if _hover:
		desc_color = Color(0.8, 0.85, 0.9, 0.9)
	# Wrap manual si es muy largo
	if descripcion.length() > 20:
		var mitad: int = descripcion.find(" ", 10)
		if mitad == -1:
			mitad = 15
		_dibujar_texto(descripcion.substr(0, mitad), Vector2(8, franja_h + 42), 10, desc_color)
		_dibujar_texto(descripcion.substr(mitad).strip_edges(), Vector2(8, franja_h + 54), 10, desc_color)
	else:
		_dibujar_texto(descripcion, Vector2(8, franja_h + 42), 10, desc_color)

	# === BORDE ===
	var borde_color: Color
	if _activado and _glow_intensity > 0.3:
		borde_color = Color(
			lerp(color_cat.r, 1.0, _glow_intensity),
			lerp(color_cat.g, 1.0, _glow_intensity),
			lerp(color_cat.b, 1.0, _glow_intensity),
			1.0
		)
	elif _hover:
		borde_color = Color(color_cat.r, color_cat.g, color_cat.b, 0.9)
	else:
		# Pulso sutil en el borde
		var alpha: float = 0.3 + pulso * 0.15
		borde_color = Color(color_cat.r, color_cat.g, color_cat.b, alpha)
	draw_rect(rect, borde_color, false, 1.5 if not _hover else 2.0)

	# === INDICADOR CATEGORIA (bolita de color) ===
	var dot_pos: Vector2 = Vector2(size.x - 10, franja_h + 14)
	var dot_alpha: float = 0.5 + pulso * 0.3
	draw_circle(dot_pos, 4.0, Color(color_cat.r, color_cat.g, color_cat.b, dot_alpha))


func _dibujar_texto(text: String, pos: Vector2, font_size: int, color: Color) -> void:
	var font: Font = ThemeDB.fallback_font
	draw_string(font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
