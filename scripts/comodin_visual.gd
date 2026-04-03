class_name ComodinVisual
extends Control

## Tarjeta visual de comodin (power-up).
## Diseño limpio: color de categoria, nombre claro, descripcion legible.
## Sin emojis - solo texto y color.

var tipo: int = -1
var nombre: String = ""
var descripcion: String = ""
var categoria: String = ""
var _hover: bool = false

# Activacion
var _activado: bool = false
var _activado_timer: float = 0.0
var _glow: float = 0.0

const COLOR_CAT: Dictionary = {
	"bluff": Color(0.9, 0.5, 0.1),
	"cartas": Color(0.2, 0.7, 0.3),
	"apuestas": Color(0.85, 0.2, 0.25),
	"info": Color(0.3, 0.5, 0.9),
	"reglas": Color(0.65, 0.35, 0.9),
	"rng": Color(0.9, 0.75, 0.1),
}

# Letra inicial como icono simple
const ICONO_LETRA: Dictionary = {
	"El Chamuyero": "CH",
	"El Mano Pesada": "MP",
	"El Matematico": "MA",
	"El Violento": "VI",
	"El Adivino": "AD",
	"El Clutchero": "CL",
	"El Sacado": "SA",
	"El Mufa": "MU",
	"El Tramposo": "TR",
	"El Caotico": "CA",
}

static func crear(tipo_comodin: int, info: Dictionary) -> ComodinVisual:
	var cv: ComodinVisual = ComodinVisual.new()
	cv.tipo = tipo_comodin
	cv.nombre = info.get("nombre", "?")
	cv.descripcion = info.get("descripcion", "")
	cv.categoria = info.get("categoria", "cartas")
	cv.custom_minimum_size = Vector2(140, 65)
	cv.mouse_filter = Control.MOUSE_FILTER_STOP
	cv.mouse_entered.connect(func(): cv._hover = true; cv.queue_redraw())
	cv.mouse_exited.connect(func(): cv._hover = false; cv.queue_redraw())
	cv.tooltip_text = cv.nombre + " - " + cv.descripcion
	return cv

func _process(delta: float) -> void:
	if _activado:
		_activado_timer += delta
		_glow = max(0.0, 1.0 - _activado_timer / 2.0)
		if _activado_timer >= 2.0:
			_activado = false
			_glow = 0.0
		queue_redraw()

func activar_efecto() -> void:
	_activado = true
	_activado_timer = 0.0
	_glow = 1.0
	queue_redraw()

func _draw() -> void:
	var r: Rect2 = Rect2(Vector2.ZERO, size)
	var col: Color = COLOR_CAT.get(categoria, Color(0.5, 0.5, 0.5))

	# Glow de activacion
	if _glow > 0.1:
		for i in range(2):
			var e: float = (i + 1) * 3.0 * _glow
			draw_rect(Rect2(Vector2(-e, -e), size + Vector2(e * 2, e * 2)), Color(col.r, col.g, col.b, _glow * 0.2 / (i + 1)), true)

	# Sombra
	draw_rect(Rect2(Vector2(2, 2), size), Color(0, 0, 0, 0.4), true)

	# Fondo
	var bg: Color
	if _hover:
		bg = Color(0.12, 0.14, 0.18, 0.95)
	elif _glow > 0.0:
		bg = Color(lerp(0.07, col.r * 0.3, _glow), lerp(0.08, col.g * 0.3, _glow), lerp(0.1, col.b * 0.3, _glow), 0.95)
	else:
		bg = Color(0.07, 0.08, 0.1, 0.95)
	draw_rect(r, bg, true)

	# Franja izquierda de color (identificador visual rapido)
	draw_rect(Rect2(Vector2.ZERO, Vector2(4, size.y)), col, true)

	# Circulo con iniciales
	var circ_pos: Vector2 = Vector2(22, size.y / 2.0)
	var circ_r: float = 12.0
	draw_circle(circ_pos, circ_r, Color(col.r, col.g, col.b, 0.25 if not _hover else 0.4))
	draw_arc(circ_pos, circ_r, 0, TAU, 12, col, 1.5)
	var iniciales: String = ICONO_LETRA.get(nombre, "??")
	var f: Font = ThemeDB.fallback_font
	var ts: Vector2 = f.get_string_size(iniciales, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(f, Vector2(circ_pos.x - ts.x / 2.0, circ_pos.y + ts.y / 4.0), iniciales, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)

	# Nombre (sin "El ")
	var nombre_corto: String = nombre.replace("El ", "")
	var nc: Color = Color(1, 1, 1, 0.95) if _hover else Color(0.9, 0.9, 0.9, 0.85)
	if _glow > 0.0:
		nc = Color(1, 1, lerp(1.0, 0.5, _glow))
	draw_string(f, Vector2(40, 22), nombre_corto, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, nc)

	# Descripcion
	var dc: Color = Color(0.65, 0.7, 0.75, 0.9) if _hover else Color(0.5, 0.55, 0.6, 0.75)
	draw_string(f, Vector2(40, 40), descripcion, HORIZONTAL_ALIGNMENT_LEFT, int(size.x - 46), 10, dc)

	# Borde
	var bc: Color
	if _glow > 0.3:
		bc = Color(lerp(col.r, 1.0, _glow), lerp(col.g, 1.0, _glow), lerp(col.b, 1.0, _glow))
	elif _hover:
		bc = Color(col.r, col.g, col.b, 0.8)
	else:
		bc = Color(col.r, col.g, col.b, 0.3)
	draw_rect(r, bc, false, 1.5 if not _hover else 2.0)
