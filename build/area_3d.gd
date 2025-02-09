extends Area3D

@onready var collision_label: Label = $CanvasLayer/Label
signal cook_button_pressed(item)
var fridge_items = []  
var fridge_ui: Control
var grid_container: GridContainer
var close_button: Button
var stove_slots = [] 
var selected_items = [] 
var required_ingredients = []
var menu_items = []
var menu_ui: Control
var menu_grid_container: GridContainer
var menu_close_button: Button
var selected_ingredients = []
@onready var http_request: HTTPRequest = $HTTPRequest
func _ready():
	create_fridge_ui()
	create_menu_ui()
	send_http_request()
	await get_tree().create_timer(0.0).timeout 
	search_stoves()
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	fridge_ui.visible = false
func _on_body_entered(body):
	print("🚀 Collision with :", body.name)
	if body.name == "fridge":
		collision_label.text = "Collision détectée avec fridge !"
		show_fridge_ui()  
	elif body.name == "kitchentable":
		collision_label.text = "Collision détectée avec kitchentable !"
	
	elif body.name == "kitchencounter":
		collision_label.text = "Collision détectée avec kitchencounter !"
	
	elif body.name == "stove":
		collision_label.text = "Collision détectée avec stove !"
		
	elif body.name == "menu2":
		collision_label.text = "Collision détectée avec menu !"
		show_menu_ui()
func _on_body_exited(body):
	if body.name == "fridge":
		collision_label.text = "Aucune collision"
		hide_fridge_ui() 
	elif body.name == "menu":
		collision_label.text = "Aucune collision"
		hide_menu_ui()
func send_http_request():
	var url = "http://192.168.243.123/digitalrestau/get_ingredient.php"
	var error = http_request.request(url)
	if error != OK:
		print("Erreur lors de l'envoi de la requête HTTP : ", error)
	else:
		print("Requête HTTP envoyée avec succès.")
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
func to_superscript(number: String) -> String:
	var superscript_map = {
		"0": "\u2070", "1": "\u00B9", "2": "\u00B2", "3": "\u00B3",
		"4": "\u2074", "5": "\u2075", "6": "\u2076", "7": "\u2077",
		"8": "\u2078", "9": "\u2079"
	}
	var result = ""
	for char in number:
		result += superscript_map.get(char, char) 
	return result
func _on_request_completed(result, response_code, _headers, body):
	if response_code == 200:
		print("Réponse reçue avec succès!")
		var response_body = body.get_string_from_utf8()
		print("Corps brut de la réponse: ", response_body)
		if response_body.is_empty():
			print("Erreur : Le corps de la réponse est vide !")
			return
		var json_instance = JSON.new()
		var json_response = json_instance.parse(response_body)
		if json_response == OK:
			print("JSON analysé avec succès")
			var data = json_instance.get_data()
			print("Données JSON : ", data)
			if typeof(data) != TYPE_ARRAY:
				print("Erreur : Les données reçues ne sont pas une liste. Format incorrect.")
				return
			fridge_items = []
			for ingredient in data:
				if typeof(ingredient) != TYPE_DICTIONARY:
					print("Erreur : L'élément reçu n'est pas un dictionnaire.")
					continue  
				if not ingredient.has("nom") or not ingredient.has("quantite_stock") or not ingredient.has("quantite"):
					print("Erreur : Clés manquantes dans l'ingrédient : ", ingredient)
					continue
				var color_rect = ColorRect.new()
				color_rect.color = Color(1, 1, 1, 0.3)  # Par exemple, une couleur blanche semi-transparente
				color_rect.size = Vector2(100, 100)  # Taille de l'entourage
				var nom_sans_exposant = ingredient["nom"]
				var quantite_stock = int(ingredient["quantite_stock"])  # Assurez-vous que c'est un entier
				var quantity_superscript = to_superscript(str(quantite_stock))  # Ajouter l'exposant pour l'affichage
				var item = {
					"name": nom_sans_exposant + quantity_superscript,  # Nom avec exposant
					"quantite_stock": quantite_stock, 
					"nom_sans_exposant": nom_sans_exposant, 
					"image": load("res://assets/images/" + nom_sans_exposant + ".png"),
					"node": color_rect  # Référence au ColorRect pour cet ingrédient
				}
				fridge_items.append(item)
			populate_fridge()
		else:
			print("Erreur lors de l'analyse JSON: ", json_response, " - Corps: ", response_body)
	else:
		print("Erreur HTTP lors de la récupération des ingrédients. Code : ", response_code)
