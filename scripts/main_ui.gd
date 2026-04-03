extends Control

## Script principal de UI. Conecta el GameManager con la interfaz visual.
## Incluye animaciones de cartas, comodines visuales estilizados, y efectos.

@onready var gm: Node = $GameManager
@onready var lbl_pts_jugador: Label = $VBox/TopBar/TopBarContent/PuntajeJugador
@onready var lbl_pts_ia: Label = $VBox/TopBar/TopBarContent/PuntajeIA
@onready var lbl_info: Label = $VBox/TopBar/TopBarContent/InfoRonda
@onready var contenedor_cartas_ia: HBoxContainer = $VBox/ZonaIA/CartasIA
@onready var contenedor_cartas_jugador: HBoxContainer = $VBox/ZonaJugador/CartasJugador
@onready var lbl_resultado: Label = $VBox/ZonaMesa/ResultadoMano
@onready var lbl_mano_score: Label = $VBox/ZonaMesa/ManoScore
@onready var log_text: RichTextLabel = $VBox/Log
@onready var comodines_hbox: HBoxContainer = $VBox/ComodinesPanel/ComodinesVBox/ComodinesHBox
@onready var comodin_popup: Label = $ComodinPopup

# Contenedores de las 3 manos en la mesa
@onready var cartas_m1: HBoxContainer = $VBox/ZonaMesa/MesaManos/Mano1/CartasM1
@onready var cartas_m2: HBoxContainer = $VBox/ZonaMesa/MesaManos/Mano2/CartasM2
@onready var cartas_m3: HBoxContainer = $VBox/ZonaMesa/MesaManos/Mano3/CartasM3
@onready var result_m1: Label = $VBox/ZonaMesa/MesaManos/Mano1/ResultM1
@onready var result_m2: Label = $VBox/ZonaMesa/MesaManos/Mano2/ResultM2
@onready var result_m3: Label = $VBox/ZonaMesa/MesaManos/Mano3/ResultM3

# Botones
@onready var btn_envido: Button = $VBox/Acciones/BtnEnvido
@onready var btn_real_envido: Button = $VBox/Acciones/BtnRealEnvido
@onready var btn_truco: Button = $VBox/Acciones/BtnTruco
@onready var btn_retruco: Button = $VBox/Acciones/BtnRetruco
@onready var btn_vale4: Button = $VBox/Acciones/BtnVale4
@onready var btn_quiero: Button = $VBox/Acciones/BtnQuiero
@onready var btn_no_quiero: Button = $VBox/Acciones/BtnNoQuiero
@onready var btn_retirarse: Button = $VBox/Acciones/BtnRetirarse
@onready var btn_siguiente: Button = $VBox/Acciones/BtnSiguiente

var comodines_mgr: ComodinesManager

# Referencia a los contenedores de mano por indice
var _contenedores_mano: Array = []
var _resultados_mano: Array = []

# Mapa nombre_comodin -> ComodinVisual para activar efectos
var _comodin_visuals: Dictionary = {}

func _ready() -> void:
	# Crear sistema de comodines
	comodines_mgr = ComodinesManager.new()
	add_child(comodines_mgr)
	comodines_mgr.asignar_comodines_aleatorios(3)
	comodines_mgr.comodin_activado.connect(_on_comodin_activado)

	_contenedores_mano = [cartas_m1, cartas_m2, cartas_m3]
	_resultados_mano = [result_m1, result_m2, result_m3]

	# Conectar senales del GameManager
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

	# Conectar botones
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
	_mostrar_comodines()

	# Ocultar popup
	comodin_popup.modulate.a = 0.0

	# Iniciar juego
	gm.comodines_jugador = comodines_mgr.comodines_jugador
	gm.comodines_ia = comodines_mgr.comodines_ia
	gm.iniciar_juego()

# ============================================================
# COMODINES VISUALES
# ============================================================

