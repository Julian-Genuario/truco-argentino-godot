extends Node

## Autoload global con datos del mazo español y jerarquía del truco.

# --- Palos ---
enum Palo { ESPADA, BASTO, ORO, COPA }

const PALO_NOMBRE: Dictionary = {
	Palo.ESPADA: "espada",
	Palo.BASTO: "basto",
	Palo.ORO: "oro",
	Palo.COPA: "copa",
}

# --- Jerarquía de truco (mayor = mejor) ---
const JERARQUIA: Dictionary = {
	# Ancho de espadas
	"1_espada": 15,
	# Ancho de bastos
	"1_basto": 14,
	# 7 de espadas
	"7_espada": 13,
	# 7 de oros
	"7_oro": 12,
	# Tres
	"3_espada": 11, "3_basto": 11, "3_oro": 11, "3_copa": 11,
	# Dos
	"2_espada": 10, "2_basto": 10, "2_oro": 10, "2_copa": 10,
	# Anchos falsos (oro y copa)
	"1_oro": 9, "1_copa": 9,
	# Doce
	"12_espada": 8, "12_basto": 8, "12_oro": 8, "12_copa": 8,
	# Once
	"11_espada": 7, "11_basto": 7, "11_oro": 7, "11_copa": 7,
	# Diez
	"10_espada": 6, "10_basto": 6, "10_oro": 6, "10_copa": 6,
	# Siete falsos (copa y basto)
	"7_copa": 5, "7_basto": 5,
	# Seis
	"6_espada": 4, "6_basto": 4, "6_oro": 4, "6_copa": 4,
	# Cinco
	"5_espada": 3, "5_basto": 3, "5_oro": 3, "5_copa": 3,
	# Cuatro
	"4_espada": 2, "4_basto": 2, "4_oro": 2, "4_copa": 2,
}

# --- Valor de envido por carta ---
# 10, 11, 12 valen 0. El resto vale su número.
func envido_valor(numero: int) -> int:
	if numero >= 10:
		return 0
	return numero

# --- Calcular envido de una mano de 3 cartas ---
func calcular_envido(cartas: Array[Carta]) -> int:
	var mejor: int = 0

	for i: int in range(cartas.size()):
		for j: int in range(i + 1, cartas.size()):
			if cartas[i].palo == cartas[j].palo:
				var val: int = 20 + envido_valor(cartas[i].numero) + envido_valor(cartas[j].numero)
				mejor = max(mejor, val)

	if mejor == 0:
		for c: Carta in cartas:
			mejor = max(mejor, envido_valor(c.numero))

	return mejor

# --- Generar mazo completo (40 cartas, sin 8 ni 9) ---
func generar_mazo() -> Array[Dictionary]:
	var mazo: Array[Dictionary] = []
	var numeros: Array[int] = [1, 2, 3, 4, 5, 6, 7, 10, 11, 12]
	for palo: int in [Palo.ESPADA, Palo.BASTO, Palo.ORO, Palo.COPA]:
		for num: int in numeros:
			mazo.append({
				"numero": num,
				"palo": palo,
				"id": str(num) + "_" + PALO_NOMBRE[palo],
			})
	return mazo

func obtener_jerarquia(carta: Dictionary) -> int:
	return JERARQUIA.get(carta.id, 0)

# --- Puntos base del truco ---
const PUNTOS_TRUCO: Dictionary = {
	"nada": 1,
	"truco": 2,
	"retruco": 3,
	"vale4": 4,
}

# --- Puntos del envido ---
const PUNTOS_ENVIDO: Dictionary = {
	"envido": 2,
	"real_envido": 3,
}

const PUNTOS_OBJETIVO: int = 30
