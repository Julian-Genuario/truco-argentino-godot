extends Control

## Menu principal - configuracion de partida y arranque.

@onready var btn_empezar: Button = $VBox/Botones/BtnEmpezar
@onready var btn_salir: Button = $VBox/Botones/BtnSalir
@onready var btn_15: Button = $VBox/Opciones/PuntosBox/Btn15
@onready var btn_30: Button = $VBox/Opciones/PuntosBox/Btn30
@onready var btn_sin_flor: Button = $VBox/Opciones/FlorBox/BtnSinFlor
@onready var btn_con_flor: Button = $VBox/Opciones/FlorBox/BtnConFlor

var _puntos: int = 30
var _con_flor: bool = false

func _ready() -> void:
	btn_empezar.pressed.connect(_on_empezar)
	btn_salir.pressed.connect(_on_salir)

	btn_15.pressed.connect(func():
		_puntos = 15
		btn_15.button_pressed = true
		btn_30.button_pressed = false
	)
	btn_30.pressed.connect(func():
		_puntos = 30
		btn_30.button_pressed = true
		btn_15.button_pressed = false
	)
	btn_sin_flor.pressed.connect(func():
		_con_flor = false
		btn_sin_flor.button_pressed = true
		btn_con_flor.button_pressed = false
	)
	btn_con_flor.pressed.connect(func():
		_con_flor = true
		btn_con_flor.button_pressed = true
		btn_sin_flor.button_pressed = false
	)

	btn_empezar.grab_focus()

func _on_empezar() -> void:
	GameData.puntos_objetivo = _puntos
	GameData.con_flor = _con_flor
	GameData.reset_partida()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_salir() -> void:
	get_tree().quit()
