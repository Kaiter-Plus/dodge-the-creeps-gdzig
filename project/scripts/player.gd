extends Area2D

signal hit

@export var speed = 400
var screen_size

@onready var player_sprite = $AnimatedSprite2D
@onready var player_collision = $CollisionShape2D



func _ready():
	screen_size = get_viewport_rect().size
	hide()
	
func _process(delta):
	var velocity = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		velocity += Vector2.RIGHT
	if Input.is_action_pressed("move_left"):
		velocity += Vector2.LEFT
	if Input.is_action_pressed("move_down"):
		velocity += Vector2.DOWN
	if Input.is_action_pressed("move_up"):
		velocity += Vector2.UP
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
		if velocity.x != 0:
			player_sprite.animation = "walk"
			player_sprite.flip_v = false
			player_sprite.flip_h = velocity.x < 0
		elif velocity.y != 0:
			player_sprite.animation = "up"
			player_sprite.flip_h = false
			player_sprite.flip_v = velocity.y > 0	
		player_sprite.play()
	else:
		player_sprite.stop()
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)


func _on_body_entered(_body):
	hide()
	hit.emit()
	player_collision.set_deferred("disabled", true)

func start(pos): 
	position = pos
	show()
	player_collision.disabled = false
