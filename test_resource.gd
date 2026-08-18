@tool
class_name TestResource
extends Resource


@export_tool_button("test") var test = _test


func _test() -> void:
	var node: Node2D = Node2D.new()
	
	node.free()
	
	var node2: Node2D = null
	
	print([node, typeof(node), node == null, !!node])
	
	
	print([node2, typeof(node2), node2 == null, !!node2])
