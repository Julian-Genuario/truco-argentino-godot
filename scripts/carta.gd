class_name Carta
extends Resource

## Recurso que representa una carta del mazo español.

@export var numero: int
@export var palo: int  # GameData.Palo
@export var id: String

func _init(p_numero: int = 0, p_palo: int = 0, p_id: String = "") -> void:
	numero = p_numero
	palo = p_palo
	id = p_id

static func desde_dict(d: Dictionary) -> Carta:
	return Carta.new(d.numero, d.palo, d.id)

func obtener_jerarquia() -> int:
	return GameData.JERARQUIA.get(id, 0)

func obtener_envido() -> int:
	return GameData.envido_valor(numero)

func nombre_legible() -> String:
	var palo_str: String = GameData.PALO_NOMBRE.get(palo, "?")
	return str(numero) + " de " + palo_str

func _to_string() -> String:
	return nombre_legible()
