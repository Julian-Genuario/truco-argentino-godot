extends Control

## UI principal. Conecta GameManager con la interfaz.
## Soporta flor, encuentros progresivos, y comodines.

@onready var gm: Node = $GameManager
@onready var lbl_pts_jugador: Label = $HBoxPrincipal/VBox/TopBar/TopBarContent/PuntajeJugador
@onready var lbl_pts_ia: Label = $HBoxPrincipal/VBox/TopBar/TopBarContent/PuntajeIA
@onready var lbl_info: Label = $HBoxPrincipal/VBox/TopBar/TopBarContent/InfoRonda
@onready var contenedor_cartas_ia: HBoxContainer = $HBoxPrincipal/VBox/ZonaIA/CartasIA
@onready var contenedor_cartas_jugador: HBoxContainer = $HBoxPrincipal/VBox/ZonaJugador/CartasJugador
@onready var lbl_resultado: Label = $HBoxPrincipal/VBox/ZonaMesa/ResultadoMano
@onready var lbl_mano_score: Label = $HBoxPrincipal/VBox/ZonaMesa/ManoScore
@onready var log_text: RichTextLabel = $HBoxPrincipal/VBox/Log
@onready var comodines_container: VBoxContainer = $HBoxPrincipal/ComodinesLateral/ComodinesMargen/ComodinesVBox/ComodinesHBox
@onready var comodin_popup: Label = $ComodinPopup
@onready var lbl_encuentro: Label = $HBoxPrincipal/ComodinesLateral/ComodinesMargen/ComodinesVBox/LabelComodinesTitle

@onready var cartas_m1: HBoxContainer = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano1/CartasM1
@onready var cartas_m2: HBoxContainer = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano2/CartasM2
@onready var cartas_m3: HBoxContainer = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano3/CartasM3
@onready var result_m1: Label = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano1/ResultM1
@onready var result_m2: Label = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano2/ResultM2
@onready var result_m3: Label = $HBoxPrincipal/VBox/ZonaMesa/MesaManos/Mano3/ResultM3

# Botones existentes
@onready var btn_envido: Button = $HBoxPrincipal/VBox/Acciones/BtnEnvido
@onready var btn_real_envido: Button = $HBoxPrincipal/VBox/Acciones/BtnRealEnvido
@onready var btn_truco: Button = $HBoxPrincipal/VBox/Acciones/BtnTruco
@onready var btn_retruco: Button = $HBoxPrincipal/VBox/Acciones/BtnRetruco
@onready var btn_vale4: Button = $HBoxPrincipal/VBox/Acciones/BtnVale4
@onready var btn_quiero: Button = $HBoxPrincipal/VBox/Acciones/BtnQuiero
@onready var btn_no_quiero: Button = $HBoxPrincipal/VBox/Acciones/BtnNoQuiero
@onready var btn_retirarse: Button = $HBoxPrincipal/VBox/Acciones/BtnRetirarse
@onready var btn_siguiente: Button = $HBoxPrincipal/VBox/Acciones/BtnSiguiente

# Botones de flor (creados dinámicamente)
var btn_flor: Button
var btn_contra_flor: Button

var comodines_mgr: ComodinesManager
var _contenedores_mano: Array = []
var _resultados_mano: Array = []
var _comodin_visuals: Dictionary = {}

