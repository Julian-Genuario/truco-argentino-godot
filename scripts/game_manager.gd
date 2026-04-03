extends Node

## Maquina de estados del juego de Truco Argentino.
## Soporta flor (3 del mismo palo), encuentros progresivos.

signal ronda_iniciada
signal flor_cantada(quien: String)
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
	TURNO_JUGADOR,
	TURNO_IA,
	ESPERANDO_RESPUESTA_JUGADOR,  # jugador debe responder envido/truco
	RESOLVIENDO,
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

# Quien es mano (empieza)
var es_mano_jugador: bool = true
# Quien juega en este momento
var turno_jugador: bool = true
# Quien jugó primera carta en la mano (para volver despues de envido)
var _turno_original: bool = true

# Cartas jugadas en la mano actual
var carta_jugada_jugador: Carta = null
var carta_jugada_ia: Carta = null

# Truco
var nivel_truco: String = "nada"
var truco_fue_cantado: bool = false
var quien_canto_truco: String = ""
var esperando_respuesta_truco: bool = false

# Envido
var envido_cantado: bool = false
var envido_nivel: String = ""
var esperando_respuesta_envido: bool = false
var envido_resuelto: bool = false
var quien_canto_envido: String = ""

# Truco pendiente (envido tiene prioridad)
var truco_pendiente: bool = false
var truco_pendiente_nivel: String = ""
var truco_pendiente_quien: String = ""

# Flor
var flor_resuelta: bool = false
var flor_jugador_cantada: bool = false
var flor_ia_cantada: bool = false
var esperando_respuesta_flor: bool = false
var quien_canto_flor: String = ""

# Comodines
var comodines_jugador: Array = []
var comodines_ia: Array = []

var ia_brain: AIBrain

# Historial para calcular envido con mano original
var _historial_jugador: Array[Carta] = []
var _historial_ia: Array[Carta] = []

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
	flor_resuelta = false
	flor_jugador_cantada = false
	flor_ia_cantada = false
	esperando_respuesta_flor = false
	quien_canto_flor = ""
	carta_jugada_jugador = null
	carta_jugada_ia = null
	_historial_jugador.clear()
	_historial_ia.clear()

	mazo.reiniciar()
	mazo.barajar()
	cartas_jugador = mazo.repartir(3)
	cartas_ia = mazo.repartir(3)

	turno_jugador = es_mano_jugador
	_turno_original = es_mano_jugador

	emit_signal("ronda_iniciada")
	emit_signal("cartas_repartidas", cartas_jugador, cartas_ia.size())

	_siguiente_turno()

# ============================================================
# CONTROL DE TURNOS
# ============================================================

func _siguiente_turno() -> void:
	# Si la ronda o juego terminó, no hacer nada
	if estado == Estado.FIN_RONDA or estado == Estado.FIN_JUEGO:
		return

	if turno_jugador:
		estado = Estado.TURNO_JUGADOR
		var acciones: Array = _obtener_acciones_jugador()
		emit_signal("esperando_accion_jugador", acciones)
	else:
		estado = Estado.TURNO_IA
		_turno_ia()

func _pedir_respuesta_jugador() -> void:
	estado = Estado.ESPERANDO_RESPUESTA_JUGADOR
	var acciones: Array = _obtener_acciones_jugador()
	emit_signal("esperando_accion_jugador", acciones)

# ============================================================
# ACCIONES DISPONIBLES
# ============================================================

func _obtener_acciones_jugador() -> Array:
	var acciones: Array = []

	var hay_respuesta: bool = esperando_respuesta_truco or esperando_respuesta_envido or esperando_respuesta_flor

	# Puede jugar carta si no hay respuesta pendiente
	if not hay_respuesta:
		acciones.append("jugar_carta")

	# Primera mano, no tiró carta
	var primera_mano_libre: bool = (mano_actual == 0 and carta_jugada_jugador == null)

	# Flor: si con_flor activo, primera mano, tiene flor, no cantó todavía
	if GameData.con_flor and primera_mano_libre and not flor_resuelta and not flor_jugador_cantada:
		if GameData.tiene_flor(cartas_jugador + _historial_jugador):
			if not esperando_respuesta_flor:
				acciones.append("flor")

	# Respuesta a flor de la IA
	if esperando_respuesta_flor and quien_canto_flor == "ia":
		acciones.append("quiero_flor")
		acciones.append("no_quiero_flor")
		# Contra flor
		if GameData.tiene_flor(cartas_jugador + _historial_jugador):
			acciones.append("contra_flor")

	# Envido: primera mano, no resuelto, no cantado, sin flor cantada
	var puede_envido: bool = (primera_mano_libre and not envido_resuelto
		and not envido_cantado and not flor_jugador_cantada and not flor_ia_cantada)

	if puede_envido and not esperando_respuesta_envido:
		acciones.append("envido")
		acciones.append("real_envido")

	# Truco
	if not hay_respuesta:
		if nivel_truco == "nada" and quien_canto_truco != "jugador":
			acciones.append("truco")
		elif nivel_truco == "truco" and quien_canto_truco != "jugador":
			acciones.append("retruco")
		elif nivel_truco == "retruco" and quien_canto_truco != "jugador":
			acciones.append("vale4")

	# Respuestas a truco de la IA
	if esperando_respuesta_truco and quien_canto_truco == "ia":
		acciones.append("quiero_truco")
		acciones.append("no_quiero_truco")
		if nivel_truco == "truco":
			acciones.append("retruco")
		elif nivel_truco == "retruco":
			acciones.append("vale4")
		if puede_envido:
			acciones.append("envido")
			acciones.append("real_envido")

	# Respuestas a envido de la IA
	if esperando_respuesta_envido and quien_canto_envido == "ia":
		acciones.append("quiero_envido")
		acciones.append("no_quiero_envido")

	# Retirarse
	if not hay_respuesta:
		acciones.append("retirarse")

	return acciones

