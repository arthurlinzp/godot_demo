extends HBoxContainer

var heart_full = preload("res://heart_ui/Heart_full.png")
var heart_empty = preload("res://heart_ui/Heart_empty.png")
var heart_half = preload("res://heart_ui/Heart_half.png")

enum TYPES {type1, type2, type3}
@export var type = TYPES.type1

func update_heart(value):
	match type:
		TYPES.type1:
			update_type1(value)
		TYPES.type2:
			update_type2(value)
		TYPES.type3:
			update_type3(value)
			
func update_type1(value):
	for i in self.get_child_count():
		if i < value:
			get_child(i).texture = heart_full
		else:
			get_child(i).texture = heart_empty
	
func update_type2(value):
	print(2)
	
func update_type3(value):
	print(3)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
