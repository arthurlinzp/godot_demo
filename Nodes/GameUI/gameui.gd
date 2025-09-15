# GameUI.gd
extends CanvasLayer

# 获取对 Label 节点的引用
@onready var hp_label: Label = $HPLabel

# 定义血条颜色
const COLOR_FULL = Color("78e08f")  # 一种柔和的绿色
const COLOR_HALF = Color("f6e58d")  # 一种柔和的黄色
const COLOR_DANGER = Color("ff7979") # 一种柔和的红色

func _ready():
	# 找到 Player 节点。因为Player在 "player" 组中，这是最好的方法。
	var player = get_tree().get_first_node_in_group("player")
	
	# 检查是否找到了Player，以防万一
	if player:
		# 将 Player 的 health_changed 信号连接到我们自己的 _on_player_health_changed 函数上
		player.health_changed.connect(_on_player_health_changed)

# 这个函数会在 Player 发出 health_changed 信号时被自动调用
func _on_player_health_changed(current_hp: int, max_hp: int):
	# 更新 Label 的文本
	hp_label.text = "HP: %s / %s" % [current_hp, max_hp]
	print(hp_label.text)
	# 更新 Label 的颜色
	var health_ratio = float(current_hp) / float(max_hp)
	
	var new_color: Color
	if health_ratio > 0.5:
		# 血量在 50% 到 100% 之间时，在绿色和黄色之间插值
		# 我们需要将 [0.5, 1.0] 的范围映射到 [0.0, 1.0]
		var weight = (health_ratio - 0.5) * 2.0
		new_color = COLOR_HALF.lerp(COLOR_FULL, weight)
	else:
		# 血量在 0% 到 50% 之间时，在红色和黄色之间插值
		# 我们需要将 [0.0, 0.5] 的范围映射到 [0.0, 1.0]
		var weight = health_ratio * 2.0
		new_color = COLOR_DANGER.lerp(COLOR_HALF, weight)
		
	# 应用新颜色到 Label 的字体颜色
	hp_label.add_theme_color_override("font_color", new_color)
