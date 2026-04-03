extends Node

## Máquina de estados principal del juego de Truco.

signal ronda_iniciada
signal mano_jugada(ganador: String, carta_j: Carta, carta_ia: Carta)
signal ronda_terminada(ganador: String)
signal juego_terminado(ganador: String)
signal puntos_actualizados(jugador_pts: int, ia_pts: int)
signal esperando_accion_jugador(acciones: Array)
signal mensaje(texto: String)
signal cartas_repartidas(cartas_jugador: Array, cantidad_ia: int)
signal carta_ia_jugada(carta: Carta)
signal envido_resultado(pts_jugador: int, pts_ia: int, ganador: String)
signal truco_cantado(quien: String, nivel: String)
signal respuesta_truco(quien: String, respuesta: String)

enum Estado {
	INICIO_RONDA,
	ESPERANDO_ENVIDO,
	ESPERANDO_JUGADOR,
	ESPERANDO_IA,
	RESOLVIENDO_MANO,
	RESOLVIENDO_TRUCO,
	RESOLVIENDO_ENVIDO,
	FIN_RONDA,
	FIN_JUEGO,
}

var estado: Estado = Estado.INICIO_RONDA
var mazo: Mazo
var cartas_jugador: Array[Carta] = []
var cartas_ia: Array[Carta] = []

# Puntaje global
var puntos_jugador: int = 0
var puntos_ia: int = 0

# Manos ganadas en la ronda actual
var manos_jugador: int = 0
var manos_ia: int = 0
var mano_actual: int = 0  # 0, 1, 2

# Quién es mano (empieza la ronda)
var es_mano_jugador: bool = true

# Quién empieza la mano actual
var turno_jugador: bool = true

# Cartas jugadas en la mano actual
var carta_jugada_jugador: Carta = null
var carta_jugada_ia: Carta = null

# Estado del truco
var nivel_truco: String = "nada"  # nada, truco, retruco, vale4
var truco_fue_cantado: bool = false
var quien_canto_truco: String = ""  # "jugador" o "ia"
var esperando_respuesta_truco: bool = false

# Estado del envido
var envido_cantado: bool = false
var envido_nivel: String = ""  # envido, real_envido
var esperando_respuesta_envido: bool = false
var envido_resuelto: bool = false
var quien_canto_envido: String = ""

# Truco pendiente mientras se resuelve envido (envido tiene prioridad)
var truco_pendiente: bool = false
var truco_pendiente_nivel: String = ""
var truco_pendiente_quien: String = ""

# Comodines activos
var comodines_jugador: Array = []
var comodines_ia: Array = []

# Referencia al cerebro IA
var ia_brain: AIBrain

func _ready() -> void:
	mazo = Mazo.new()
	ia_brain = AIBrain.new()
	add_child(ia_brain)

# ============================================================
# FLUJO PRINCIPAL
# ============================================================

func iniciar_juego() -> void:
	puntos_jugador = 0
	puntos_ia = 0
	es_mano_jugador = true
	emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
	iniciar_ronda()

func iniciar_ronda() -> void:
	estado = Estado.INICIO_RONDA
	manos_jugador = 0
	manos_ia = 0
	mano_actual = 0
	nivel_truco = "nada"
	truco_fue_cantado = false
	quien_canto_truco = ""
	esperando_respuesta_truco = false
	envido_cantado = false
	envido_nivel = ""
	esperando_respuesta_envido = false
	envido_resuelto = false
	quien_canto_envido = ""
	truco_pendiente = false
	truco_pendiente_nivel = ""
	truco_pendiente_quien = ""
	carta_jugada_jugador = null
	carta_jugada_ia = null

	# Barajar y repartir
	mazo.reiniciar()
	mazo.barajar()
	cartas_jugador = mazo.repartir(3)
	cartas_ia = mazo.repartir(3)

	turno_jugador = es_mano_jugador

	emit_signal("ronda_iniciada")
	emit_signal("cartas_repartidas", cartas_jugador, cartas_ia.size())

	# Fase de envido (solo antes de primera mano)
	estado = Estado.ESPERANDO_ENVIDO
	_preparar_turno()

