# Utility class for parsing and hacking the editor

static func find_animation_menu_button(node: Node) -> MenuButton:
	if node is MenuButton and node.text == "Animation":
		return node
	
	for child in node.get_children():
		# Not sure if this helps to prevent checking the actual scene tree
		if not child is Control:
			continue
		
		var menu_button = find_animation_menu_button(child)
		if menu_button:
			return menu_button
		
	return null


static func find_editor_control_with_class(base: Control, p_class_name: StringName) -> Node:
	if base.get_class() == p_class_name:
		return base
		
	for child in base.get_children():
		if not child is Control:
			continue
			
		var found = find_editor_control_with_class(child, p_class_name)
		if found:
			return found
		
	return null



# Finds the active animation player (either pinned or selected)
static func find_active_anim_player(base_control: Control, scene_tree: Tree) -> AnimationPlayer:
	var find_anim_player_recursive: Callable
	
	var pin_icon := scene_tree.get_theme_icon("Pin", "EditorIcons")
	
	var stack: Array[TreeItem] = []
	stack.append(scene_tree.get_root())
	
	while not stack.is_empty():
		var current := stack.pop_back() as TreeItem
		
		# Check for pin icon
		for i in current.get_button_count(0):
			if current.get_button(0, i) == pin_icon:
				var node := base_control.get_node_or_null(current.get_metadata(0))
				if node is AnimationPlayer:
					return node
		
		if current.is_selected(0):
			var node := base_control.get_node_or_null(current.get_metadata(0))
			if node is AnimationPlayer:
				return node
		
		for i in range(current.get_child_count() - 1, -1, -1):
			stack.push_back(current.get_child(i))
		
	return null