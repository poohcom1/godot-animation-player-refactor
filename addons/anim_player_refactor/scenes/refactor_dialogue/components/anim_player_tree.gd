@tool
extends Tree

const EditInfo := preload("edit_info.gd")

@export var edittable_items := false

func _ready() -> void:
	reset_size()


func render(editor_plugin: EditorPlugin, anim_player: AnimationPlayer) -> void:
	clear()

	# Get paths
	var animations = anim_player.get_animation_list()
	var root_node := anim_player.get_node(anim_player.root_node)

	var track_paths := {}  # Dictionary[NodePath, Dictionary[NodePath, EditInfo]]

	# Get EditInfo data
	for anim_name in animations:
		var animation := anim_player.get_animation(anim_name)

		for i in animation.get_track_count():
			var path := animation.track_get_path(i)
			var type := animation.track_get_type(i)

			var node_path := NodePath(path.get_concatenated_names())
			var property_path := path.get_concatenated_subnames()
			var node := root_node.get_node_or_null(node_path)

			var edit_infos: Array[EditInfo] = []

			if not property_path.is_empty():
				edit_infos.append(EditInfo.new(EditInfo.Type.VALUE_TRACK, path, node_path, node))

			if not node_path in track_paths:
				track_paths[node_path] = {}

			match type:
				Animation.TYPE_VALUE:
					pass
				Animation.TYPE_METHOD:
					for j in animation.track_get_key_count(i):
						edit_infos.append(
							EditInfo.new(
								EditInfo.Type.METHOD_TRACK,
								NodePath(
									(
										path.get_concatenated_names()
										+ ":"
										+ animation.method_track_get_name(i, j)
									)
								),
								node_path,
								node
							)
						)

			for info in edit_infos:
				if not StringName(info.path) in track_paths[node_path]:
					track_paths[node_path][StringName(info.path)] = info

	# Sort
	var paths := track_paths.keys()
	paths.sort()

	var tree_root: TreeItem = create_item()
	hide_root = true

	# Get icons
	var gui := editor_plugin.get_editor_interface().get_base_control()

	# Render
	for path in paths:
		var node := root_node.get_node_or_null(path)
		var icon := gui.get_theme_icon(node.get_class() if node != null else "", "EditorIcons")

		var path_item = create_item(tree_root)
		path_item.set_editable(0, edittable_items)
		if edittable_items:
			path_item.set_text(0, path)
			if path.get_concatenated_names() == ".." and node:
				path_item.set_suffix(0, "(" + node.name + ")")
		else:
			path_item.set_text(0, node.name if node else path)
		path_item.set_icon(0, icon)
		path_item.set_metadata(0, EditInfo.new(EditInfo.Type.NODE, path, path, node))
		path_item.add_button(0, gui.get_theme_icon("Edit", "EditorIcons"))
		path_item.add_button(0, gui.get_theme_icon("Remove", "EditorIcons"))

		var property_paths: Array = track_paths[path].keys()
		property_paths.sort()

		for property_path in property_paths:
			var info: EditInfo = track_paths[path][property_path]
			var edit_type = EditInfo.Type.VALUE_TRACK
			var icon_type = "KeyValue"
			var invalid = false
			var property := info.path.get_concatenated_subnames()
			if node == null:
				invalid = true
				icon_type = ""
			elif node.has_method(StringName(property)):
				icon_type = "KeyCall"
			elif str(info.path) in node or node.get_indexed(NodePath(property)) != null:
				pass
			else:
				invalid = true
				icon_type = ""

			var property_item = create_item(path_item)
			property_item.set_editable(0, edittable_items)
			property_item.set_text(0, property)
			property_item.set_icon(0, gui.get_theme_icon(icon_type, "EditorIcons"))
			property_item.set_metadata(0, info)
			property_item.add_button(0, gui.get_theme_icon("Edit", "EditorIcons"))
			property_item.add_button(0, gui.get_theme_icon("Remove", "EditorIcons"))

			if invalid:
				property_item.set_custom_color(0, Color.RED)
				property_item.set_tooltip_text(
					0, "Possibly invalid value: %s" % info.path
				)


## Class to cache heirarchy of nodes
## Unused
class TreeNode:
	var node: Node
	var path: String
	var children: Dictionary
	var parent: TreeNode

	func debug(level = 0):
		print(" - ".repeat(level) + node.name)
		for name in children:
			children[name].debug(level + 1)