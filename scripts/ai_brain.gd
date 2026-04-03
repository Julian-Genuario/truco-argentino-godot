class_name AIBrain
extends Node

## Cerebro de la IA para tomar decisiones en el truco.
## Usa heurísticas basadas en la fuerza de la mano.

# ============================================================
# EVALUACIÓN DE MANO
# ============================================================

## Devuelve un score de 0-100 basado en la jerarquía de las cartas.
func _fuerza_mano(cartas: Array[Carta]) -> float:
	if cartas.is_empty():
		return 0.0
	var total := 0.0
	for c in cartas:
		total += c.obtener_jerarquia()
	# Max teórico: 15+14+13 = 42
	return (total / 42.0) * 100.0

## Devuelve la carta más alta de la mano.
func _mejor_carta(cartas: Array[Carta]) -> int:
	var mejor_idx := 0
	var mejor_jer := 0
	for i in range(cartas.size()):
		var jer := cartas[i].obtener_jerarquia()
		if jer > mejor_jer:
			mejor_jer = jer
			mejor_idx = i
	return mejor_idx

## Devuelve la carta más baja.
func _peor_carta(cartas: Array[Carta]) -> int:
	var peor_idx := 0
	var peor_jer := 999
	for i in range(cartas.size()):
		var jer := cartas[i].obtener_jerarquia()
		if jer < peor_jer:
			peor_jer = jer
			peor_idx = i
	return peor_idx

## Devuelve la carta más baja que gana a la carta rival, o -1.
func _carta_que_gana_justa(cartas: Array[Carta], rival: Carta) -> int:
	var jer_rival := rival.obtener_jerarquia()
	var mejor_idx := -1
	var mejor_jer := 999
	for i in range(cartas.size()):
		var jer := cartas[i].obtener_jerarquia()
		if jer > jer_rival and jer < mejor_jer:
			mejor_jer = jer
			mejor_idx = i
	return mejor_idx

# ============================================================
# DECISIÓN: QUÉ CARTA JUGAR
# ============================================================

func elegir_carta(cartas: Array[Carta], carta_rival: Carta, manos_ganadas_ia: int, manos_ganadas_rival: int, mano_num: int) -> int:
	if cartas.size() == 1:
		return 0

	# Si el rival ya jugó, intentar ganar con la carta justa
	if carta_rival != null:
		var idx_gana := _carta_que_gana_justa(cartas, carta_rival)
		if idx_gana >= 0:
			return idx_gana
		# No puede ganar → tirar la peor
		return _peor_carta(cartas)

	# Si somos primeros en tirar
	match mano_num:
		0:
			# Primera mano: jugar carta media-alta
			if cartas.size() == 3:
				var indices := _ordenar_por_jerarquia(cartas)
				return indices[1]  # La del medio
			return _mejor_carta(cartas)
		1:
			# Segunda mano
			if manos_ganadas_ia >= 1:
				# Ya ganamos una, tirar la peor para conservar
				return _peor_carta(cartas)
			else:
				# Necesitamos ganar, tirar la mejor
				return _mejor_carta(cartas)
		_:
			# Tercera mano: todo o nada
			return _mejor_carta(cartas)

func _ordenar_por_jerarquia(cartas: Array[Carta]) -> Array:
	var indices: Array = []
	for i in range(cartas.size()):
		indices.append(i)
	# Bubble sort simple por jerarquía
	for i in range(indices.size()):
		for j in range(i + 1, indices.size()):
			if cartas[indices[i]].obtener_jerarquia() > cartas[indices[j]].obtener_jerarquia():
				var tmp = indices[i]
				indices[i] = indices[j]
				indices[j] = tmp
	return indices

# ============================================================
# DECISIÓN: CANTAR ENVIDO
# ============================================================

func decidir_cantar_envido(cartas: Array[Carta], pts_ia: int, pts_rival: int) -> String:
	var envido_val := GameData.calcular_envido(cartas)

	# Envido fuerte (>= 30): cantar real_envido
	if envido_val >= 30:
		return "real_envido" if randf() > 0.3 else "envido"

	# Envido bueno (>= 25): cantar envido
	if envido_val >= 25:
		return "envido" if randf() > 0.3 else ""

	# Envido medio (>= 20): a veces cantar (bluff)
	if envido_val >= 20:
		return "envido" if randf() > 0.7 else ""

	# Envido bajo: bluff ocasional
	if randf() > 0.9:
		return "envido"

	return ""

# ============================================================
# DECISIÓN: RESPONDER ENVIDO
# ============================================================

func decidir_envido_respuesta(cartas: Array[Carta], nivel: String, pts_ia: int, pts_rival: int) -> bool:
	var envido_val := GameData.calcular_envido(cartas)

	match nivel:
		"envido":
			return envido_val >= 22 or (envido_val >= 18 and randf() > 0.5)
		"real_envido":
			return envido_val >= 27 or (envido_val >= 23 and randf() > 0.5)

	return envido_val >= 25

# ============================================================
# DECISIÓN: CANTAR TRUCO
# ============================================================

func decidir_cantar_truco(cartas: Array[Carta], nivel_actual: String, manos_ia: int, manos_rival: int, pts_ia: int, pts_rival: int) -> String:
	var fuerza := _fuerza_mano(cartas)

	# Ya está en vale4, no se puede subir
	if nivel_actual == "vale4":
		return ""

	# Con mano muy fuerte
	if fuerza >= 65:
		if nivel_actual == "nada":
			return "truco"
		elif nivel_actual == "truco":
			return "retruco" if randf() > 0.3 else ""
		elif nivel_actual == "retruco":
			return "vale4" if randf() > 0.4 else ""

	# Con mano decente + ya ganamos una mano
	if fuerza >= 45 and manos_ia >= 1:
		if nivel_actual == "nada":
			return "truco" if randf() > 0.3 else ""

	# Bluff ocasional con mano mala
	if fuerza < 35 and nivel_actual == "nada" and randf() > 0.85:
		return "truco"

	return ""

# ============================================================
# DECISIÓN: RESPONDER TRUCO
# ============================================================

func decidir_truco_respuesta(cartas: Array[Carta], nivel: String, manos_ia: int, manos_rival: int, pts_ia: int, pts_rival: int) -> String:
	var fuerza := _fuerza_mano(cartas)

	match nivel:
		"truco":
			if fuerza >= 60:
				# Subir a retruco
				return "retruco" if randf() > 0.4 else "quiero"
			elif fuerza >= 35:
				return "quiero"
			elif fuerza >= 20 and manos_ia >= 1:
				return "quiero" if randf() > 0.3 else "no_quiero"
			else:
				return "no_quiero" if randf() > 0.2 else "quiero"

		"retruco":
			if fuerza >= 70:
				return "vale4" if randf() > 0.4 else "quiero"
			elif fuerza >= 45:
				return "quiero"
			elif fuerza >= 30 and manos_ia >= 1:
				return "quiero" if randf() > 0.4 else "no_quiero"
			else:
				return "no_quiero"

		"vale4":
			if fuerza >= 75:
				return "quiero"
			elif fuerza >= 55 and manos_ia >= 1:
				return "quiero" if randf() > 0.3 else "no_quiero"
			else:
				return "no_quiero"

	return "no_quiero"
