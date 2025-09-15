# Slime.gd (Final Corrected Version)
extends CharacterBody2D

signal health_changed(current_hp, max_hp)

# --- 可调整的参数 ---
@export var speed: float = 120.0
@export var jump_height: float = -250.0
@export var detect_range: float = 100.0  # 检测玩家的范围
@export var follow_speed: float = 150.0  # 追踪玩家时的速度
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# --- 生命值相关 ---
@export var max_hp: int = 50
var current_hp: int

# --- 内部变量 ---
var direction = -1 # 初始方向向左
var player: Node2D = null  # 玩家节点引用

# --- 节点引用 ---
@onready var sprite = $Sprite2D
@onready var jump_timer = $JumpTimer
@onready var wall_detector = $WallDetector
@onready var ledge_detector = $LedgeDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var health_bar: ProgressBar = $HealthBar

# --- 受击效果相关 ---
var is_hurt: bool = false
var hurt_duration: float = 0.25
var hurt_timer: float = 0.0
var knockback_power: float = 150.0


func _ready():
	_update_visuals()
	jump_timer.timeout.connect(_on_jump_timer_timeout)
	current_hp = max_hp
	# 连接动画播放完成信号
	animation_player.animation_finished.connect(_on_animation_finished)
	
	# 获取玩家节点引用
	player = get_tree().get_nodes_in_group("player")[0] if get_tree().get_nodes_in_group("player").size() > 0 else null
	
	# 连接信号到 HealthBar 的更新函数
	health_changed.connect(_on_health_changed)
	# 初始化 HealthBar 的显示
	health_changed.emit(current_hp, max_hp)
	
func _physics_process(delta):
	# 持续施加重力
	if not is_on_floor():
		velocity.y += gravity * delta
		if not is_hurt:
			velocity.x = speed * direction * 0.8
	else:
		# 当在地面上时，让它有一个比较慢的速度，以防止它停在悬崖边
		# 这样比较能触发LedgeDetector
		if not is_hurt:
			velocity.x = speed * direction * 0.2

	# 处理受击效果
	if is_hurt:
		hurt_timer -= delta
		# 闪烁效果
		sprite.modulate = Color(1, 1, 1) if fmod(hurt_timer, 0.1) < 0.05 else Color(1, 0, 0)
		
		if hurt_timer <= 0:
			is_hurt = false
			sprite.modulate = Color(1, 1, 1)

	# -----------------------------------------------------------------
	# 在物理帧中持续检测环境，实现立即反应
	# 只有当史莱姆在地面上时，才需要检查前方是否有障碍
	if is_on_floor() and not is_hurt:
		# 检查是否需要追踪玩家
		if _should_follow_player():
			_follow_player()
		elif wall_detector.is_colliding() or not ledge_detector.is_colliding():
			turn_around()
	# -----------------------------------------------------------------

	move_and_slide()

# 简化：这里只负责执行跳跃动作
func _on_jump_timer_timeout():
	if is_on_floor() and not is_hurt:
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
func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO):
	current_hp -= amount
	print("Slime HP: ", current_hp, "/", max_hp)
	
	health_changed.emit(current_hp, max_hp)
	health_bar.visible = true
	
	# 添加受击效果
	if current_hp > 0:
		_apply_hurt_effect(from_position)
	
	if current_hp <= 0:
		die()

func _apply_hurt_effect(from_position: Vector2):
	is_hurt = true
	hurt_timer = hurt_duration
	
	# 计算击退方向（远离攻击源）
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * knockback_power
	velocity.y = -knockback_power * 0.5  # 向上击飞效果

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
		area.get_parent().take_damage(damage, global_position)

# --- 追踪玩家相关函数 ---
func _should_follow_player() -> bool:
	# 检查是否应该追踪玩家
	if player == null:
		return false
	
	# 检查玩家是否在水平检测范围内且垂直距离足够近
	var horizontal_distance = abs(player.global_position.x - global_position.x)
	var vertical_distance = abs(player.global_position.y - global_position.y)
	
	return horizontal_distance <= detect_range and vertical_distance <= 32

func _follow_player():
	# 朝玩家方向移动
	if player.global_position.x > global_position.x:
		direction = 1  # 向右
	else:
		direction = -1  # 向左
	
	velocity.x = follow_speed * direction
	_update_visuals()

func _on_health_changed(new_hp: int, max_hp_value: int):
	health_bar.max_value = max_hp_value
	health_bar.value = new_hp
