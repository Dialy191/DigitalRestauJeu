extends Node3D

var is_cooking = false
var cooking_timer: Timer
var current_item = null

func _ready():
	cooking_timer = Timer.new()
	add_child(cooking_timer)
	cooking_timer.connect("timeout", Callable(self, "_on_cooking_done"))


func is_free() -> bool:
	return !is_cooking

func start_cooking(item):
	if is_free():
		is_cooking = true
		current_item = item
		cooking_timer.start(5)  # La cuisson dure 5 secondes par exemple
		print("Cuisson démarrée pour", item["name"])

func _on_cooking_done():
	print("Cuisson terminée pour", current_item["name"])
	is_cooking = false
	current_item = null