func _ready() -> void:
	# Crear botones de flor dinámicamente
	btn_flor = Button.new()
	btn_flor.text = "Flor"
	btn_flor.custom_minimum_size = Vector2(100, 38)
	btn_flor.add_theme_font_size_override("font_size", 14)
	btn_flor.visible = false
	btn_flor.pressed.connect(_on_btn_flor)
	$HBoxPrincipal/VBox/Acciones.add_child(btn_flor)

	btn_contra_flor = Button.new()
	btn_contra_flor.text = "Contra Flor"
	btn_contra_flor.custom_minimum_size = Vector2(100, 38)
	btn_contra_flor.add_theme_font_size_override("font_size", 14)
	btn_contra_flor.visible = false
	btn_contra_flor.pressed.connect(_on_btn_contra_flor)
	$HBoxPrincipal/VBox/Acciones.add_child(btn_contra_flor)

	# Comodines segun encuentro
	comodines_mgr = ComodinesManager.new()
	add_child(comodines_mgr)
	var cant_comodines: int = GameData.COMODINES_POR_ENCUENTRO.get(GameData.encuentro_actual, 3)
	comodines_mgr.asignar_comodines_aleatorios(cant_comodines)
	comodines_mgr.comodin_activado.connect(_on_comodin_activado)

	_contenedores_mano = [cartas_m1, cartas_m2, cartas_m3]
	_resultados_mano = [result_m1, result_m2, result_m3]

	# Señales del GM
	gm.ronda_iniciada.connect(_on_ronda_iniciada)
	gm.mano_jugada.connect(_on_mano_jugada)
	gm.ronda_terminada.connect(_on_ronda_terminada)
	gm.juego_terminado.connect(_on_juego_terminado)
	gm.puntos_actualizados.connect(_on_puntos_actualizados)
	gm.esperando_accion_jugador.connect(_on_esperando_accion)
	gm.mensaje.connect(_on_mensaje)
	gm.cartas_repartidas.connect(_on_cartas_repartidas)
	gm.carta_ia_jugada.connect(_on_carta_ia_jugada)
	gm.truco_cantado.connect(_on_truco_cantado)

	# Botones
	btn_envido.pressed.connect(_on_btn_envido)
	btn_real_envido.pressed.connect(_on_btn_real_envido)
	btn_truco.pressed.connect(_on_btn_truco)
	btn_retruco.pressed.connect(_on_btn_retruco)
	btn_vale4.pressed.connect(_on_btn_vale4)
	btn_quiero.pressed.connect(_on_btn_quiero)
	btn_no_quiero.pressed.connect(_on_btn_no_quiero)
	btn_retirarse.pressed.connect(_on_btn_retirarse)
	btn_siguiente.pressed.connect(_on_btn_siguiente)

	_ocultar_todos_botones()
	_actualizar_titulo_encuentro()
	_mostrar_comodines()
	comodin_popup.modulate.a = 0.0

	_log("[color=cyan]Encuentro " + str(GameData.encuentro_actual) + " de " + str(GameData.TOTAL_ENCUENTROS) + "[/color]")
	if GameData.con_flor:
		_log("[color=yellow]Modo: Con Flor[/color]")
	_log("A " + str(GameData.puntos_objetivo) + " puntos")

	gm.comodines_jugador = comodines_mgr.comodines_jugador
	gm.comodines_ia = comodines_mgr.comodines_ia
	gm.iniciar_juego()

func _actualizar_titulo_encuentro() -> void:
	lbl_encuentro.text = "ENCUENTRO " + str(GameData.encuentro_actual) + "/" + str(GameData.TOTAL_ENCUENTROS)

# ============================================================
# COMODINES
# ============================================================

