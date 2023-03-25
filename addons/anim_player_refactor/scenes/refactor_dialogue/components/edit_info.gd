## Data class for storing information on tracks
extends Object

enum Type { VALUE_TRACK, METHOD_TRACK, NODE }

# Type of info being edited
var type: Type

## Full path to property. Same as node_path if type is NODE
var path: NodePath

## Full path to node
var node_path: NodePath

# Cached node
var node: Node

func _init(type: Type, path: NodePath, node_path: NodePath, node: Node) -> void:
	self.type = type
	self.path = path
	self.node = node
	self.node_path = node_path
