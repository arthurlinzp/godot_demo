# Player.gd
extends CharacterBody2D

# 将这些变量导出，以便在状态脚本中通过 @export 引用
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var state_machine = $StateMachine

func _physics_process(delta):
	# 重力应用
	if not is_on_floor():
		velocity.y += gravity * delta

	# 统一执行移动
	move_and_slide()
