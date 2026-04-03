class_name Mazo
extends RefCounted

## Maneja el mazo de cartas, barajar y repartir.

var cartas: Array[Carta] = []

func _init() -> void:
	reiniciar()

func reiniciar() -> void:
	cartas.clear()
	var datos: Array[Dictionary] = GameData.generar_mazo()
	for d: Dictionary in datos:
		cartas.append(Carta.desde_dict(d))

func barajar() -> void:
	cartas.shuffle()

func repartir(cantidad: int) -> Array[Carta]:
	var mano: Array[Carta] = []
	for i: int in range(cantidad):
		if cartas.is_empty():
			break
		var carta: Carta = cartas.pop_back() as Carta
		mano.append(carta)
	return mano
