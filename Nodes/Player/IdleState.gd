# IdleState.gd
extends State

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer

func enter():
	# 进入站立状态时，播放idle动画
	animation_player.play("idle")
	print("Entering Idle State")
	
	# 速度归零
	player.velocity.x = 0

func physics_update(_delta: float):
	# 检查转换条件
	# 1. 如果不在地面上，切换到下落状态
	if not player.is_on_floor():
		get_parent().change_state("Fall") # 通知状态机切换状态
		return # 立即返回，防止执行后续逻辑

	# 2. 如果有水平输入，切换到跑步状态
	var direction = Input.get_axis("left", "right")
	if direction != 0:
		get_parent().change_state("Run")
		return

	# 3. 如果按下跳跃键，切换到跳跃状态
	if Input.is_action_just_pressed("jump"):
		get_parent().change_state("Jump")
		return
		
	# 4. 如果按下攻击键，切换到攻击状态
	if Input.is_action_just_pressed("attack"):
		get_parent().change_state("Attack")
		return