func search_stoves():
	var stove_parent = get_node_or_null("/root/Principal/assets/stove") 
	
	if is_instance_valid(stove_parent):
		print("Parent des stoves trouvé:", stove_parent)

		for child in stove_parent.get_children():
			if child.name.begins_with("stove"):
				stove_slots.append(child)
				print("Stove trouvé:", child)
		print("🛠️ Stoves détectés après recherche :", stove_slots)
	else:
		print("Erreur : Le parent des stoves (stove) n'existe pas ou n'est pas encore chargé.")
func create_fridge_ui():
	fridge_ui = Control.new()
	fridge_ui.size = Vector2(300, 400)
	fridge_ui.anchor_left = 0.5
	fridge_ui.anchor_top = 0.5
	fridge_ui.offset_left = -150
	fridge_ui.offset_top = -200
	var scroll_container = ScrollContainer.new()
	scroll_container.size = Vector2(280, 300)
	fridge_ui.add_child(scroll_container)
	grid_container = GridContainer.new()
	grid_container.columns = 2  
	scroll_container.add_child(grid_container) 
	var hbox = HBoxContainer.new()
	fridge_ui.add_child(hbox)
	var close_button = Button.new()
	close_button.text = "Fermer"
	close_button.custom_minimum_size = Vector2(140, 50)
	close_button.connect("pressed", Callable(self, "_on_close_button_pressed"))
	hbox.add_child(close_button)
	var global_cook_button = Button.new()
	global_cook_button.text = "Cuire"
	global_cook_button.custom_minimum_size = Vector2(140, 50)
	global_cook_button.connect("pressed", Callable(self, "_on_global_cook_button_pressed"))
	hbox.add_child(global_cook_button)
	$CanvasLayer.add_child(fridge_ui)
func populate_fridge():
	for child in grid_container.get_children():
		child.queue_free()
	for item in fridge_items:
		var item_container = VBoxContainer.new()
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var background_panel = ColorRect.new()
		background_panel.size = Vector2(70, 70)  
		background_panel.color = Color(0.8, 0.8, 0.8) 
		var texture_rect = TextureRect.new()
		texture_rect.texture = item["image"]
		texture_rect.custom_minimum_size = Vector2(30, 30)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var name_label = Label.new()
		name_label.text = item["name"]  
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  
		var quantity_spinbox = SpinBox.new()
		quantity_spinbox.min_value = 1
		quantity_spinbox.max_value = int(item["quantite_stock"]) 
		quantity_spinbox.value = max(1, quantity_spinbox.value) 
		quantity_spinbox.step = 1 
		var select_button = Button.new()
		select_button.text = "Sélectionner"
		select_button.connect("pressed", Callable(self, "_on_select_button_pressed").bind(item, quantity_spinbox))  # Sélectionner l'aliment
		item_container.add_child(background_panel)  # Ajoute le fond
		item_container.add_child(texture_rect)  # Ajoute l'image
		item_container.add_child(name_label)  # Ajoute le texte sous l'image
		item_container.add_child(quantity_spinbox)  # Ajoute le SpinBox pour la quantité
		item_container.add_child(select_button)  # Ajoute le bouton de sélection
		
		grid_container.add_child(item_container)
func _on_select_button_pressed(item, quantity_spinbox):
	var selected_item = {
		"name": item["name"],
		"quantity": quantity_spinbox.value
	}
	if selected_items.has(selected_item):
		selected_items.erase(selected_item)
		print("Désélectionné : ", item["name"])
	else:
		selected_items.append(selected_item)
		print("Sélectionné : ", item["name"])
func _on_item_selected(item, quantity_spinbox):
	var selected_item = {
		"name": item["name"],
		"quantity": quantity_spinbox.value
	}
	selected_items.append(selected_item)
	
	
