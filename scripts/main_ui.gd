extends Control

## Script principal de UI. Conecta el GameManager con la interfaz visual.

@onready var gm: Node = $GameManager
@onready var lbl_pts_jugador: Label = $VBox/TopBar/TopBarContent/PuntajeJugador
@onready var lbl_pts_ia: Label = $VBox/TopBar/TopBarContent/PuntajeIA
@onready var lbl_info: Label = $VBox/TopBar/TopBarContent/InfoRonda
@onready var contenedor_cartas_ia: HBoxContainer = $VBox/ZonaIA/CartasIA
@onready var contenedor_cartas_jugador: HBoxContainer = $VBox/ZonaJugador/CartasJugador
@onready var lbl_resultado: Label = $VBox/ZonaMesa/ResultadoMano
@onready var lbl_mano_score: Label = $VBox/ZonaMesa/ManoScore
@onready var log_text: RichTextLabel = $VBox/Log
@onready var lbl_comodines: Label = $VBox/ComodinesPanel/LabelComodines

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

func _ready() -> void:
	# Crear sistema de comodines
	comodines_mgr = ComodinesManager.new()
	add_child(comodines_mgr)
	comodines_mgr.asignar_comodines_aleatorios(3)
	comodines_mgr.comodin_activado.connect(_on_comodin_activado)

	_contenedores_mano = [cartas_m1, cartas_m2, cartas_m3]
	_resultados_mano = [result_m1, result_m2, result_m3]

	# Conectar señales del GameManager
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

	# Iniciar juego
	gm.comodines_jugador = comodines_mgr.comodines_jugador
	gm.comodines_ia = comodines_mgr.comodines_ia
	gm.iniciar_juego()

# ============================================================
# MOSTRAR CARTAS
# ============================================================

func _on_cartas_repartidas(cartas_j: Array, cant_ia: int) -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	_limpiar_contenedor(contenedor_cartas_ia)

	# Cartas del jugador como sprites visuales
	for i in range(cartas_j.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(cartas_j[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)

	# Cartas de IA (ocultas)
	for i in range(cant_ia):
		var oculta: CartaVisual = CartaVisual.crear_carta_oculta()
		contenedor_cartas_ia.add_child(oculta)

	# Limpiar mesa - poner slots vacios en las 3 manos
	_limpiar_mesa()
	lbl_resultado.text = ""
	lbl_mano_score.text = "Manos: Vos 0 - IA 0"

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

func _actualizar_cartas_jugador() -> void:
	_limpiar_contenedor(contenedor_cartas_jugador)
	for i in range(gm.cartas_jugador.size()):
		var cv: CartaVisual = CartaVisual.crear_carta_jugador(gm.cartas_jugador[i], i)
		cv.carta_clickeada.connect(_on_carta_clickeada)
		contenedor_cartas_jugador.add_child(cv)

func _on_carta_ia_jugada(carta: Carta) -> void:
	# Colocar carta de IA en la mesa
	_colocar_carta_mesa(gm.mano_actual, carta, false)
	# Remover una carta oculta de la IA
	if contenedor_cartas_ia.get_child_count() > 0:
		contenedor_cartas_ia.get_child(0).queue_free()

# ============================================================
# EVENTOS DEL JUEGO
# ============================================================

func _on_ronda_iniciada() -> void:
	comodines_mgr.nueva_ronda()
	_log("[color=cyan]--- Nueva Ronda ---[/color]")
	var mano_txt: String = "Sos mano" if gm.es_mano_jugador else "IA es mano"
	_log(mano_txt)
	lbl_info.text = mano_txt

func _on_mano_jugada(ganador: String, carta_j: Carta, carta_ia: Carta) -> void:
	var mano_idx: int = gm.mano_actual - 1  # mano_actual ya incremento
	if mano_idx < 0:
		mano_idx = 0

	var txt_ganador: String = "Ganaste" if ganador == "jugador" else "IA gano"
	lbl_resultado.text = txt_ganador
	lbl_mano_score.text = "Manos: Vos " + str(gm.manos_jugador) + " - IA " + str(gm.manos_ia)
	_log(carta_j.nombre_legible() + " vs " + carta_ia.nombre_legible() + " -> " + txt_ganador)

	# Mostrar resultado en el slot de la mano
	if mano_idx < 3:
		if ganador == "jugador":
			_resultados_mano[mano_idx].text = "Ganaste"
			_resultados_mano[mano_idx].add_theme_color_override("font_color", Color(0.3, 1, 0.4))
		else:
			_resultados_mano[mano_idx].text = "IA gano"
			_resultados_mano[mano_idx].add_theme_color_override("font_color", Color(1, 0.4, 0.4))

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

func _on_juego_terminado(ganador: String) -> void:
	var txt: String = "GANASTE EL JUEGO!" if ganador == "jugador" else "PERDISTE... La IA gano"
	_log("[color=gold][b]" + txt + "[/b][/color]")
	lbl_info.text = txt
	_ocultar_todos_botones()

func _on_puntos_actualizados(pts_j: int, pts_ia: int) -> void:
	lbl_pts_jugador.text = "Vos: " + str(pts_j)
	lbl_pts_ia.text = "IA: " + str(pts_ia)

func _on_esperando_accion(acciones: Array) -> void:
	_ocultar_todos_botones()

	btn_envido.visible = "envido" in acciones
	btn_real_envido.visible = "real_envido" in acciones
	btn_truco.visible = "truco" in acciones
	btn_retruco.visible = "retruco" in acciones
	btn_vale4.visible = "vale4" in acciones
	btn_quiero.visible = "quiero_truco" in acciones or "quiero_envido" in acciones
	btn_no_quiero.visible = "no_quiero_truco" in acciones or "no_quiero_envido" in acciones
	btn_retirarse.visible = "retirarse" in acciones

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

func _on_comodin_activado(nombre: String, descripcion: String) -> void:
	_log("[color=magenta]* " + nombre + ": " + descripcion + "[/color]")

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

func _mostrar_comodines() -> void:
	var info: Array = comodines_mgr.obtener_comodines_jugador()
	var txt: String = "Comodines: "
	for i in range(info.size()):
		if i > 0:
			txt += " | "
		txt += info[i].get("nombre", "?") + " (" + info[i].get("descripcion", "") + ")"
	lbl_comodines.text = txt
