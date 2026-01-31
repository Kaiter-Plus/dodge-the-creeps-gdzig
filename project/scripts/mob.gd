extends RigidBody2D

@onready var animated_sprite = $AnimatedSprite2D

func _ready():
	var mob_type = animated_sprite.sprite_frames.get_animation_names()
	animated_sprite.play(mob_type[randi() % mob_type.size()])


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