func _preparar_turno() -> void:
	if turno_jugador:
		var acciones: Array = _obtener_acciones_jugador()
		estado = Estado.ESPERANDO_JUGADOR if not esperando_respuesta_truco and not esperando_respuesta_envido else estado
		emit_signal("esperando_accion_jugador", acciones)
	else:
		estado = Estado.ESPERANDO_IA
		_turno_ia()

# ============================================================
# ACCIONES DISPONIBLES
# ============================================================

func _obtener_acciones_jugador() -> Array:
	var acciones: Array = []

	# Puede jugar carta si no está esperando respuestas
	if not esperando_respuesta_truco and not esperando_respuesta_envido:
		acciones.append("jugar_carta")

	# Envido: en la primera mano, solo si el jugador NO tiró su carta todavía.
	# El rival puede cantar envido si todavía no jugó su carta (aunque el mano ya tiró).
	var puede_envido: bool = mano_actual == 0 and not envido_resuelto and not envido_cantado and carta_jugada_jugador == null
	if puede_envido and not esperando_respuesta_envido:
		acciones.append("envido")
		acciones.append("real_envido")

	# Truco: si no se llegó al máximo y no hay envido pendiente
	if not esperando_respuesta_truco and not esperando_respuesta_envido:
		if nivel_truco == "nada" and quien_canto_truco != "jugador":
			acciones.append("truco")
		elif nivel_truco == "truco" and quien_canto_truco != "jugador":
			acciones.append("retruco")
		elif nivel_truco == "retruco" and quien_canto_truco != "jugador":
			acciones.append("vale4")

	# Respuestas a truco
	if esperando_respuesta_truco and quien_canto_truco == "ia":
		acciones.append("quiero_truco")
		acciones.append("no_quiero_truco")
		# Puede subir la apuesta
		if nivel_truco == "truco":
			acciones.append("retruco")
		elif nivel_truco == "retruco":
			acciones.append("vale4")
		# Envido tiene prioridad: puede responder con envido al truco en primera mano
		if puede_envido:
			acciones.append("envido")
			acciones.append("real_envido")

	# Respuestas a envido
	if esperando_respuesta_envido and quien_canto_envido == "ia":
		acciones.append("quiero_envido")
		acciones.append("no_quiero_envido")

	# Retirarse
	if not esperando_respuesta_truco and not esperando_respuesta_envido:
		acciones.append("retirarse")

	return acciones

# ============================================================
# ACCIONES DEL JUGADOR
# ============================================================

func jugador_jugar_carta(indice: int) -> void:
	if estado != Estado.ESPERANDO_JUGADOR and estado != Estado.ESPERANDO_ENVIDO:
		return
	if indice < 0 or indice >= cartas_jugador.size():
		return

	carta_jugada_jugador = cartas_jugador[indice]
	cartas_jugador.remove_at(indice)

	# Si la IA ya jugó, resolver mano
	# (al resolver la mano 0, envido se marca como resuelto)
	if carta_jugada_ia != null:
		_resolver_mano()
	else:
		# Turno de la IA
		turno_jugador = false
		_preparar_turno()

func jugador_cantar_envido(nivel: String) -> void:
	if mano_actual != 0 or envido_resuelto or envido_cantado or carta_jugada_jugador != null:
		return

	# Si había truco pendiente, guardarlo (envido tiene prioridad)
	if esperando_respuesta_truco:
		truco_pendiente = true
		truco_pendiente_nivel = nivel_truco
		truco_pendiente_quien = quien_canto_truco
		esperando_respuesta_truco = false

	envido_cantado = true
	envido_nivel = nivel
	quien_canto_envido = "jugador"
	esperando_respuesta_envido = true
	emit_signal("mensaje", "¡Cantaste " + nivel.replace("_", " ") + "!")

	# IA decide si acepta
	var acepta: bool = ia_brain.decidir_envido_respuesta(cartas_ia, nivel, puntos_ia, puntos_jugador)
	_procesar_respuesta_envido("ia", acepta)

