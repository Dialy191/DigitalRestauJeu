extends Node3D

var cooking_timer: Timer  
@onready var time_label: Label = $CanvasLayer/Label 
var stove_name: String  
var remaining_time: int = 0 
@onready var http_request: HTTPRequest = $HTTPRequest
var commande_id = null 

# Variables manquantes
var cooking_time: int = 0  # Temps de cuisson total
var is_cooking_active: bool = false  # Indique si une cuisson est en cours

func _ready():
	stove_name = name  

	cooking_timer = Timer.new()
	cooking_timer.wait_time = 1 
	cooking_timer.one_shot = false 
	add_child(cooking_timer)
	
	cooking_timer.connect("timeout", Callable(self, "_update_cooking_time"))

func has_cooking_timer() -> bool:
	return !cooking_timer.is_stopped()

func is_cooking() -> bool:
	return has_cooking_timer() and cooking_timer.time_left > 0

func start_cooking(ingredient, passed_commande_id):
	if is_cooking():
		print("⏳ Un plat est déjà en cuisson ici.")
		return

	commande_id = passed_commande_id  
	print("🔥 Début de cuisson pour la commande ID :", commande_id)

	cooking_time = calculate_cooking_time(ingredient)  
	remaining_time = cooking_time  

	cooking_timer.start(1)  
	is_cooking_active = true

func calculate_cooking_time(ingredient) -> int:
	var cooking_times = {
		"steak": 10,
		"poulet": 15,
		"riz": 8
	}
	return cooking_times.get(ingredient["name"], 10)  

func _update_cooking_time():
	remaining_time -= 1 
	time_label.text = "Temps restant : " + str(remaining_time) + "s"

	print("⏳", stove_name, "- Temps restant :", remaining_time, "s")

	if remaining_time <= 0:
		_on_cooking_done()

func _on_cooking_done():
	cooking_timer.stop()  
	time_label.text = "✅ Cuisson terminée !"
	print("✅", stove_name, "- Cuisson terminée.")

	# Met à jour le statut de la commande
	if commande_id != null:
		var success = await update_commande_status(commande_id, "Terminé")
		if success:
			print("✅ Commande ID", commande_id, "mise à jour avec succès.")
			await decrement_recipe_quantity(commande_id)  # Décrémente la recette
		else:
			print("❌ Erreur lors de la mise à jour de la commande.")
	else:
		print("❌ Aucune commande en cours.")

func update_commande_status(commande_id, new_status):
	var url = "http://192.168.243.123/digitalrestau/update_statut_commande.php"
	var data = {
		"id_commande": commande_id,
		"status": new_status
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	var error = await http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("❌ Erreur mise à jour statut :", error)
		return false
	
	await http_request.request_completed
	print("✅ Statut de la commande mis à jour :", new_status)

	# Vérifier si la recette doit être supprimée
	return await check_recipe_quantity(commande_id)
	
func decrement_recipe_quantity(commande_id):
	var url = "http://192.168.243.123/digitalrestau/decrement_recipe.php"
	var data = { "id_commande": str(commande_id) }  # S'assurer que l'ID est bien une chaîne

	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	print("Données envoyées : ", json_data)  # Log de débogage pour vérifier les données envoyées

	# Envoie la requête
	var error = await http_request.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("❌ Erreur requête HTTP pour décrémenter quantité recette :", error)
		return false

	# Connecte la fonction de rappel pour traiter la réponse
	http_request.connect("request_completed", Callable(self, "_on_decrement_recipe_completed").bind(commande_id))
	return true


func check_recipe_quantity(commande_id):
	var url = "http://192.168.243.123/digitalrestau/get_recipe_quantity.php?id_commande=" + str(commande_id)
	var error = await http_request.request(url)

	if error != OK:
		print("❌ Erreur requête HTTP lors de la récupération de la quantité recette :", error)
		return false

	# Attends que la requête soit terminée et appelle la fonction callback
	await http_request.request_completed
	http_request.connect("request_completed", Callable(self, "_on_request_completed").bind(commande_id))

	return true


func _on_decrement_recipe_completed(result, response_code, _headers, body, commande_id):
	if response_code != 200:
		print("❌ Erreur HTTP lors de la mise à jour de la quantité recette pour la commande ID :", commande_id)
		return false

	# Affiche la réponse brute pour vérifier le contenu
	var response_body = body.get_string_from_utf8()
	print("Réponse brute du serveur :", response_body)

	var json_instance = JSON.new()
	var parse_result = json_instance.parse(response_body)

	if parse_result != OK:
		print("❌ Erreur analyse JSON pour décrémenter la quantité recette.")
		return false

	var data = json_instance.get_data()
	print("Réponse JSON analysée :", data)

	print("✅ Quantité recette décrémentée pour la commande ID :", commande_id)
	return true
