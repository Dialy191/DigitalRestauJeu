extends Node3D

var cooking_timer: Timer  # Timer pour la cuisson
var time_label: Label  # Label pour afficher le temps restant
var stove_name: String  # Nom du stove

func _ready():
	# Récupérer le nom du stove
	stove_name = name  # Le nom du node Stove

	# Créer le timer de cuisson
	cooking_timer = Timer.new()
	cooking_timer.wait_time = 1  # Mise à jour chaque seconde
	cooking_timer.one_shot = false  # Continue jusqu'à la fin du temps de cuisson
	add_child(cooking_timer)

	# Créer le label d'affichage du temps de cuisson
	time_label = Label.new()
	time_label.text = "Temps restant : 0s"
	time_label.set_position(Vector2(10, -20))  # Position relative au stove
	add_child(time_label)
	
	cooking_timer.connect("timeout", Callable(self, "_update_cooking_time"))

# Vérifie si le stove a un timer de cuisson actif
func has_cooking_timer() -> bool:
	return !cooking_timer.is_stopped()

# Vérifie si la cuisson est en cours
func is_cooking() -> bool:
	return has_cooking_timer() and cooking_timer.time_left > 0

func start_cooking(item):
	var cook_time = 5  # Temps de cuisson en secondes
	cooking_timer.start(cook_time)  # Démarrer le timer
	time_label.text = "Temps restant : " + str(cook_time) + "s"
	print("🔥 Cuisson commencée sur", stove_name, "pour :", item["name"])

func _update_cooking_time():
	var time_left = int(cooking_timer.time_left)
	time_label.text = "Temps restant : " + str(time_left) + "s"

	# Afficher le temps restant avec le nom du stove
	print("⏳", stove_name, "- Temps restant :", time_left, "s")

	if time_left <= 0:
		_on_cooking_done()

func _on_cooking_done():
	cooking_timer.stop()
	time_label.text = "✅ Cuisson terminée !"
	print("✅", stove_name, "- Cuisson terminée.")
