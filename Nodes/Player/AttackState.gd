# AttackState.gd
extends State

var player: CharacterBody2D
var animation_player: AnimationPlayer

# --- 新增：可调整的摩擦力 ---
# 这个值越大，惯性滑行停止得越快。你可以在编辑器里微调它。
@export var friction: float = 200.0

func enter():
	animation_player.play("attack")
	print("Entering Attack State")
	
	# 攻击时通常不能移动
	player.velocity.x *= 0.5
	
	# 连接信号：当动画播放完成时，调用 _on_animation_finished 函数
	# 先检查是否已经连接，避免重复连接导致多次触发
	if not animation_player.is_connected("animation_finished", _on_animation_finished):
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

# 在攻击状态下
func physics_update(_delta: float):
	# 逐渐减少水平速度，实现摩擦效果
	# move_toward 是 Godot 提供的实用函数，用于平滑地移动值接近目标值
	player.velocity.x = move_toward(player.velocity.x, 0, friction * _delta)