# Slime.gd (Final Corrected Version)
extends CharacterBody2D

signal health_changed(current_hp, max_hp)

# --- 可调整的参数 ---
@export var speed: float = 120.0
@export var jump_height: float = -250.0
@export var detect_range: float = 100.0  # 检测玩家的范围
@export var follow_speed: float = 150.0  # 追踪玩家时的速度
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var friction: float = 1000.0 # 值越大，停得越快

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
const KNOCKBACK_VERTICAL_POWER: float = 0.5
var is_hurt: bool = false
var hurt_duration: float = 0.25
var hurt_timer: float = 0.0
var knockback_power: float = 250.0

var is_dead: bool = false


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
	if is_dead:
		return
		
	var on_floor = is_on_floor()
		
	# 持续施加重力
	if not on_floor:
		velocity.y += gravity * delta
		# 在空中时，让击退效果持续，但可以稍微减速
		if is_hurt:
			velocity.x = move_toward(velocity.x, 0, friction * 0.1 * delta)
		else: # 如果没受伤，则按正常逻辑移动
			velocity.x = speed * direction * 0.8
			
	# 处理受击效果
	if is_hurt:
		# 如果在地面上，施加摩擦力让它停下来
		if on_floor:
			velocity.x = move_toward(velocity.x, 0, friction * delta)
			if abs(velocity.x) < 0.1:
				velocity.x = 0
		
		# 倒计时和闪烁效果保持不变
		hurt_timer -= delta
		sprite.modulate = Color(1, 1, 1) if fmod(hurt_timer, 0.1) < 0.05 else Color(1, 0, 0)
		
		if hurt_timer <= 0:
			is_hurt = false
			sprite.modulate = Color(1, 1, 1)

	# -----------------------------------------------------------------
	# 在物理帧中持续检测环境，实现立即反应
	# 只有当史莱姆在地面上时，才需要检查前方是否有障碍
	if on_floor and not is_hurt:
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
	velocity.y = -knockback_power * KNOCKBACK_VERTICAL_POWER  # 向上击飞效果

func die():
	if is_dead:
		return
	is_dead = true # 锁住死亡状态！
	
	print("Slime has died!")
	animation_player.play("die")
	
	# 停止所有潜在的移动和交互
	jump_timer.stop() # 停止AI计时器，防止死后还想跳
	velocity = Vector2.ZERO # 立即停止当前所有速度
	# 使用 set_deferred 来安全地禁用碰撞体
	var shapes = [
		"CollisionShape2D",
		"SlimeHitbox/CollisionShape2D",
		"SlimeHurtbox/CollisionShape2D"
	]
	
	for path in shapes:
		var node = get_node_or_null(path)
		if node:
			node.set_deferred("disabled", true)

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
	var player_x = player.global_position.x
	var slime_x = global_position.x
	var dx = player_x - slime_x
	# 获取“玩家相对于史莱姆”的目标方向
	var target_dir = 1 if dx > 0 else -1
	# 🚫 只有当目标方向与当前方向不一致时，才考虑是否转向
	if target_dir != direction:
		# 💡 智能转向：只有当玩家“越过中线”（dx 绝对值较大）时才允许转向
		# 避免贴脸时因微小位移抖动
		if abs(dx) > 8.0:  # 可调参数，推荐 5~15
			direction = target_dir
			_update_visuals()
	# 保持移动
	velocity.x = follow_speed * direction

func _on_health_changed(new_hp: int, max_hp_value: int):
	health_bar.max_value = max_hp_value
	health_bar.value = new_hp
