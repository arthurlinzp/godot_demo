extends CharacterBody2D

# 移动参数
@export var speed: float = 200.0
@export var jump_velocity: float = -400.0
@export var gravity: float = 800.0
@export var cureen_health = 5

# 引用动画节点
@onready var animated_sprite = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var attack_coll: CollisionShape2D = $Hitbox/attackColl
@onready var heart: HBoxContainer = $CanvasLayer/heart

# 攻击后血量+1
func enable_attack_hitbox():
	attack_coll.disabled = false
	$CanvasLayer/heart.update_heart(cureen_health)

func disable_attack_hitbox():
	attack_coll.disabled = true
	
#攻击血量+1
func doAttack(value):
	if cureen_health >= 5:
		return
	cureen_health += value
	$CanvasLayer/heart.update_heart(cureen_health)

#受伤血量-1
func demage(value):
	cureen_health -= value
	$CanvasLayer/heart.update_heart(cureen_health)


# 攻击冷却时间（秒）
var attack_cooldown: float = 0.5
var can_attack: bool = true

# 状态常量
enum State { IDLE, RUN, JUMP, FALL, ATTACK, ATTACK2 }
var current_state: State = State.IDLE

func _ready():
	# 确保初始动画正确
	_change_animation("idle")
	# 连接动画完成信号
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# 应用重力
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0  # 避免地板上漂浮

	# 处理攻击（优先级高于移动）
	if _handle_attack_input():
		return  # 攻击时跳过移动逻辑（可选，根据需求调整）

	# 处理移动和跳跃
	_handle_movement_input(delta)

	# 更新动画状态（攻击结束后，这里会根据速度/地面修正状态）
	_update_animation()

	# 移动角色
	move_and_slide()

# 攻击动画播放完成后回调
func _on_animation_finished():
	if current_state == State.ATTACK or current_state == State.ATTACK2:
		# 攻击结束，回到空闲（下一帧会根据实际状态修正）
		current_state = State.IDLE
		_change_animation("idle")

# 处理攻击输入
func _handle_attack_input() -> bool:
	if not can_attack:
		return false

	if Input.is_action_just_pressed("attack"):
		_play_attack("attack")
		return true
	elif Input.is_action_just_pressed("attack2"):
		_play_attack("attack2")
		return true

	return false

# 播放攻击动画并设置冷却
func _play_attack(anim_name: String):
	current_state = State.ATTACK if anim_name == "attack" else State.ATTACK2
	_change_animation(anim_name)
	can_attack = false
	# 设置攻击冷却
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

# 处理移动和跳跃输入
func _handle_movement_input(_delta):  # 👈 加下划线，消除警告
	var direction = Input.get_axis("left", "right")
	velocity.x = direction * speed

	# 跳跃
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

# 更新动画状态
func _update_animation():
	# 如果正在攻击，不覆盖（等待动画结束自动回到 idle）
	if current_state == State.ATTACK or current_state == State.ATTACK2:
		return

	if not is_on_floor():
		if velocity.y < 0:
			_change_animation("jump")
			current_state = State.JUMP
		else:
			_change_animation("fall")
			current_state = State.FALL
	else:
		if velocity.x != 0:
			_change_animation("run")
			current_state = State.RUN
			# 根据方向翻转精灵
			animated_sprite.flip_h = velocity.x < 0
		else:
			_change_animation("idle")
			current_state = State.IDLE

# 安全切换动画（避免重复设置）
func _change_animation(anim_name: String):
	if animated_sprite.animation != anim_name:
		if anim_name == "attack":
			animation_player.play("attack_with_hitbox")
		else:
			animated_sprite.play(anim_name)