func _on_global_cook_button_pressed():
	if selected_items.size() == 0:
		print("Erreur : Aucun ingrédient sélectionné.")
		return

	# Vérification des quantités avant de lancer la cuisson
	if !check_ingredient_quantities(selected_items, required_ingredients):
		print("Erreur : Quantités insuffisantes pour la recette.")
		return

	var stove_found = false
	for stove in stove_slots:
		if stove == null:
			print("Erreur: Stove invalide ou manquant.")
		elif stove.has_cooking_timer() and stove.is_cooking():
			print("Erreur: Stove occupé avec un plat en cuisson.")
		else:
			stove_found = true
			for selected_item in selected_items:
				var item = null
				var commande_id = null  # Ajout de la variable pour stocker l'ID de la commande

				# Trouver l'ingrédient dans le frigo
				for fridge_item in fridge_items:
					if fridge_item["name"] == selected_item["name"]:
						item = fridge_item
						break  # On arrête la boucle dès qu'on trouve l'élément
				
				if item == null:
					print("❌ Ingrédient NON TROUVÉ dans le frigo:", selected_item["name"])

				# Trouver la recette associée à l'ingrédient
				var recette_id = null
				for menu_item in menu_items:
					commande_id = menu_item["Commande_id"]  # Récupérer l'ID de la commande
					break  # Dès qu'on trouve, on sort

				if recette_id == null or commande_id == null:
					print("❌ Erreur : Impossible de trouver la recette ou l'ID de commande pour :", selected_item["name"])


				if commande_id == null:
					print("❌ ID COMMANDE NON TROUVÉ pour:", selected_item["name"])

				if item != null and commande_id != null:
					print("🔥 Début de cuisson pour", item["name"], "avec commande ID :", commande_id)
					stove.start_cooking(item, commande_id)  # On passe bien l'ID

					var success = await update_quantity_in_database(item, selected_item["quantity"])
					if success:
						print("✅ Quantité mise à jour pour", item["name"], "(", selected_item["quantity"], ")")
					else:
						print("❌ Erreur lors de la mise à jour de la quantité pour", item["name"])
				else:
					print("❌ Erreur : Ingrédient ou ID commande non trouvé pour", selected_item["name"])


		selected_items.clear()  
		break  # Sortir dès qu'on a trouvé une stove dispo

	if not stove_found:
		print("❌ Erreur : Aucune stove disponible pour la cuisson.")


func update_quantity_in_database(item, quantity_used):
	var url = "http://192.168.243.123/digitalrestau/update_ingredient.php"
	var item_name = item["nom_sans_exposant"]
	var data = {
		"nom": item_name,
		"quantity_used": quantity_used 
	}
	
	var json_data = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]

	var error = await http_request.request(url, headers, HTTPClient.METHOD_POST, json_data) 
	if error != OK:
		print("Erreur lors de l'envoi de la mise à jour HTTP : ", error)
		return false
	
	await http_request.request_completed
	return true


func hide_fridge_ui():
	fridge_ui.visible = false  

func show_fridge_ui():
	fridge_ui.visible = true  

func _on_close_button_pressed():
	print("Frigo fermé !")
	hide_fridge_ui() 

func create_menu_ui():
	menu_ui = Control.new()
	menu_ui.size = Vector2(300, 400)
	menu_ui.anchor_left = 0.5
	menu_ui.anchor_top = 0.5
	menu_ui.offset_left = -150
	menu_ui.offset_top = -200

	var scroll_container = ScrollContainer.new()
	scroll_container.size = Vector2(280, 300)
	menu_ui.add_child(scroll_container)

	menu_grid_container = GridContainer.new()
	menu_grid_container.columns = 1  # 1 commande par ligne
	scroll_container.add_child(menu_grid_container)

	menu_close_button = Button.new()
	menu_close_button.text = "Fermer"
	menu_close_button.size = Vector2(280, 50)
	menu_close_button.connect("pressed", Callable(self, "_on_menu_close_button_pressed"))
	menu_ui.add_child(menu_close_button)

	$CanvasLayer.add_child(menu_ui) 
