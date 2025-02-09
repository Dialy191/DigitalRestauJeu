extends CharacterBody3D

@export var speed: float = 5.0  # Vitesse du personnage
@export var jump_speed: float = 10.0  # Hauteur du saut
@export var gravity: float = 9.8  # Gravité appliquée

@onready var interaction_raycast: RayCast3D = $Camera3D/RayCast3D  # Vérifie le bon chemin

var interaction_is_reset: bool = true

func _ready():
	print("✅ Personnage prêt dans la scène !")

func _physics_process(delta):
	# Appliquer la gravité
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Récupérer l'input pour le déplacement
	var input_dir = Vector3.ZERO
	
	# Détection des touches avec DEBUG
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_forward"):
		input_dir.z -= 1  # En 3D, avancer c'est négatif sur l'axe Z
	if Input.is_action_pressed("move_backwards"):
		input_dir.z += 1  # Reculer c'est positif sur l'axe Z
	if input_dir.length() > 0:
		input_dir = input_dir.normalized() * speed

	velocity.x = input_dir.x
	velocity.z = input_dir.z

	# Gestion du saut
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_speed

	# Appliquer le mouvement
	move_and_slide()