func _mostrar_comodines() -> void:
	_limpiar_contenedor(comodines_container)
	_comodin_visuals.clear()

	for i in range(comodines_mgr.comodines_jugador.size()):
		var tipo: int = comodines_mgr.comodines_jugador[i]
		var info: Dictionary = comodines_mgr.obtener_info(tipo)
		var cv: ComodinVisual = ComodinVisual.crear(tipo, info)
		comodines_container.add_child(cv)
		_comodin_visuals[info.get("nombre", "")] = cv
		cv.modulate.a = 0.0
		cv.scale = Vector2(0.5, 0.5)
		cv.pivot_offset = cv.custom_minimum_size / 2.0
		var tw: Tween = create_tween()
		tw.set_parallel(true)
		tw.tween_property(cv, "modulate:a", 1.0, 0.4).set_delay(i * 0.15)
		tw.tween_property(cv, "scale", Vector2.ONE, 0.4).set_delay(i * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_comodin_activado(nombre: String, descripcion: String) -> void:
	_log("[color=magenta]* " + nombre + ": " + descripcion + "[/color]")
	var nl: String = nombre.replace(" (IA)", "")
	if _comodin_visuals.has(nl):
		_comodin_visuals[nl].activar_efecto()
	_mostrar_popup_comodin(nombre, descripcion)

func _mostrar_popup_comodin(nombre: String, desc: String) -> void:
	comodin_popup.text = nombre + " - " + desc
	comodin_popup.add_theme_color_override("font_color", Color(1, 0.4, 0.4) if "(IA)" in nombre else Color(1, 0.9, 0.3))
	var tw: Tween = create_tween()
	comodin_popup.modulate.a = 0.0
	comodin_popup.position.y = 300.0
	tw.set_parallel(true)
	tw.tween_property(comodin_popup, "modulate:a", 1.0, 0.25)
	tw.tween_property(comodin_popup, "position:y", 270.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(1.2)
	tw.chain().set_parallel(true)
	tw.tween_property(comodin_popup, "modulate:a", 0.0, 0.5)
	tw.tween_property(comodin_popup, "position:y", 250.0, 0.5)

# ============================================================
# CARTAS
# ============================================================

func _on_cartas_repartidas(cartas_j: Array, cant_ia: int) -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	_limpiar_contenedor(contenedor_cartas_ia)
	for i in range(cartas_j.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(cartas_j[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)
		_animar_entrada_carta(cv, i)
	for i in range(cant_ia):
		var oc: CartaVisual = CartaVisual.crear_carta_oculta()
		contenedor_cartas_ia.add_child(oc)
		_animar_entrada_carta(oc, i)
	_limpiar_mesa()
	lbl_resultado.text = ""
	lbl_mano_score.text = "Manos: Vos 0 - IA 0"

func _animar_entrada_carta(carta: CartaVisual, indice: int) -> void:
	carta.modulate.a = 0.0
	carta.scale = Vector2(0.3, 0.3)
	carta.pivot_offset = carta.custom_minimum_size / 2.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(carta, "modulate:a", 1.0, 0.3).set_delay(indice * 0.12)
	tw.tween_property(carta, "scale", Vector2.ONE, 0.35).set_delay(indice * 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _limpiar_mesa() -> void:
	for i in range(3):
		_limpiar_contenedor(_contenedores_mano[i])
		_contenedores_mano[i].add_child(CartaVisual.crear_slot_vacio())
		_contenedores_mano[i].add_child(CartaVisual.crear_slot_vacio())
		_resultados_mano[i].text = ""

func _on_carta_clickeada(indice: int) -> void:
	var mano_idx: int = gm.mano_actual
	if mano_idx < 3 and indice < gm.cartas_jugador.size():
		_colocar_carta_mesa(mano_idx, gm.cartas_jugador[indice], true)
	gm.jugador_jugar_carta(indice)
	_actualizar_cartas_jugador()

func _colocar_carta_mesa(mano_idx: int, carta: Carta, es_jugador: bool) -> void:
	if mano_idx >= 3:
		return
	var cont: HBoxContainer = _contenedores_mano[mano_idx]
	var slot: int = 0 if es_jugador else 1
	if slot < cont.get_child_count():
		cont.get_child(slot).queue_free()
		await get_tree().process_frame
	var cv: CartaVisual = CartaVisual.crear_carta_mesa(carta, es_jugador)
	cont.add_child(cv)
	cont.move_child(cv, slot)
	cv.modulate.a = 0.0
	cv.scale = Vector2(1.3, 1.3)
	cv.pivot_offset = cv.custom_minimum_size / 2.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(cv, "modulate:a", 1.0, 0.2)
	tw.tween_property(cv, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _actualizar_cartas_jugador() -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	for i in range(gm.cartas_jugador.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(gm.cartas_jugador[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)

func _on_carta_ia_jugada(carta: Carta) -> void:
	_colocar_carta_mesa(gm.mano_actual, carta, false)
	if contenedor_cartas_ia.get_child_count() > 0:
		var oc: Node = contenedor_cartas_ia.get_child(0)
		var tw: Tween = create_tween()
		tw.tween_property(oc, "modulate:a", 0.0, 0.15)
		tw.tween_callback(oc.queue_free)

# ============================================================
# EVENTOS
# ============================================================

func _on_ronda_iniciada() -> void:
	comodines_mgr.nueva_ronda()
	_log("[color=cyan]--- Nueva Ronda ---[/color]")
	var txt: String = "Sos mano" if gm.es_mano_jugador else "IA es mano"
	_log(txt)
	lbl_info.text = txt
	_animar_label_bounce(lbl_info)

func _on_mano_jugada(ganador: String, carta_j: Carta, carta_ia: Carta) -> void:
	var mi: int = max(gm.mano_actual - 1, 0)
	var txt: String = "Ganaste" if ganador == "jugador" else "IA gano"
	lbl_resultado.text = txt
	lbl_mano_score.text = "Manos: Vos " + str(gm.manos_jugador) + " - IA " + str(gm.manos_ia)
	_log(carta_j.nombre_legible() + " vs " + carta_ia.nombre_legible() + " -> " + txt)
	_animar_label_bounce(lbl_resultado)
	if mi < 3:
		_resultados_mano[mi].text = txt
		_resultados_mano[mi].add_theme_color_override("font_color", Color(0.3, 1, 0.4) if ganador == "jugador" else Color(1, 0.4, 0.4))
		_animar_label_bounce(_resultados_mano[mi])
	if gm.mano_actual == 1:
		var bonus: int = comodines_mgr.aplicar_mano_pesada(ganador == "jugador")
		if bonus > 0:
			if ganador == "jugador":
				gm.puntos_jugador += bonus
			else:
				gm.puntos_ia += bonus
			gm.emit_signal("puntos_actualizados", gm.puntos_jugador, gm.puntos_ia)

func _on_ronda_terminada(ganador: String) -> void:
	var txt: String = "Ganaste la ronda!" if ganador == "jugador" else "La IA gano la ronda"
	_log("[color=yellow]" + txt + "[/color]")
	lbl_resultado.text = txt
	_animar_resultado_ronda(ganador == "jugador")
	if gm.truco_fue_cantado:
		var bonus: int = comodines_mgr.aplicar_violento(ganador == "jugador")
		if bonus > 0:
			if ganador == "jugador":
				gm.puntos_jugador += bonus
			else:
				gm.puntos_ia += bonus
			gm.emit_signal("puntos_actualizados", gm.puntos_jugador, gm.puntos_ia)
	_ocultar_todos_botones()
	btn_siguiente.visible = true
	_animar_boton_entrada(btn_siguiente)

func _on_juego_terminado(ganador: String) -> void:
	_ocultar_todos_botones()

	if ganador == "jugador":
		if GameData.encuentro_actual < GameData.TOTAL_ENCUENTROS:
			var txt: String = "GANASTE el encuentro " + str(GameData.encuentro_actual) + "!"
			_log("[color=gold][b]" + txt + "[/b][/color]")
			lbl_info.text = txt
			# Botón para siguiente encuentro
			btn_siguiente.text = "Siguiente Encuentro"
			btn_siguiente.visible = true
			btn_siguiente.pressed.disconnect(_on_btn_siguiente)
			btn_siguiente.pressed.connect(_on_siguiente_encuentro)
			_animar_boton_entrada(btn_siguiente)
		else:
			_log("[color=gold][b]GANASTE LA PARTIDA COMPLETA![/b][/color]")
			lbl_info.text = "CAMPEON! Ganaste los 3 encuentros!"
			btn_siguiente.text = "Volver al Menu"
			btn_siguiente.visible = true
			btn_siguiente.pressed.disconnect(_on_btn_siguiente)
			btn_siguiente.pressed.connect(_on_volver_menu)
			_animar_boton_entrada(btn_siguiente)
	else:
		_log("[color=red][b]PERDISTE el encuentro " + str(GameData.encuentro_actual) + "[/b][/color]")
		lbl_info.text = "PERDISTE... La IA gano"
		btn_siguiente.text = "Reintentar Encuentro"
		btn_siguiente.visible = true
		btn_siguiente.pressed.disconnect(_on_btn_siguiente)
		btn_siguiente.pressed.connect(_on_reintentar_encuentro)
		_animar_boton_entrada(btn_siguiente)

	_animar_fin_juego(ganador == "jugador")

func _on_siguiente_encuentro() -> void:
	GameData.avanzar_encuentro()
	get_tree().reload_current_scene()

func _on_reintentar_encuentro() -> void:
	get_tree().reload_current_scene()

func _on_volver_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _on_puntos_actualizados(pts_j: int, pts_ia: int) -> void:
	lbl_pts_jugador.text = "Vos: " + str(pts_j)
	lbl_pts_ia.text = "IA: " + str(pts_ia)
	_animar_label_punch(lbl_pts_jugador)
	_animar_label_punch(lbl_pts_ia)

func _on_esperando_accion(acciones: Array) -> void:
	_ocultar_todos_botones()
	var visibles: Array[Button] = []

	# Flor
	if "flor" in acciones:
		btn_flor.visible = true
		visibles.append(btn_flor)
	if "contra_flor" in acciones:
		btn_contra_flor.visible = true
		visibles.append(btn_contra_flor)
	if "quiero_flor" in acciones:
		btn_quiero.visible = true
		visibles.append(btn_quiero)
	if "no_quiero_flor" in acciones:
		btn_no_quiero.visible = true
		visibles.append(btn_no_quiero)

	if "envido" in acciones:
		btn_envido.visible = true
		visibles.append(btn_envido)
	if "real_envido" in acciones:
		btn_real_envido.visible = true
		visibles.append(btn_real_envido)
	if "truco" in acciones:
		btn_truco.visible = true
		visibles.append(btn_truco)
	if "retruco" in acciones:
		btn_retruco.visible = true
		visibles.append(btn_retruco)
	if "vale4" in acciones:
		btn_vale4.visible = true
		visibles.append(btn_vale4)
	if "quiero_truco" in acciones or "quiero_envido" in acciones:
		if not btn_quiero.visible:
			btn_quiero.visible = true
			visibles.append(btn_quiero)
	if "no_quiero_truco" in acciones or "no_quiero_envido" in acciones:
		if not btn_no_quiero.visible:
			btn_no_quiero.visible = true
			visibles.append(btn_no_quiero)
	if "retirarse" in acciones:
		btn_retirarse.visible = true
		visibles.append(btn_retirarse)

	for i in range(visibles.size()):
		_animar_boton_entrada(visibles[i], i * 0.05)

	var puede_jugar: bool = "jugar_carta" in acciones
	for child in contenedor_cartas_jugador.get_children():
		if child is CartaVisual:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if puede_jugar else Control.MOUSE_FILTER_IGNORE
			child.modulate.a = 1.0 if puede_jugar else 0.5

func _on_mensaje(texto: String) -> void:
	_log(texto)

func _on_truco_cantado(quien: String, nivel: String) -> void:
	lbl_info.text = ("IA canto " if quien == "ia" else "Cantaste ") + nivel + "!"
	_animar_truco_cantado()

# ============================================================
# BOTONES
# ============================================================

func _on_btn_flor() -> void:
	gm.jugador_cantar_flor()

func _on_btn_contra_flor() -> void:
	gm.jugador_responder_flor("contra_flor")

func _on_btn_envido() -> void:
	gm.jugador_cantar_envido("envido")

func _on_btn_real_envido() -> void:
	gm.jugador_cantar_envido("real_envido")

func _on_btn_truco() -> void:
	gm.jugador_cantar_truco("truco")

func _on_btn_retruco() -> void:
	if gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("retruco")
	else:
		gm.jugador_cantar_truco("retruco")

func _on_btn_vale4() -> void:
	if gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("vale4")
	else:
		gm.jugador_cantar_truco("vale4")

func _on_btn_quiero() -> void:
	if gm.esperando_respuesta_flor:
		gm.jugador_responder_flor("quiero")
	elif gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("quiero")
	elif gm.esperando_respuesta_envido:
		gm.jugador_responder_envido(true)

func _on_btn_no_quiero() -> void:
	if gm.esperando_respuesta_flor:
		gm.jugador_responder_flor("no_quiero")
	elif gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("no_quiero")
	elif gm.esperando_respuesta_envido:
		gm.jugador_responder_envido(false)

func _on_btn_retirarse() -> void:
	gm.jugador_retirarse()

func _on_btn_siguiente() -> void:
	gm.siguiente_ronda()

# ============================================================
# ANIMACIONES
# ============================================================

func _animar_label_bounce(label: Control) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.3, 1.3)
	create_tween().tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animar_label_punch(label: Control) -> void:
	label.pivot_offset = label.size / 2.0
	var tw: Tween = create_tween()
	tw.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	tw.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _animar_boton_entrada(boton: Button, delay: float = 0.0) -> void:
	boton.modulate.a = 0.0
	boton.pivot_offset = boton.size / 2.0
	boton.scale = Vector2(0.8, 0.8)
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(boton, "modulate:a", 1.0, 0.2).set_delay(delay)
	tw.tween_property(boton, "scale", Vector2.ONE, 0.25).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animar_truco_cantado() -> void:
	lbl_info.pivot_offset = lbl_info.size / 2.0
	var tw: Tween = create_tween()
	tw.tween_property(lbl_info, "scale", Vector2(1.5, 1.5), 0.15)
	tw.tween_property(lbl_info, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _animar_resultado_ronda(gano: bool) -> void:
	lbl_resultado.pivot_offset = lbl_resultado.size / 2.0
	lbl_resultado.add_theme_color_override("font_color", Color(0.3, 1, 0.4) if gano else Color(1, 0.4, 0.4))
	var tw: Tween = create_tween()
	tw.tween_property(lbl_resultado, "scale", Vector2(1.4, 1.4), 0.2)
	tw.tween_property(lbl_resultado, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _animar_fin_juego(gano: bool) -> void:
	lbl_info.pivot_offset = lbl_info.size / 2.0
	lbl_info.add_theme_color_override("font_color", Color(1, 0.85, 0.2) if gano else Color(1, 0.3, 0.3))
	lbl_info.scale = Vector2(0.3, 0.3)
	lbl_info.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.set_parallel(true)
	tw.tween_property(lbl_info, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(lbl_info, "modulate:a", 1.0, 0.3)
	tw.chain().tween_property(lbl_info, "scale", Vector2.ONE, 0.3)

# ============================================================
# UTILIDADES
# ============================================================

func _ocultar_todos_botones() -> void:
	btn_envido.visible = false
	btn_real_envido.visible = false
	btn_truco.visible = false
	btn_retruco.visible = false
	btn_vale4.visible = false
	btn_quiero.visible = false
	btn_no_quiero.visible = false
	btn_retirarse.visible = false
	btn_siguiente.visible = false
	btn_flor.visible = false
	btn_contra_flor.visible = false

func _limpiar_contenedor(cont: Container) -> void:
	for child in cont.get_children():
		child.queue_free()

func _log(texto: String) -> void:
	log_text.append_text("\n" + texto)
