# Player.gd
extends CharacterBody2D

signal health_changed(current_hp, max_hp)

# 将这些变量导出，以便在状态脚本中通过 @export 引用
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
# --- 生命值相关 ---
@export var max_hp: int = 100
@export var current_hp: int

# --- 节点引用 ---
@onready var player_hitbox = $PlayerHitbox
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var state_machine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D

# --- 受击效果相关 ---
var is_hurt: bool = false
var hurt_duration: float = 0.25
var hurt_timer: float = 0.0
var knockback_power: float = 200.0

# 新增一个死亡状态锁，防止多次触发死亡逻辑
var is_dead: bool = false


func _ready():
	# 将Player添加到player组中，方便Slime查找
	add_to_group("player")
	current_hp = max_hp
	# 确保Hitbox一开始是禁用的
	player_hitbox.get_node("CollisionShape2D").disabled = true
	# 连接动画播放完成信号
	animation_player.animation_finished.connect(_on_animation_finished)
	call_deferred("_emit_initial_health")
	
func _physics_process(delta):
	# 如果已经死了，就停止所有物理和受击处理
	if is_dead:
		return
	# 重力应用
	if not is_on_floor():
		velocity.y += gravity * delta

	# 处理受击效果
	if is_hurt:
		hurt_timer -= delta
		# 闪烁效果
		sprite.modulate = Color(1, 1, 1) if fmod(hurt_timer, 0.1) < 0.05 else Color(1, 0, 0)
		
		if hurt_timer <= 0:
			is_hurt = false
			sprite.modulate = Color(1, 1, 1)

	# 统一执行移动
	move_and_slide()
	
	
# --- 核心函数 ---
func take_damage(amount: int, from_position: Vector2 = Vector2.ZERO):
	# 如果已经死了，立即返回，不处理任何后续伤害
	if is_dead:
		return
	current_hp -= amount
	if current_hp < 0:
		current_hp = 0
	print("Player HP: ", current_hp, "/", max_hp)
	health_changed.emit(current_hp, max_hp)
	
	# 调整逻辑顺序：先判断是否死亡
	if current_hp <= 0:
		die()
	else:
		# 如果没死，才应用受伤效果
		_apply_hurt_effect(from_position)

func _apply_hurt_effect(from_position: Vector2):
	is_hurt = true
	hurt_timer = hurt_duration
	
	# 计算击退方向（远离攻击源）
	var knockback_direction = (global_position - from_position).normalized()
	velocity.x = knockback_direction.x * knockback_power
	velocity.y = -knockback_power * 0.5  # 向上击飞效果

func die():
	if is_dead:
		return
	print("Player has died!")
	animation_player.play("die")
	state_machine.set_physics_process(false)

# --- 连接信号的回调函数 ---
func _on_player_hitbox_area_entered(area):
	# area 是我们碰到的 Hurtbox (比如 SlimeHurtbox)
	print("Player hit something!")
	# 计算随机伤害
	var damage = randi_range(30, 40)
	# 让被击中的对象受伤
	# area.get_parent() 会获取到 Slime 根节点
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage, global_position)

# 添加动画完成回调函数
func _on_animation_finished(anim_name):
	if anim_name == "die":
		queue_free()

func _emit_initial_health():
	health_changed.emit(current_hp, max_hp)
