# Player.gd
extends CharacterBody2D

# 将这些变量导出，以便在状态脚本中通过 @export 引用
@export var speed: float = 300.0
@export var jump_velocity: float = -400.0
# --- 生命值相关 ---
@export var max_hp: int = 100
@export var current_hp: int

# --- 节点引用 ---
@onready var player_hitbox = $PlayerHitbox
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var state_machine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready():
	current_hp = max_hp
	# 确保Hitbox一开始是禁用的
	player_hitbox.get_node("CollisionShape2D").disabled = true
	# 连接动画播放完成信号
	animation_player.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# 重力应用
	if not is_on_floor():
		velocity.y += gravity * delta

	# 统一执行移动
	move_and_slide()
	
	
# --- 核心函数 ---
func take_damage(amount: int):
	current_hp -= amount
	print("Player HP: ", current_hp, "/", max_hp)
	# 在这里可以添加受伤动画、音效、屏幕闪烁等
	if current_hp <= 0:
		die()

func die():
	print("Player has died!")
	animation_player.play("die")

# --- 连接信号的回调函数 ---
func _on_player_hitbox_area_entered(area):
	# area 是我们碰到的 Hurtbox (比如 SlimeHurtbox)
	print("Player hit something!")
	# 计算随机伤害
	var damage = randi_range(30, 40)
	# 让被击中的对象受伤
	# area.get_parent() 会获取到 Slime 根节点
	if area.get_parent().has_method("take_damage"):
		area.get_parent().take_damage(damage)

# 添加动画完成回调函数
func _on_animation_finished(anim_name):
	if anim_name == "die":
		queue_free()
