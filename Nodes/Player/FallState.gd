# FallState.gd
extends State

var player: CharacterBody2D
var animation_player: AnimationPlayer

func enter():
	animation_player.play("fall")
	print("Entering Fall State")

func physics_update(_delta: float):
	# 检查是否已落地
	if player.is_on_floor():
		# 根据落地时是否有移动输入来决定下一个状态
		var direction = Input.get_axis("left", "right")
		if direction == 0:
			get_parent().change_state("Idle")
		else:
			get_parent().change_state("Run")
		return # 落地后立即返回

	# 空中左右移动逻辑
	var direction = Input.get_axis("left", "right")
	player.velocity.x = direction * (player.speed * 0.75) 

	# --- 修改后的翻转逻辑 ---
	# 假设你的精灵节点名为 "Sprite2D"，如果不是请修改
	var sprite = player.get_node("Sprite2D")
	
	# 只有在有输入时才改变方向
	if direction > 0:
		sprite.scale.x = 1 # 面向右
	elif direction < 0:
		sprite.scale.x = -1 # 面向左