func jugador_cantar_truco(nivel: String) -> void:
	nivel_truco = nivel
	quien_canto_truco = "jugador"
	esperando_respuesta_truco = true
	truco_fue_cantado = true
	emit_signal("truco_cantado", "jugador", nivel)
	emit_signal("mensaje", "¡Cantaste " + nivel + "!")

	# En primera mano, la IA puede responder con envido primero (tiene prioridad)
	# Solo si la IA no tiró su carta todavía
	if mano_actual == 0 and not envido_resuelto and not envido_cantado and carta_jugada_ia == null:
		var decision_envido: String = ia_brain.decidir_cantar_envido(cartas_ia, puntos_ia, puntos_jugador)
		if decision_envido != "":
			# Guardar truco como pendiente
			truco_pendiente = true
			truco_pendiente_nivel = nivel_truco
			truco_pendiente_quien = quien_canto_truco
			esperando_respuesta_truco = false
			# Cantar envido
			envido_cantado = true
			envido_nivel = decision_envido
			quien_canto_envido = "ia"
			esperando_respuesta_envido = true
			emit_signal("mensaje", "La IA responde con " + decision_envido.replace("_", " ") + "! (envido tiene prioridad)")
			turno_jugador = true
			_preparar_turno()
			return

	# IA decide sobre el truco
	var respuesta: String = ia_brain.decidir_truco_respuesta(cartas_ia, nivel, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
	_procesar_respuesta_truco("ia", respuesta)

func jugador_responder_truco(respuesta: String) -> void:
	if not esperando_respuesta_truco:
		return
	_procesar_respuesta_truco("jugador", respuesta)

func jugador_responder_envido(acepta: bool) -> void:
	if not esperando_respuesta_envido:
		return
	_procesar_respuesta_envido("jugador", acepta)

func jugador_retirarse() -> void:
	var pts: int = GameData.PUNTOS_TRUCO.get(nivel_truco, 1)
	puntos_ia += pts
	emit_signal("mensaje", "Te retiraste. La IA gana " + str(pts) + " punto(s).")
	emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
	_fin_ronda("ia")

# ============================================================
# TRUCO: RESOLUCIÓN
# ============================================================

func _procesar_respuesta_truco(quien_responde: String, respuesta: String) -> void:
	esperando_respuesta_truco = false

	if respuesta == "no_quiero":
		# El que no quiso pierde los puntos del nivel anterior
		var pts_anterior: int
		match nivel_truco:
			"truco": pts_anterior = 1
			"retruco": pts_anterior = 2
			"vale4": pts_anterior = 3
			_: pts_anterior = 1

		if quien_responde == "ia":
			puntos_jugador += pts_anterior
			emit_signal("mensaje", "La IA no quiso. Ganás " + str(pts_anterior) + " punto(s).")
		else:
			puntos_ia += pts_anterior
			emit_signal("mensaje", "No quisiste. La IA gana " + str(pts_anterior) + " punto(s).")

		emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
		_fin_ronda("jugador" if quien_responde == "ia" else "ia")

	elif respuesta == "quiero":
		emit_signal("respuesta_truco", quien_responde, "quiero")
		if quien_responde == "ia":
			emit_signal("mensaje", "La IA quiere el " + nivel_truco + ".")
		else:
			emit_signal("mensaje", "Aceptaste el " + nivel_truco + ".")
		_preparar_turno()

	elif respuesta in ["retruco", "vale4"]:
		# Sube la apuesta
		nivel_truco = respuesta
		quien_canto_truco = quien_responde
		esperando_respuesta_truco = true
		if quien_responde == "ia":
			emit_signal("truco_cantado", "ia", respuesta)
			emit_signal("mensaje", "La IA canta " + respuesta + "!")
			# Ahora el jugador debe responder
			turno_jugador = true
			_preparar_turno()
		else:
			emit_signal("truco_cantado", "jugador", respuesta)
			emit_signal("mensaje", "¡Cantaste " + respuesta + "!")
			var resp_ia: String = ia_brain.decidir_truco_respuesta(cartas_ia, respuesta, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
			_procesar_respuesta_truco("ia", resp_ia)

# ============================================================
# ENVIDO: RESOLUCIÓN
# ============================================================

func _procesar_respuesta_envido(quien_responde: String, acepta: bool) -> void:
	esperando_respuesta_envido = false
	envido_resuelto = true

	if not acepta:
		# El que no quiso pierde 1 punto
		if quien_responde == "ia":
			puntos_jugador += 1
			emit_signal("mensaje", "La IA no quiso el envido. Ganás 1 punto.")
		else:
			puntos_ia += 1
			emit_signal("mensaje", "No quisiste el envido. La IA gana 1 punto.")
		emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
		_preparar_turno()
		return

	# Se juega el envido
	var env_jugador: int = GameData.calcular_envido(cartas_jugador + _cartas_jugadas_jugador())
	var env_ia: int = GameData.calcular_envido(cartas_ia + _cartas_jugadas_ia())
	var pts_envido: int = GameData.PUNTOS_ENVIDO.get(envido_nivel, 2)

	var ganador_env: String
	if env_jugador > env_ia:
		puntos_jugador += pts_envido
		ganador_env = "jugador"
	elif env_ia > env_jugador:
		puntos_ia += pts_envido
		ganador_env = "ia"
	else:
		# Empate: gana el mano
		if es_mano_jugador:
			puntos_jugador += pts_envido
			ganador_env = "jugador"
		else:
			puntos_ia += pts_envido
			ganador_env = "ia"

	if quien_responde == "ia":
		emit_signal("mensaje", "La IA quiso. Envido: Vos " + str(env_jugador) + " - IA " + str(env_ia))
	else:
		emit_signal("mensaje", "Aceptaste. Envido: Vos " + str(env_jugador) + " - IA " + str(env_ia))
	emit_signal("envido_resultado", env_jugador, env_ia, ganador_env)
	emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)

	_verificar_fin_juego()
	if estado != Estado.FIN_JUEGO:
		# Si había truco pendiente, retomarlo ahora que envido se resolvió
		if truco_pendiente:
			truco_pendiente = false
			nivel_truco = truco_pendiente_nivel
			quien_canto_truco = truco_pendiente_quien
			esperando_respuesta_truco = true
			if quien_canto_truco == "ia":
				emit_signal("mensaje", "Ahora respondé al " + nivel_truco + " de la IA.")
				turno_jugador = true
				_preparar_turno()
			else:
				emit_signal("mensaje", "La IA responde a tu " + nivel_truco + ".")
				var respuesta: String = ia_brain.decidir_truco_respuesta(cartas_ia, nivel_truco, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
				_procesar_respuesta_truco("ia", respuesta)
		else:
			_preparar_turno()

# Helper: cartas ya jugadas (para calcular envido con la mano original)
var _historial_jugador: Array[Carta] = []
var _historial_ia: Array[Carta] = []

func _cartas_jugadas_jugador() -> Array[Carta]:
	return _historial_jugador

func _cartas_jugadas_ia() -> Array[Carta]:
	return _historial_ia

# ============================================================
# TURNO DE LA IA
# ============================================================

func _turno_ia() -> void:
	# Esperar un momento para que se sienta natural
	await get_tree().create_timer(0.8).timeout

	# ¿La IA quiere cantar envido? (primera mano, solo si no tiró su carta)
	if mano_actual == 0 and not envido_resuelto and not envido_cantado and carta_jugada_ia == null:
		var decision_envido: String = ia_brain.decidir_cantar_envido(cartas_ia, puntos_ia, puntos_jugador)
		if decision_envido != "":
			envido_cantado = true
			envido_nivel = decision_envido
			quien_canto_envido = "ia"
			esperando_respuesta_envido = true
			emit_signal("mensaje", "La IA canta " + decision_envido.replace("_", " ") + "!")
			turno_jugador = true
			_preparar_turno()
			return

	# ¿La IA quiere cantar truco?
	if not esperando_respuesta_truco and not esperando_respuesta_envido:
		var decision_truco: String = ia_brain.decidir_cantar_truco(cartas_ia, nivel_truco, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
		if decision_truco != "":
			nivel_truco = decision_truco
			quien_canto_truco = "ia"
			esperando_respuesta_truco = true
			truco_fue_cantado = true
			emit_signal("truco_cantado", "ia", decision_truco)
			emit_signal("mensaje", "La IA canta " + decision_truco + "!")
			turno_jugador = true
			_preparar_turno()
			return

	# Jugar carta
	var indice_carta: int = ia_brain.elegir_carta(cartas_ia, carta_jugada_jugador, manos_ia, manos_jugador, mano_actual)
	carta_jugada_ia = cartas_ia[indice_carta]
	cartas_ia.remove_at(indice_carta)
	emit_signal("carta_ia_jugada", carta_jugada_ia)

	# Si el jugador ya jugó, resolver
	if carta_jugada_jugador != null:
		_resolver_mano()
	else:
		turno_jugador = true
		_preparar_turno()

# ============================================================
# RESOLVER MANO
# ============================================================

func _resolver_mano() -> void:
	estado = Estado.RESOLVIENDO_MANO

	# Al completarse la primera mano, ya no se puede cantar envido
	if mano_actual == 0:
		envido_resuelto = true

	var jer_j: int = carta_jugada_jugador.obtener_jerarquia()
	var jer_ia: int = carta_jugada_ia.obtener_jerarquia()

	var ganador: String
	if jer_j > jer_ia:
		manos_jugador += 1
		ganador = "jugador"
		turno_jugador = true
	elif jer_ia > jer_j:
		manos_ia += 1
		ganador = "ia"
		turno_jugador = false
	else:
		# Empate: gana el mano
		if es_mano_jugador:
			manos_jugador += 1
			ganador = "jugador"
		else:
			manos_ia += 1
			ganador = "ia"
		# El que ganó la mano empieza la siguiente
		turno_jugador = (ganador == "jugador")

	_historial_jugador.append(carta_jugada_jugador)
	_historial_ia.append(carta_jugada_ia)

	emit_signal("mano_jugada", ganador, carta_jugada_jugador, carta_jugada_ia)

	carta_jugada_jugador = null
	carta_jugada_ia = null
	mano_actual += 1

	# ¿Alguien ganó 2 manos?
	if manos_jugador >= 2:
		_ganar_ronda("jugador")
	elif manos_ia >= 2:
		_ganar_ronda("ia")
	elif mano_actual >= 3:
		# 3 manos jugadas sin ganador claro → gana el mano
		if es_mano_jugador:
			_ganar_ronda("jugador")
		else:
			_ganar_ronda("ia")
	else:
		_preparar_turno()

func _ganar_ronda(ganador: String) -> void:
	var pts: int = GameData.PUNTOS_TRUCO.get(nivel_truco, 1)
	if ganador == "jugador":
		puntos_jugador += pts
	else:
		puntos_ia += pts

	emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
	_fin_ronda(ganador)

func _fin_ronda(ganador: String) -> void:
	estado = Estado.FIN_RONDA
	_historial_jugador.clear()
	_historial_ia.clear()
	emit_signal("ronda_terminada", ganador)

	# Cambiar mano
	es_mano_jugador = not es_mano_jugador

	_verificar_fin_juego()

func _verificar_fin_juego() -> void:
	if puntos_jugador >= GameData.PUNTOS_OBJETIVO:
		estado = Estado.FIN_JUEGO
		emit_signal("juego_terminado", "jugador")
	elif puntos_ia >= GameData.PUNTOS_OBJETIVO:
		estado = Estado.FIN_JUEGO
		emit_signal("juego_terminado", "ia")

func siguiente_ronda() -> void:
	if estado == Estado.FIN_JUEGO:
		return
	iniciar_ronda()
