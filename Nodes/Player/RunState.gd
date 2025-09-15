# RunState.gd
extends State

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	print("Entering Run State")
	animation_player.play("run")

func physics_update(_delta: float):
	# =========================================================
	# 按照优先级检查状态转换条件
	# =========================================================

	# 优先级 1: 是否离地？ (比如从平台上跑下去)
	# 如果不在地面上，无论如何都应该进入下落状态。
	if not player.is_on_floor():
		get_parent().change_state("Fall")
		return # 立即返回，防止执行后续逻辑
		
	# 优先级 2: 是否按下了跳跃键？
	# 在跑步时可以跳跃。
	if Input.is_action_just_pressed("jump"):
		get_parent().change_state("Jump")
		return
		
	# 优先级 3: 是否按下了攻击键？
	# 在跑步时也可以攻击。
	if Input.is_action_just_pressed("attack"):
		get_parent().change_state("Attack")
		return

	# 跑步逻辑
	var direction = Input.get_axis("left", "right")
	player.velocity.x = direction * player.speed
	
	# --- 修改后的翻转逻辑 ---
	var sprite = player.get_node("Sprite2D")
	
	if direction > 0:
		sprite.scale.x = 1 # 面向右
	elif direction < 0:
		sprite.scale.x = -1 # 面向左
		
	var hitbox = player.get_node("PlayerHitbox")
	hitbox.scale.x = sprite.scale.x
	#var hurtbox = player.get_node("PlayerHurtbox")
	#hurtbox.scale.x = sprite.scale.x
	
	# 如果没有移动输入，切换回站立
	if direction == 0:
		get_parent().change_state("Idle")
		return
