# State.gd
class_name State
extends Node

# 当状态机切换到这个状态时被调用
func enter():
	pass # 子类将重写这个方法

# 当状态机离开这个状态时被调用
func exit():
	pass # 子类将重写这个方法

# 处理非物理相关的逐帧逻辑 (在 _process 中调用)
func update(_delta: float):
	pass # 子类将重写这个方法

# 处理物理相关的逐帧逻辑 (在 _physics_process 中调用)
func physics_update(_delta: float):
	pass # 子类将重写这个方法
