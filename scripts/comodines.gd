class_name ComodinesManager
extends Node

## Sistema de comodines (power-ups) para el Truco.
## Máximo 2-5 activos por jugador.

signal comodin_activado(nombre: String, descripcion: String)

const MAX_COMODINES := 5

# Definición de todos los comodines disponibles
enum Tipo {
	CHAMUYERO,
	MANO_PESADA,
	MATEMATICO,
	VIOLENTO,
	ADIVINO,
	CLUTCHERO,
	SACADO,
	MUFA,
	TRAMPOSO,
	CAOTICO,
}

const DEFINICIONES := {
	Tipo.CHAMUYERO: {
		"nombre": "El Chamuyero",
		"descripcion": "Bluff exitoso = +2 puntos",
		"categoria": "bluff",
	},
	Tipo.MANO_PESADA: {
		"nombre": "El Mano Pesada",
		"descripcion": "Ganar la primera mano = +1 punto",
		"categoria": "cartas",
	},
	Tipo.MATEMATICO: {
		"nombre": "El Matematico",
		"descripcion": "Envido suma +2",
		"categoria": "apuestas",
	},
	Tipo.MANO_PESADA: {
		"nombre": "El Mano Pesada",
		"descripcion": "Ganar primera mano = +1 punto",
		"categoria": "cartas",
	},
	Tipo.VIOLENTO: {
		"nombre": "El Violento",
		"descripcion": "Truco ganado = +1 punto extra",
		"categoria": "apuestas",
	},
	Tipo.ADIVINO: {
		"nombre": "El Adivino",
		"descripcion": "Ves 1 carta del rival",
		"categoria": "info",
	},
	Tipo.CLUTCHERO: {
		"nombre": "El Clutchero",
		"descripcion": "Ultima mano vale doble",
		"categoria": "reglas",
	},
	Tipo.SACADO: {
		"nombre": "El Sacado",
		"descripcion": "Podes retruco una vez gratis",
		"categoria": "apuestas",
	},
	Tipo.MUFA: {
		"nombre": "El Mufa",
		"descripcion": "Si perdes ronda -> siguiente +2 fuerza",
		"categoria": "cartas",
	},
	Tipo.TRAMPOSO: {
		"nombre": "El Tramposo",
		"descripcion": "Podes cambiar 1 carta por ronda",
		"categoria": "cartas",
	},
	Tipo.CAOTICO: {
		"nombre": "El Caotico",
		"descripcion": "1 carta random cambia de valor",
		"categoria": "rng",
	},
}

# Comodines activos por jugador
var comodines_jugador: Array[Tipo] = []
var comodines_ia: Array[Tipo] = []

# Estado de uso por ronda
var _usados_ronda_jugador: Dictionary = {}
var _usados_ronda_ia: Dictionary = {}

# Mufa: bonus acumulado
var mufa_bonus_jugador: int = 0
var mufa_bonus_ia: int = 0

# Tramposo: ya usó cambio esta ronda
var tramposo_usado_jugador: bool = false
var tramposo_usado_ia: bool = false

# Sacado: ya usó retruco gratis
var sacado_usado_jugador: bool = false
var sacado_usado_ia: bool = false

# ============================================================
# GESTIÓN DE COMODINES
# ============================================================

func asignar_comodines_aleatorios(cantidad: int = 3) -> void:
	var todos: Array = Tipo.values()
	todos.shuffle()
	comodines_jugador.clear()
	comodines_ia.clear()
	for i in range(min(cantidad, todos.size())):
		comodines_jugador.append(todos[i])
	todos.shuffle()
	for i in range(min(cantidad, todos.size())):
		comodines_ia.append(todos[i])

func jugador_tiene(tipo: Tipo) -> bool:
	return tipo in comodines_jugador

func ia_tiene(tipo: Tipo) -> bool:
	return tipo in comodines_ia

func obtener_info(tipo: Tipo) -> Dictionary:
	return DEFINICIONES.get(tipo, {})

func obtener_comodines_jugador() -> Array:
	var resultado: Array = []
	for t in comodines_jugador:
		resultado.append(DEFINICIONES.get(t, {}))
	return resultado

func obtener_comodines_ia() -> Array:
	var resultado: Array = []
	for t in comodines_ia:
		resultado.append(DEFINICIONES.get(t, {}))
	return resultado

# ============================================================
# RESETEO POR RONDA
# ============================================================

func nueva_ronda() -> void:
	_usados_ronda_jugador.clear()
	_usados_ronda_ia.clear()
	tramposo_usado_jugador = false
	tramposo_usado_ia = false
	sacado_usado_jugador = false
	sacado_usado_ia = false

# ============================================================
# APLICACIÓN DE EFECTOS
# ============================================================