# ============================================================
# ACCIONES DEL JUGADOR
# ============================================================

func jugador_jugar_carta(indice: int) -> void:
	# Solo puede jugar en su turno y sin respuestas pendientes
	if estado != Estado.TURNO_JUGADOR:
		return
	if esperando_respuesta_truco or esperando_respuesta_envido:
		return
	if indice < 0 or indice >= cartas_jugador.size():
		return

	carta_jugada_jugador = cartas_jugador[indice]
	cartas_jugador.remove_at(indice)

	if carta_jugada_ia != null:
		_resolver_mano()
	else:
		turno_jugador = false
		_siguiente_turno()

func jugador_cantar_envido(nivel: String) -> void:
	if mano_actual != 0 or envido_resuelto or envido_cantado or carta_jugada_jugador != null:
		return

	# Si había truco pendiente, guardarlo
	if esperando_respuesta_truco:
		truco_pendiente = true
		truco_pendiente_nivel = nivel_truco
		truco_pendiente_quien = quien_canto_truco
		esperando_respuesta_truco = false

	envido_cantado = true
	envido_nivel = nivel
	quien_canto_envido = "jugador"
	esperando_respuesta_envido = true
	emit_signal("mensaje", "Cantaste " + nivel.replace("_", " ") + "!")

	# IA decide
	var acepta: bool = ia_brain.decidir_envido_respuesta(cartas_ia, nivel, puntos_ia, puntos_jugador)
	_procesar_respuesta_envido("ia", acepta)

func jugador_cantar_truco(nivel: String) -> void:
	nivel_truco = nivel
	quien_canto_truco = "jugador"
	esperando_respuesta_truco = true
	truco_fue_cantado = true
	emit_signal("truco_cantado", "jugador", nivel)
	emit_signal("mensaje", "Cantaste " + nivel + "!")

	# IA puede responder con envido primero (prioridad, primera mano)
	if mano_actual == 0 and not envido_resuelto and not envido_cantado and carta_jugada_ia == null:
		var decision_envido: String = ia_brain.decidir_cantar_envido(cartas_ia, puntos_ia, puntos_jugador)
		if decision_envido != "":
			truco_pendiente = true
			truco_pendiente_nivel = nivel_truco
			truco_pendiente_quien = quien_canto_truco
			esperando_respuesta_truco = false

			envido_cantado = true
			envido_nivel = decision_envido
			quien_canto_envido = "ia"
			esperando_respuesta_envido = true
			emit_signal("mensaje", "La IA responde con " + decision_envido.replace("_", " ") + "! (envido tiene prioridad)")
			_pedir_respuesta_jugador()
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

# ============================================================
# FLOR
# ============================================================

func jugador_cantar_flor() -> void:
	if not GameData.con_flor or mano_actual != 0 or flor_resuelta or flor_jugador_cantada:
		return
	if not GameData.tiene_flor(cartas_jugador + _historial_jugador):
		return

	flor_jugador_cantada = true
	quien_canto_flor = "jugador"
	emit_signal("flor_cantada", "jugador")
	emit_signal("mensaje", "Cantaste FLOR!")

	# Flor mata envido
	envido_resuelto = true
	envido_cantado = true

	# IA tiene flor?
	if GameData.tiene_flor(cartas_ia + _historial_ia):
		flor_ia_cantada = true
		emit_signal("mensaje", "La IA tambien tiene FLOR! Se comparan.")
		_resolver_flor()
	else:
		# IA no tiene flor, jugador gana 3 puntos
		puntos_jugador += 3
		emit_signal("mensaje", "La IA no tiene flor. Ganas 3 puntos!")
		emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
		flor_resuelta = true
		if not _verificar_fin_juego():
			_siguiente_turno()