func _mostrar_comodines() -> void:
	_limpiar_contenedor(comodines_hbox)
	_comodin_visuals.clear()

	for i in range(comodines_mgr.comodines_jugador.size()):
		var tipo: int = comodines_mgr.comodines_jugador[i]
		var info: Dictionary = comodines_mgr.obtener_info(tipo)
		var cv: ComodinVisual = ComodinVisual.crear(tipo, info)
		comodines_hbox.add_child(cv)
		_comodin_visuals[info.get("nombre", "")] = cv

		# Animacion de entrada escalonada
		cv.modulate.a = 0.0
		cv.scale = Vector2(0.5, 0.5)
		cv.pivot_offset = cv.custom_minimum_size / 2.0
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(cv, "modulate:a", 1.0, 0.4).set_delay(i * 0.15)
		tween.tween_property(cv, "scale", Vector2.ONE, 0.4).set_delay(i * 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_comodin_activado(nombre: String, descripcion: String) -> void:
	_log("[color=magenta]* " + nombre + ": " + descripcion + "[/color]")

	# Activar glow en la tarjeta visual correspondiente
	var nombre_limpio: String = nombre.replace(" (IA)", "")
	if _comodin_visuals.has(nombre_limpio):
		var cv: ComodinVisual = _comodin_visuals[nombre_limpio]
		cv.activar_efecto()

	# Mostrar popup animado
	_mostrar_popup_comodin(nombre, descripcion)


func _mostrar_popup_comodin(nombre: String, desc: String) -> void:
	comodin_popup.text = nombre + " - " + desc

	# Color segun si es del jugador o IA
	var es_ia: bool = "(IA)" in nombre
	if es_ia:
		comodin_popup.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	else:
		comodin_popup.add_theme_color_override("font_color", Color(1, 0.9, 0.3))

	# Animacion: aparece desde abajo, sube, y desaparece
	var tween: Tween = create_tween()
	comodin_popup.modulate.a = 0.0
	comodin_popup.position.y = 300.0
	tween.set_parallel(true)
	tween.tween_property(comodin_popup, "modulate:a", 1.0, 0.25)
	tween.tween_property(comodin_popup, "position:y", 270.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain()
	tween.tween_interval(1.2)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(comodin_popup, "modulate:a", 0.0, 0.5)
	tween.tween_property(comodin_popup, "position:y", 250.0, 0.5)


# ============================================================
# MOSTRAR CARTAS CON ANIMACION
# ============================================================

func _on_cartas_repartidas(cartas_j: Array, cant_ia: int) -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	_limpiar_contenedor(contenedor_cartas_ia)

	# Cartas del jugador - animacion de reparto escalonada
	for i in range(cartas_j.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(cartas_j[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)
		_animar_entrada_carta(cv, i, true)

	# Cartas de IA (ocultas) - animacion escalonada
	for i in range(cant_ia):
		var oculta: CartaVisual = CartaVisual.crear_carta_oculta()
		contenedor_cartas_ia.add_child(oculta)
		_animar_entrada_carta(oculta, i, false)

	# Limpiar mesa
	_limpiar_mesa()
	lbl_resultado.text = ""
	lbl_mano_score.text = "Manos: Vos 0 - IA 0"


func _animar_entrada_carta(carta: CartaVisual, indice: int, es_jugador: bool) -> void:
	carta.modulate.a = 0.0
	carta.scale = Vector2(0.3, 0.3)
	carta.pivot_offset = carta.custom_minimum_size / 2.0

	var delay: float = indice * 0.12
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	# Fade in
	tween.tween_property(carta, "modulate:a", 1.0, 0.3).set_delay(delay)
	# Scale up con bounce
	tween.tween_property(carta, "scale", Vector2.ONE, 0.35).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _limpiar_mesa() -> void:
	for i in range(3):
		_limpiar_contenedor(_contenedores_mano[i])
		_contenedores_mano[i].add_child(CartaVisual.crear_slot_vacio())
		_contenedores_mano[i].add_child(CartaVisual.crear_slot_vacio())
		_resultados_mano[i].text = ""


func _on_carta_clickeada(indice: int) -> void:
	# Mostrar carta del jugador en la mesa antes de enviarla al GM
	var mano_idx: int = gm.mano_actual
	if mano_idx < 3 and indice < gm.cartas_jugador.size():
		var carta: Carta = gm.cartas_jugador[indice]
		_colocar_carta_mesa(mano_idx, carta, true)

	gm.jugador_jugar_carta(indice)
	_actualizar_cartas_jugador()


func _colocar_carta_mesa(mano_idx: int, carta: Carta, es_jugador: bool) -> void:
	if mano_idx >= 3:
		return
	var cont: HBoxContainer = _contenedores_mano[mano_idx]
	# Slot 0 = jugador, Slot 1 = IA
	var slot_idx: int = 0 if es_jugador else 1
	if slot_idx < cont.get_child_count():
		var viejo: Node = cont.get_child(slot_idx)
		viejo.queue_free()
		await get_tree().process_frame
	var carta_visual: CartaVisual = CartaVisual.crear_carta_mesa(carta, es_jugador)
	cont.add_child(carta_visual)
	cont.move_child(carta_visual, slot_idx)

	# Animacion de carta llegando a la mesa
	_animar_carta_mesa(carta_visual)


func _animar_carta_mesa(carta: CartaVisual) -> void:
	carta.modulate.a = 0.0
	carta.scale = Vector2(1.3, 1.3)
	carta.pivot_offset = carta.custom_minimum_size / 2.0

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(carta, "modulate:a", 1.0, 0.2)
	tween.tween_property(carta, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _actualizar_cartas_jugador() -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	for i in range(gm.cartas_jugador.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(gm.cartas_jugador[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)


func _on_carta_ia_jugada(carta: Carta) -> void:
	# Colocar carta de IA en la mesa
	_colocar_carta_mesa(gm.mano_actual, carta, false)
	# Remover una carta oculta de la IA con animacion
	if contenedor_cartas_ia.get_child_count() > 0:
		var oculta: Node = contenedor_cartas_ia.get_child(0)
		var tween: Tween = create_tween()
		tween.tween_property(oculta, "modulate:a", 0.0, 0.15)
		tween.tween_callback(oculta.queue_free)

# ============================================================
# EVENTOS DEL JUEGO
# ============================================================

func _on_ronda_iniciada() -> void:
	comodines_mgr.nueva_ronda()
	_log("[color=cyan]--- Nueva Ronda ---[/color]")
	var mano_txt: String = "Sos mano" if gm.es_mano_jugador else "IA es mano"
	_log(mano_txt)

	# Animacion del texto de info
	lbl_info.text = mano_txt
	_animar_label_bounce(lbl_info)


func _on_mano_jugada(ganador: String, carta_j: Carta, carta_ia: Carta) -> void:
	var mano_idx: int = gm.mano_actual - 1
	if mano_idx < 0:
		mano_idx = 0

	var txt_ganador: String = "Ganaste" if ganador == "jugador" else "IA gano"
	lbl_resultado.text = txt_ganador
	lbl_mano_score.text = "Manos: Vos " + str(gm.manos_jugador) + " - IA " + str(gm.manos_ia)
	_log(carta_j.nombre_legible() + " vs " + carta_ia.nombre_legible() + " -> " + txt_ganador)

	# Animacion del resultado
	_animar_label_bounce(lbl_resultado)

	# Mostrar resultado en el slot de la mano con animacion
	if mano_idx < 3:
		if ganador == "jugador":
			_resultados_mano[mano_idx].text = "Ganaste"
			_resultados_mano[mano_idx].add_theme_color_override("font_color", Color(0.3, 1, 0.4))
		else:
			_resultados_mano[mano_idx].text = "IA gano"
			_resultados_mano[mano_idx].add_theme_color_override("font_color", Color(1, 0.4, 0.4))
		_animar_label_bounce(_resultados_mano[mano_idx])

	# Comodin: Mano Pesada
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

	# Animacion de resultado de ronda
	_animar_resultado_ronda(ganador == "jugador")

	# Comodin: Violento
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
	var txt: String = "GANASTE EL JUEGO!" if ganador == "jugador" else "PERDISTE... La IA gano"
	_log("[color=gold][b]" + txt + "[/b][/color]")
	lbl_info.text = txt
	_ocultar_todos_botones()

	# Animacion de fin de juego
	_animar_fin_juego(ganador == "jugador")


func _on_puntos_actualizados(pts_j: int, pts_ia: int) -> void:
	lbl_pts_jugador.text = "Vos: " + str(pts_j)
	lbl_pts_ia.text = "IA: " + str(pts_ia)
	# Animacion de puntos
	_animar_label_punch(lbl_pts_jugador)
	_animar_label_punch(lbl_pts_ia)


func _on_esperando_accion(acciones: Array) -> void:
	_ocultar_todos_botones()

	# Mostrar botones con animacion escalonada
	var botones_visibles: Array[Button] = []

	if "envido" in acciones:
		btn_envido.visible = true
		botones_visibles.append(btn_envido)
	if "real_envido" in acciones:
		btn_real_envido.visible = true
		botones_visibles.append(btn_real_envido)
	if "truco" in acciones:
		btn_truco.visible = true
		botones_visibles.append(btn_truco)
	if "retruco" in acciones:
		btn_retruco.visible = true
		botones_visibles.append(btn_retruco)
	if "vale4" in acciones:
		btn_vale4.visible = true
		botones_visibles.append(btn_vale4)
	if "quiero_truco" in acciones or "quiero_envido" in acciones:
		btn_quiero.visible = true
		botones_visibles.append(btn_quiero)
	if "no_quiero_truco" in acciones or "no_quiero_envido" in acciones:
		btn_no_quiero.visible = true
		botones_visibles.append(btn_no_quiero)
	if "retirarse" in acciones:
		btn_retirarse.visible = true
		botones_visibles.append(btn_retirarse)

	# Animar entrada de botones
	for i in range(botones_visibles.size()):
		_animar_boton_entrada(botones_visibles[i], i * 0.05)

	# Habilitar click en cartas solo si puede jugar
	var puede_jugar: bool = "jugar_carta" in acciones
	for child in contenedor_cartas_jugador.get_children():
		if child is CartaVisual:
			child.mouse_filter = Control.MOUSE_FILTER_STOP if puede_jugar else Control.MOUSE_FILTER_IGNORE
			child.modulate.a = 1.0 if puede_jugar else 0.5


func _on_mensaje(texto: String) -> void:
	_log(texto)


func _on_truco_cantado(quien: String, nivel: String) -> void:
	if quien == "ia":
		lbl_info.text = "IA canto " + nivel + "!"
	else:
		lbl_info.text = "Cantaste " + nivel + "!"
	_animar_truco_cantado()


# ============================================================
# ANIMACIONES
# ============================================================

## Bounce: escala sube y baja rapidamente
func _animar_label_bounce(label: Control) -> void:
	label.pivot_offset = label.size / 2.0
	label.scale = Vector2(1.3, 1.3)
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Punch: sacudon rapido para cambios de puntaje
func _animar_label_punch(label: Control) -> void:
	label.pivot_offset = label.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Boton aparece con slide desde abajo
func _animar_boton_entrada(boton: Button, delay: float = 0.0) -> void:
	boton.modulate.a = 0.0
	boton.pivot_offset = boton.size / 2.0
	boton.scale = Vector2(0.8, 0.8)
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(boton, "modulate:a", 1.0, 0.2).set_delay(delay)
	tween.tween_property(boton, "scale", Vector2.ONE, 0.25).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Truco cantado: flash en el texto de info
func _animar_truco_cantado() -> void:
	lbl_info.pivot_offset = lbl_info.size / 2.0
	var tween: Tween = create_tween()
	# Scale up grande
	tween.tween_property(lbl_info, "scale", Vector2(1.5, 1.5), 0.15)
	tween.tween_property(lbl_info, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Resultado de ronda: flash de color en el fondo
func _animar_resultado_ronda(gano_jugador: bool) -> void:
	lbl_resultado.pivot_offset = lbl_resultado.size / 2.0
	var color: Color = Color(0.3, 1, 0.4) if gano_jugador else Color(1, 0.4, 0.4)
	lbl_resultado.add_theme_color_override("font_color", color)

	var tween: Tween = create_tween()
	tween.tween_property(lbl_resultado, "scale", Vector2(1.4, 1.4), 0.2)
	tween.tween_property(lbl_resultado, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Fin de juego: animacion dramatica
func _animar_fin_juego(gano_jugador: bool) -> void:
	lbl_info.pivot_offset = lbl_info.size / 2.0
	var color: Color = Color(1, 0.85, 0.2) if gano_jugador else Color(1, 0.3, 0.3)
	lbl_info.add_theme_color_override("font_color", color)

	var tween: Tween = create_tween()
	# Empieza chiquito
	lbl_info.scale = Vector2(0.3, 0.3)
	lbl_info.modulate.a = 0.0
	tween.set_parallel(true)
	tween.tween_property(lbl_info, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(lbl_info, "modulate:a", 1.0, 0.3)
	tween.chain()
	# Pulso
	tween.tween_property(lbl_info, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_SINE)

# ============================================================
# BOTONES
# ============================================================

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
	if gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("quiero")
	elif gm.esperando_respuesta_envido:
		gm.jugador_responder_envido(true)

func _on_btn_no_quiero() -> void:
	if gm.esperando_respuesta_truco:
		gm.jugador_responder_truco("no_quiero")
	elif gm.esperando_respuesta_envido:
		gm.jugador_responder_envido(false)

func _on_btn_retirarse() -> void:
	gm.jugador_retirarse()

func _on_btn_siguiente() -> void:
	gm.siguiente_ronda()

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

func _limpiar_contenedor(cont: Container) -> void:
	for child in cont.get_children():
		child.queue_free()

func _log(texto: String) -> void:
	log_text.append_text("\n" + texto)
