extends Node3D

@export var ui_label: Label  

func _on_body_entered(body):
	if body.is_in_group("player"):
		ui_label.text = "Appuie sur [E] pour interagir"
		ui_label.visible = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		ui_label.visible = false
