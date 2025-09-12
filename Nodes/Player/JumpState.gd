# JumpState.gd
extends State

@export var player: CharacterBody2D
@export var animation_player: AnimationPlayer
@export var jump_velocity: float = -400.0

func enter():
	print("Entering Jump State")
	# 施加一个向上的瞬时速度
	player.velocity.y = jump_velocity
	animation_player.play("jump")

func physics_update(_delta: float):
	# 检查转换条件
	# 1. 当向上的速度消失 (即开始下落)，切换到 Fall 状态
	if player.velocity.y > 0:
		get_parent().change_state("Fall")
		return
		
	# 可以在这里添加空中左右移动的逻辑
	var direction = Input.get_axis("left", "right")
	player.velocity.x = direction * 200.0 # 空中速度可以慢一点
