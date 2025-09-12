# StateMachine.gd
extends Node

@export var initial_state: State

var states: Dictionary = {}
var current_state: State

func _ready():
	# Player 节点是 StateMachine 的父节点
	var player_node = get_parent()
	var animation_player_node = player_node.get_node("AnimationPlayer")

	for child in get_children():
		if child is State:
			states[child.name] = child
			# 注意: 这里不再需要导出player和animation_player
			# 我们直接在代码中设置它们
			# 这比在每个状态的检查器中手动拖拽要好得多
			child.set("player", player_node)
			child.set("animation_player", animation_player_node)

	if initial_state:
		current_state = initial_state
		current_state.enter()

func _physics_process(delta: float):
	if current_state:
		current_state.physics_update(delta)

func change_state(new_state_name: String):
	if not states.has(new_state_name) or states[new_state_name] == current_state:
		return

	if current_state:
		current_state.exit()

	current_state = states[new_state_name]
	current_state.enter()