func jugador_responder_flor(respuesta: String) -> void:
	if not esperando_respuesta_flor:
		return
	esperando_respuesta_flor = false

	if respuesta == "no_quiero":
		puntos_ia += 3
		emit_signal("mensaje", "No quisiste la flor. La IA gana 3 puntos.")
		emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
		flor_resuelta = true
		envido_resuelto = true
		if not _verificar_fin_juego():
			_siguiente_turno()
	elif respuesta == "contra_flor":
		# Jugador tiene flor, se comparan con puntos dobles (6)
		flor_jugador_cantada = true
		emit_signal("mensaje", "Contra flor!")
		_resolver_flor_con_puntos(6)
	else:  # quiero
		flor_jugador_cantada = true
		_resolver_flor()

func _resolver_flor() -> void:
	_resolver_flor_con_puntos(3)

func _resolver_flor_con_puntos(pts: int) -> void:
	flor_resuelta = true
	envido_resuelto = true

	var flor_j: int = GameData.calcular_flor(cartas_jugador + _historial_jugador)
	var flor_ia: int = GameData.calcular_flor(cartas_ia + _historial_ia)

	emit_signal("mensaje", "Flor: Vos " + str(flor_j) + " - IA " + str(flor_ia))

	var ganador: String
	if flor_j > flor_ia:
		puntos_jugador += pts
		ganador = "jugador"
	elif flor_ia > flor_j:
		puntos_ia += pts
		ganador = "ia"
	else:
		# Empate: gana mano
		if es_mano_jugador:
			puntos_jugador += pts
			ganador = "jugador"
		else:
			puntos_ia += pts
			ganador = "ia"

	emit_signal("mensaje", ("Ganas " if ganador == "jugador" else "La IA gana ") + str(pts) + " puntos por flor!")
	emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)

	if not _verificar_fin_juego():
		_siguiente_turno()

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
		var pts_anterior: int
		match nivel_truco:
			"truco": pts_anterior = 1
			"retruco": pts_anterior = 2
			"vale4": pts_anterior = 3
			_: pts_anterior = 1

		if quien_responde == "ia":
			puntos_jugador += pts_anterior
			emit_signal("mensaje", "La IA no quiso. Ganas " + str(pts_anterior) + " punto(s).")
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
		# Continuar el juego - volver al turno que corresponde
		_siguiente_turno()

	elif respuesta in ["retruco", "vale4"]:
		nivel_truco = respuesta
		quien_canto_truco = quien_responde
		esperando_respuesta_truco = true
		if quien_responde == "ia":
			emit_signal("truco_cantado", "ia", respuesta)
			emit_signal("mensaje", "La IA canta " + respuesta + "!")
			turno_jugador = true
			_pedir_respuesta_jugador()
		else:
			emit_signal("truco_cantado", "jugador", respuesta)
			emit_signal("mensaje", "Cantaste " + respuesta + "!")
			var resp_ia: String = ia_brain.decidir_truco_respuesta(cartas_ia, respuesta, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
			_procesar_respuesta_truco("ia", resp_ia)

# ============================================================
# ENVIDO: RESOLUCIÓN
# ============================================================

func _procesar_respuesta_envido(quien_responde: String, acepta: bool) -> void:
	esperando_respuesta_envido = false
	envido_resuelto = true

	if not acepta:
		if quien_responde == "ia":
			puntos_jugador += 1
			emit_signal("mensaje", "La IA no quiso el envido. Ganas 1 punto.")
		else:
			puntos_ia += 1
			emit_signal("mensaje", "No quisiste el envido. La IA gana 1 punto.")
		emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
		_post_envido()
		return

	# Se juega el envido
	var env_jugador: int = GameData.calcular_envido(cartas_jugador + _historial_jugador)
	var env_ia: int = GameData.calcular_envido(cartas_ia + _historial_ia)
	var pts_envido: int = GameData.PUNTOS_ENVIDO.get(envido_nivel, 2)

	var ganador_env: String
	if env_jugador > env_ia:
		puntos_jugador += pts_envido
		ganador_env = "jugador"
	elif env_ia > env_jugador:
		puntos_ia += pts_envido
		ganador_env = "ia"
	else:
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

	_post_envido()

func _post_envido() -> void:
	# Verificar si alguien gano por puntos de envido
	if _verificar_fin_juego():
		return

	# Si habia truco pendiente, retomarlo
	if truco_pendiente:
		truco_pendiente = false
		nivel_truco = truco_pendiente_nivel
		quien_canto_truco = truco_pendiente_quien
		esperando_respuesta_truco = true
		if quien_canto_truco == "ia":
			emit_signal("mensaje", "Ahora responde al " + nivel_truco + " de la IA.")
			turno_jugador = true
			_pedir_respuesta_jugador()
		else:
			emit_signal("mensaje", "La IA responde a tu " + nivel_truco + ".")
			var respuesta: String = ia_brain.decidir_truco_respuesta(cartas_ia, nivel_truco, manos_ia, manos_jugador, puntos_ia, puntos_jugador)
			_procesar_respuesta_truco("ia", respuesta)
	else:
		# Restaurar el turno al que corresponde (el mano juega primero)
		turno_jugador = _turno_original
		_siguiente_turno()

# ============================================================
# TURNO DE LA IA
# ============================================================

func _turno_ia() -> void:
	await get_tree().create_timer(0.8).timeout

	# Verificar que no cambio el estado durante la espera
	if estado != Estado.TURNO_IA:
		return

	# Cantar flor?
	if GameData.con_flor and mano_actual == 0 and not flor_resuelta and not flor_ia_cantada and carta_jugada_ia == null:
		if GameData.tiene_flor(cartas_ia + _historial_ia):
			flor_ia_cantada = true
			quien_canto_flor = "ia"
			envido_resuelto = true
			envido_cantado = true
			emit_signal("flor_cantada", "ia")
			emit_signal("mensaje", "La IA canta FLOR!")
			# Jugador tiene flor?
			if GameData.tiene_flor(cartas_jugador + _historial_jugador):
				esperando_respuesta_flor = true
				turno_jugador = true
				_pedir_respuesta_jugador()
				return
			else:
				# Jugador no tiene flor, IA gana 3 puntos
				puntos_ia += 3
				emit_signal("mensaje", "No tenes flor. La IA gana 3 puntos.")
				emit_signal("puntos_actualizados", puntos_jugador, puntos_ia)
				flor_resuelta = true
				if _verificar_fin_juego():
					return
				# IA sigue su turno normal (jugar carta)

	# Cantar envido?
	if mano_actual == 0 and not envido_resuelto and not envido_cantado and carta_jugada_ia == null:
		var decision_envido: String = ia_brain.decidir_cantar_envido(cartas_ia, puntos_ia, puntos_jugador)
		if decision_envido != "":
			envido_cantado = true
			envido_nivel = decision_envido
			quien_canto_envido = "ia"
			esperando_respuesta_envido = true
			emit_signal("mensaje", "La IA canta " + decision_envido.replace("_", " ") + "!")
			turno_jugador = true
			_pedir_respuesta_jugador()
			return

	# Cantar truco?
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
			_pedir_respuesta_jugador()
			return

	# Jugar carta
	var indice_carta: int = ia_brain.elegir_carta(cartas_ia, carta_jugada_jugador, manos_ia, manos_jugador, mano_actual)
	carta_jugada_ia = cartas_ia[indice_carta]
	cartas_ia.remove_at(indice_carta)
	emit_signal("carta_ia_jugada", carta_jugada_ia)

	if carta_jugada_jugador != null:
		_resolver_mano()
	else:
		turno_jugador = true
		_siguiente_turno()

# ============================================================
# RESOLVER MANO
# ============================================================

func _resolver_mano() -> void:
	estado = Estado.RESOLVIENDO

	# Al completar la primera mano, no se puede cantar envido mas
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
		turno_jugador = (ganador == "jugador")

	_historial_jugador.append(carta_jugada_jugador)
	_historial_ia.append(carta_jugada_ia)

	emit_signal("mano_jugada", ganador, carta_jugada_jugador, carta_jugada_ia)

	carta_jugada_jugador = null
	carta_jugada_ia = null
	mano_actual += 1

	# Guardar turno original para la nueva mano
	_turno_original = turno_jugador

	# Alguien gano 2 manos?
	if manos_jugador >= 2:
		_ganar_ronda("jugador")
	elif manos_ia >= 2:
		_ganar_ronda("ia")
	elif mano_actual >= 3:
		# 3 manos sin ganador claro: gana el mano
		if es_mano_jugador:
			_ganar_ronda("jugador")
		else:
			_ganar_ronda("ia")
	else:
		_siguiente_turno()

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
	es_mano_jugador = not es_mano_jugador
	_verificar_fin_juego()

func _verificar_fin_juego() -> bool:
	if puntos_jugador >= GameData.puntos_objetivo:
		estado = Estado.FIN_JUEGO
		emit_signal("juego_terminado", "jugador")
		return true
	elif puntos_ia >= GameData.puntos_objetivo:
		estado = Estado.FIN_JUEGO
		emit_signal("juego_terminado", "ia")
		return true
	return false

func siguiente_ronda() -> void:
	if estado == Estado.FIN_JUEGO:
		return
	iniciar_ronda()
