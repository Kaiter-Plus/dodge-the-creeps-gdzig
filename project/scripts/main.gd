extends Node

@export var mob_scene: PackedScene

@onready var mob_timer = $MobTimer
@onready var score_timer = $ScoreTimer
@onready var start_timer = $StartTimer
@onready var player = $Player
@onready var start_position = $StartPosition
@onready var mob_spawn_location = $MobPath/MobSpawnLocation
#@onready var hud = $HUD
#@onready var music = $Music
#@onready var death_sound = $DeathSound
@onready var fps = $Fps

var score

func _ready():
	new_game()

func _process(_delta):
	fps.text = str(Engine.get_frames_per_second())

func _on_player_hit():
	game_over()


func _on_score_timer_timeout():
	score += 1
	#hud.update_score(score)


func _on_start_timer_timeout():
	mob_timer.start()
	score_timer.start()


func _on_mob_timer_timeout():
	# 创建一个小怪的实例
	var mob = mob_scene.instantiate()
	mob_spawn_location.progress_ratio = randf()
	# 旋转一定的角度，使方向朝向屏幕内测
	var direction = mob_spawn_location.rotation + PI / 2
	# 设置小怪的位置
	mob.position = mob_spawn_location.position
	# 随机朝向
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	# 从 [150, 250] 区间内选择一个数值作为小怪的移动速度
	var velocity = Vector2(randf_range(150.0, 250.0), 0)
	mob.linear_velocity = velocity.rotated(direction)
	# 把生成的小怪加到主场景中
	add_child(mob)
	
func game_over():
	score_timer.stop()
	mob_timer.stop()
	#hud.show_game_over()
	#music.stop()
	#death_sound.play()
	
func new_game():
	score = 0
	player.start(start_position.position)
	start_timer.start()
	#hud.update_score(score)
	#hud.show_message("Get Ready")
	get_tree().call_group("mobs", "queue_free")
	#music.play()
