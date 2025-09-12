# AttackState.gd
extends State

var player: CharacterBody2D
var animation_player: AnimationPlayer

func enter():
	animation_player.play("attack")
	print("Entering Attack State")
	
	# 攻击时通常不能移动
	player.velocity.x = 0
	
	# 连接信号：当动画播放完成时，调用 _on_animation_finished 函数
	animation_player.animation_finished.connect(_on_animation_finished)

func exit():
	# 离开状态时，务必断开信号连接，防止多次连接
	if animation_player.is_connected("animation_finished", _on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)

func _on_animation_finished(anim_name: StringName):
	# 确保是攻击动画结束了，而不是其他动画
	if anim_name == "attack":
		# 动画结束后，根据角色位置决定下一个状态
		if player.is_on_floor():
			get_parent().change_state("Idle")
		else:
			# 如果在空中攻击，结束后应该进入下落状态
			get_parent().change_state("Fall")

# 在攻击状态下，我们通常不处理输入，所以 physics_update 可以为空
func physics_update(_delta: float):
	pass