func send_menu_http_request():
	var url = "http://192.168.243.123/digitalrestau/get_commande.php"
	var error = http_request.request(url)
	
	if error != OK:
		print("❌ Erreur lors de l'envoi de la requête HTTP : ", error)
	else:
		print("✅ Requête HTTP pour les commandes envoyée avec succès.")

	http_request.connect("request_completed", Callable(self, "_on_menu_request_completed"))
	
func _on_menu_request_completed(result, response_code, _headers, body):
	if response_code == 200:
		print("✅ Réponse reçue avec succès !")

		var response_body = body.get_string_from_utf8()
		print("📜 Corps brut de la réponse : ", response_body)

		if response_body.is_empty():
			print("❌ Erreur : Le corps de la réponse est vide !")
			return

		var json_instance = JSON.new()
		var json_response = json_instance.parse(response_body)

		if json_response == OK:
			var data = json_instance.get_data()
			print("📦 Données JSON : ", data)

			if typeof(data) != TYPE_ARRAY:
				print("❌ Erreur : Les données reçues ne sont pas une liste.")
				return

			menu_items = []
			for order in data:
				if typeof(order) != TYPE_DICTIONARY:
					print("❌ Erreur : L'élément reçu n'est pas un dictionnaire.")
					continue  
				if not order.has("commande_id"):
					print("⚠️ Avertissement : Clé 'idCommande' manquante dans :", order)
					continue  # On ignore cet élément s'il manque la clé
				if not order.has("quantite") or not order.has("nom") or not order.has("recette_id"):
					print("❌ Erreur : Champs manquants dans l'ordre : ", order)
					continue

				var item = {
					"name_recette": order["nom"],
					"quantity": int(order["quantite"]), 
					"Commande_id": order.get("commande_id"), 
					"recette_id": order["recette_id"] 
				}
				menu_items.append(item)

			populate_menu()  
		else:
			print("❌ Erreur lors de l'analyse JSON : ", json_response)
	else:
		print("❌ Erreur HTTP lors de la récupération des commandes. Code : ", response_code)
		
func populate_menu():
	for child in menu_grid_container.get_children():
		child.queue_free()  # On supprime les anciens éléments de l'interface

	for item in menu_items:
		var item_container = VBoxContainer.new()
		item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		item_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		var background_panel = ColorRect.new()
		background_panel.size = Vector2(70, 70)  # Taille du fond
		background_panel.color = Color(0.8, 0.8, 0.8)  # Couleur de fond
		
		var texture_rect = TextureRect.new()
		texture_rect.texture = load("res://assets/images/" + item["name_recette"] + ".png")  # Charge l'image de la commande
		texture_rect.custom_minimum_size = Vector2(30, 30)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var name_label = Label.new()
		name_label.text =  item["name_recette"] +  to_superscript(str(item["quantity"]))
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER  # Centrer le texte

		var prepare_button = Button.new()
		prepare_button.text = "Préparer"
		prepare_button.connect("pressed", Callable(self, "_on_prepare_button_pressed").bind(item))  # Lier l'item de la commande
		
		item_container.add_child(background_panel)
		item_container.add_child(texture_rect)  
		item_container.add_child(name_label)  
		item_container.add_child(prepare_button)  
		
		menu_grid_container.add_child(item_container)
func _on_prepare_button_pressed(item):
	print("Préparation de la commande : ", item["name_recette"])
	send_ingredients_http_request(item["recette_id"])  # Passe le nom de la commande
	hide_menu_ui()  # Cacher le menu avant de montrer le frigo
	show_fridge_ui()  # Afficher le frigo

	var all_valid = true
	for selected_item in selected_items:
		var found = false
		for required_ingredient in required_ingredients:
			if typeof(required_ingredient) == TYPE_DICTIONARY and selected_item.has("name") and selected_item.has("quantity"):
				if selected_item["name"].begins_with(required_ingredient["nom"]):
					found = true
					if selected_item["quantity"] < required_ingredient["quantite"]:
						print("Erreur : Quantité insuffisante pour ", selected_item["name"])
						all_valid = false
						break
			else:
				print("Erreur : L'élément requis n'est pas un dictionnaire ou manque des clés.")
		if not found:
			print("Erreur : Ingrédient non requis ", selected_item["name"])
			all_valid = false
	
	if all_valid:
		print("Tous les ingrédients sont suffisants pour préparer la commande.")
	else:
		print("Erreur : Certains ingrédients ne sont pas suffisants.")
