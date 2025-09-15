# Slime.gd (Final Corrected Version)
extends CharacterBody2D

# --- 可调整的参数 ---
@export var speed: float = 120.0
@export var jump_height: float = -250.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- 生命值相关 ---
@export var max_hp: int = 50
var current_hp: int

# --- 内部变量 ---
var direction = -1 # 初始方向向左

# --- 节点引用 ---
@onready var sprite = $Sprite2D
@onready var jump_timer = $JumpTimer
@onready var wall_detector = $WallDetector
@onready var ledge_detector = $LedgeDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	_update_visuals()
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	current_hp = max_hp
	# 连接动画播放完成信号
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# 持续施加重力
	if not is_on_floor():
		velocity.y += gravity * delta
		velocity.x = speed * direction * 0.8
	else:
		# 当在地面上时，让它有一个比较慢的速度，以防止它停在悬崖边
		# 这样比较能触发LedgeDetector
		velocity.x = speed * direction * 0.2

	# -----------------------------------------------------------------
	# 在物理帧中持续检测环境，实现立即反应
	# 只有当史莱姆在地面上时，才需要检查前方是否有障碍
	if is_on_floor():
		if wall_detector.is_colliding() or not ledge_detector.is_colliding():
			turn_around()
	# -----------------------------------------------------------------

	move_and_slide()

# 简化：这里只负责执行跳跃动作
func _on_jump_timer_timeout():
	if is_on_floor():
		velocity.y = jump_height
		velocity.x = speed * direction * 0.8
	
	jump_timer.start()

func turn_around():
	direction *= -1
	_update_visuals()

func _update_visuals():
	sprite.scale.x = -direction
	
	wall_detector.target_position.x = abs(wall_detector.target_position.x) * direction
	ledge_detector.position.x = abs(ledge_detector.position.x) * direction

# --- 核心函数 ---
func take_damage(amount: int):
	current_hp -= amount
	print("Slime HP: ", current_hp, "/", max_hp)
	if current_hp <= 0:
		die()

func die():
	print("Slime has died!")
	animation_player.play("die")
	# 不再直接调用queue_free()，而是在动画播放完成后再释放

# 添加动画完成回调函数
func _on_animation_finished(anim_name):
	if anim_name == "die":
		queue_free()

# --- 连接信号的回调函数 ---
func _on_slime_hitbox_area_entered(area):
	# area 是我们碰到的 PlayerHurtbox
	# 计算伤害
	var damage = randi_range(10, 20)
	# 让玩家受伤
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)
