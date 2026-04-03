extends Control

## Menu principal del juego "Quiero Vale 4".

@onready var btn_empezar: Button = $VBox/Botones/BtnEmpezar
@onready var btn_salir: Button = $VBox/Botones/BtnSalir

func _ready() -> void:
	btn_empezar.pressed.connect(_on_empezar)
	btn_salir.pressed.connect(_on_salir)

	# Foco inicial en empezar
	btn_empezar.grab_focus()


func _on_empezar() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_salir() -> void:
	get_tree().quit()