## CHAMUYERO: Si el rival no quiso truco y tenías mano mala, +2 pts extra.
func aplicar_chamuyero(es_jugador: bool, fuerza_mano: float) -> int:
	var tipo := Tipo.CHAMUYERO
	if es_jugador and jugador_tiene(tipo) and fuerza_mano < 35:
		emit_signal("comodin_activado", "El Chamuyero", "+2 puntos por bluff exitoso!")
		return 2
	elif not es_jugador and ia_tiene(tipo) and fuerza_mano < 35:
		emit_signal("comodin_activado", "El Chamuyero (IA)", "+2 puntos por bluff!")
		return 2
	return 0

## MANO PESADA: +1 punto si ganaste la primera mano.
func aplicar_mano_pesada(es_jugador: bool) -> int:
	var tipo := Tipo.MANO_PESADA
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Mano Pesada", "+1 punto por ganar primera mano!")
		return 1
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Mano Pesada (IA)", "+1 punto!")
		return 1
	return 0

## MATEMATICO: Envido suma +2 al puntaje.
func aplicar_matematico(es_jugador: bool, envido_base: int) -> int:
	var tipo := Tipo.MATEMATICO
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Matematico", "Envido +2!")
		return envido_base + 2
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Matematico (IA)", "Envido +2!")
		return envido_base + 2
	return envido_base

## VIOLENTO: Truco ganado = +1 punto extra.
func aplicar_violento(es_jugador: bool) -> int:
	var tipo := Tipo.VIOLENTO
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Violento", "+1 punto extra por truco!")
		return 1
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Violento (IA)", "+1 punto extra!")
		return 1
	return 0

## ADIVINO: Revela 1 carta del rival. Devuelve índice o -1.
func aplicar_adivino(es_jugador: bool, cartas_rival: Array) -> int:
	var tipo := Tipo.ADIVINO
	if cartas_rival.is_empty():
		return -1
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Adivino", "Ves una carta del rival!")
		return randi() % cartas_rival.size()
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Adivino (IA)", "La IA ve una de tus cartas!")
		return randi() % cartas_rival.size()
	return -1

## CLUTCHERO: Última mano vale doble (multiplicador).
func aplicar_clutchero(es_jugador: bool, mano_num: int) -> int:
	if mano_num != 2:
		return 1
	var tipo := Tipo.CLUTCHERO
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Clutchero", "Ultima mano vale doble!")
		return 2
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Clutchero (IA)", "Ultima mano doble!")
		return 2
	return 1

## SACADO: Puede cantar retruco gratis (sin riesgo).
func puede_retruco_gratis(es_jugador: bool) -> bool:
	var tipo := Tipo.SACADO
	if es_jugador and jugador_tiene(tipo) and not sacado_usado_jugador:
		return true
	elif not es_jugador and ia_tiene(tipo) and not sacado_usado_ia:
		return true
	return false

func usar_sacado(es_jugador: bool) -> void:
	if es_jugador:
		sacado_usado_jugador = true
	else:
		sacado_usado_ia = true
	emit_signal("comodin_activado", "El Sacado", "Retruco gratis!")

## MUFA: Si perdió la ronda anterior, +2 fuerza (bonus a jerarquía).
func aplicar_mufa(es_jugador: bool, perdio_anterior: bool) -> int:
	if not perdio_anterior:
		return 0
	var tipo := Tipo.MUFA
	if es_jugador and jugador_tiene(tipo):
		emit_signal("comodin_activado", "El Mufa", "+2 fuerza por perder la anterior!")
		return 2
	elif not es_jugador and ia_tiene(tipo):
		emit_signal("comodin_activado", "El Mufa (IA)", "+2 fuerza!")
		return 2
	return 0

## TRAMPOSO: Puede cambiar 1 carta. Devuelve true si puede.
func puede_cambiar_carta(es_jugador: bool) -> bool:
	var tipo := Tipo.TRAMPOSO
	if es_jugador and jugador_tiene(tipo) and not tramposo_usado_jugador:
		return true
	elif not es_jugador and ia_tiene(tipo) and not tramposo_usado_ia:
		return true
	return false

func usar_tramposo(es_jugador: bool, cartas: Array, indice: int, mazo: Mazo) -> Carta:
	if mazo.cartas.is_empty():
		return null
	var nueva := mazo.cartas.pop_back()
	cartas[indice] = nueva
	if es_jugador:
		tramposo_usado_jugador = true
	else:
		tramposo_usado_ia = true
	emit_signal("comodin_activado", "El Tramposo", "Carta cambiada!")
	return nueva

## CAOTICO: 1 carta random cambia de valor efectivo.
## Devuelve {indice, bonus} o null.
func aplicar_caotico(es_jugador: bool, cartas: Array) -> Dictionary:
	var tipo := Tipo.CAOTICO
	var aplica := false
	if es_jugador and jugador_tiene(tipo):
		aplica = true
	elif not es_jugador and ia_tiene(tipo):
		aplica = true

	if aplica and not cartas.is_empty():
		var idx := randi() % cartas.size()
		var bonus := randi_range(-3, 3)
		emit_signal("comodin_activado", "El Caotico", "Carta " + str(idx + 1) + " cambio " + ("+" if bonus >= 0 else "") + str(bonus) + "!")
		return {"indice": idx, "bonus": bonus}
	return {}
