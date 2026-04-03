class_name Mazo
extends RefCounted

## Maneja el mazo de cartas, barajar y repartir.

var cartas: Array[Carta] = []

func _init() -> void:
	reiniciar()

func reiniciar() -> void:
	cartas.clear()
	var datos := GameData.generar_mazo()
	for d in datos:
		cartas.append(Carta.desde_dict(d))

func barajar() -> void:
	cartas.shuffle()

func repartir(cantidad: int) -> Array[Carta]:
	var mano: Array[Carta] = []
	for i in range(cantidad):
		if cartas.is_empty():
			break
		mano.append(cartas.pop_back())
	return mano