func send_ingredients_http_request(recette_id):
	var url = "http://192.168.243.123/digitalrestau/get_recipe_ingredients.php?recette_id=" + str(recette_id)
	var error = http_request.request(url)

	if error != OK:
		print("Erreur lors de l'envoi de la requête HTTP : ", error)
	else:
		print("Requête HTTP envoyée avec succès pour les ingrédients.")
	http_request.connect("request_completed", Callable(self, "_on_ingredients_request_completed"))
func _on_ingredients_request_completed(result, response_code, _headers, body):
	if response_code == 200:
		var response_body = body.get_string_from_utf8()
		var json_instance = JSON.new()
		var json_response = json_instance.parse(response_body)

		if json_response == OK:
			var data = json_instance.get_data()
			required_ingredients = data
			highlight_required_ingredients(required_ingredients)  # Surligner les ingrédients nécessaires dans le frigo
		else:
			print("Erreur lors de l'analyse JSON des ingrédients.")
	else:
		print("Erreur HTTP lors de la récupération des ingrédients nécessaires.")
func highlight_required_ingredients(ingredients):
	for ingredient in ingredients:
		if typeof(ingredient) != TYPE_DICTIONARY or not ingredient.has("nom"):
			print("❌ Erreur : Ingredient mal formé ->", ingredient)
			continue  # Ignore cet élément et passe au suivant

		for fridge_item in fridge_items:
			if typeof(fridge_item) != TYPE_DICTIONARY or not fridge_item.has("nom_sans_exposant"):
				print("❌ Erreur : Fridge item mal formé ->", fridge_item)
				continue  # Ignore cet élément
			if fridge_item["nom_sans_exposant"] == ingredient["nom"]:
				print("🔎 Correspondance trouvée :", fridge_item["nom_sans_exposant"], "==", ingredient["nom"])

				if fridge_item.has("node"):
					fridge_item["node"].modulate = Color(1, 0, 0)  # Entoure l'ingrédient en rouge

				if fridge_item["quantite_stock"] < ingredient["quantite"]:
					print("⚠️ Quantité insuffisante pour", fridge_item["nom_sans_exposant"])
				else:
					print("✅ Ingrédient suffisant pour", fridge_item["nom_sans_exposant"])

func validate_ingredient_selection(selected_ingredient):
	var is_valid = false
	for ingredient in required_ingredients:
		if selected_ingredient["nom"] == ingredient["nom"]:
			is_valid = true
			if selected_ingredient["quantite"] >= ingredient["quantite"]:
				print("Ingrédient sélectionné correctement")
			else:
				print("Quantité insuffisante pour ", selected_ingredient["nom"])
				is_valid = false
			break
	
	if !is_valid:
		print("Ingrédient invalide ou quantité insuffisante.")
	return is_valid
	
func check_ingredient_quantities(selected_items, required_ingredients):
	var all_valid = true
	for selected_item in selected_items:
		var found = false
		for required_ingredient in required_ingredients:
			if selected_item["name"].begins_with(required_ingredient["nom"]):
				found = true
				if selected_item["quantity"] < required_ingredient["quantite"]:
					print("Erreur : Quantité insuffisante pour ", selected_item["name"])
					all_valid = false
					break
		if not found:
			print("Erreur : Ingrédient non requis ", selected_item["name"])
			all_valid = false
	
	return all_valid

func _on_fridge_ingredient_selected(ingredient):
	if validate_ingredient_selection(ingredient):
		print("Ingrédient sélectionné: ", ingredient["nom"])
		selected_ingredients.append(ingredient)
	else:
		print("Sélection invalide d'ingrédient.")

func show_menu_ui():
	menu_ui.visible = true  
	send_menu_http_request() 

func hide_menu_ui():
	menu_ui.visible = false  

func _on_menu_close_button_pressed():
	print("Menu fermé !")
	hide_menu_ui()
