## Utility class to handle all refactoring logic


# Nodes

static func rename_node_path(anim_player: AnimationPlayer, old: NodePath, new: NodePath):
	if old == new:
		return

	var callback := func(animation: Animation):
		var count := 0
		for i in animation.get_track_count():
			var path := animation.track_get_path(i)
			var node_path := path.get_concatenated_names()

			if node_path == old.get_concatenated_names():
				var new_path := new.get_concatenated_names() + ":" + path.get_concatenated_subnames()
				animation.track_set_path(i, NodePath(new_path))
				count += 1
		return count

	var count = recurse_animations(anim_player, callback)

	print("Renamed %d tracks!" % count)


static func remove_node_path(anim_player: AnimationPlayer, node_path: NodePath):

	var callback := func(animation: Animation):
		var count := 0
		for i in range(animation.get_track_count() - 1, 0, -1):
			var path = animation.track_get_path(i)
			if NodePath(path.get_concatenated_names()) == node_path:
				animation.remove_track(i)
				count += 1
		return count

	var count = recurse_animations(anim_player, callback)

	print("Removed %d tracks!" % count)

# Tracks

static func rename_track_path(anim_player: AnimationPlayer, old: NodePath, new: NodePath):
	if old == new:
		return

	var callback = func(animation: Animation):
		var count := 0
		for i in animation.get_track_count():
			var path = animation.track_get_path(i)
			if path == old:
				animation.track_set_path(i, new)
				count += 1
		return count

	var count = recurse_animations(anim_player, callback)

	print("Renamed %d tracks!" % count)


static func remove_track_path(anim_player: AnimationPlayer, property_path: NodePath):
	var callback := func(animation: Animation):
		var count = 0
		for i in range(animation.get_track_count() - 1, 0, -1):
			var path = animation.track_get_path(i)
			if path == property_path:
				animation.remove_track(i)
				count += 1
		return count
	
	var count = recurse_animations(anim_player, callback)

	print("Removed %d tracks!" % count)


# Method tracks

static func rename_method(anim_player, node: NodePath, old: StringName, new: StringName):
	if old == new:
		return

	var callback = func(animation: Animation):
		var count := 0
		for i in animation.get_track_count():
			if animation.track_get_type(i) == Animation.TYPE_METHOD:
				for j in animation.track_get_key_count(i):
					var name := animation.method_track_get_name(i, j)
					if name == old:
						var method := {
							"method": new,
							"args": animation.method_track_get_params(i, j)
						}

						animation.track_set_key_value(i, j, method)
						count += 1

		return count

	var count = recurse_animations(anim_player, callback)

	print("Renamed %d method keys!" % count)

# Root
static func change_root(anim_player: AnimationPlayer, new_path: NodePath):
	var current_root: Node = anim_player.get_node(anim_player.root_node)
	var new_root: Node = anim_player.get_node_or_null(new_path)

	if new_root == null:
		return

	var callback := func(animation: Animation):
		var count := 0
		for i in animation.get_track_count():
			var path := animation.track_get_path(i)
			var node := current_root.get_node_or_null(NodePath(path.get_concatenated_names()))

			if node == null:
				push_warning("Invalid path: %s. Skipping root change." % path)
				continue
			
			var updated_path = str(new_root.get_path_to(node)) + ":" + path.get_concatenated_subnames()
			animation.track_set_path(i, updated_path)
		return count

	recurse_animations(anim_player, callback)
	anim_player.root_node = new_path
	print("Changed root to %s" % new_root.name)


# Helper

## Helper method to recurse through all animations and save when edited
## 	callback: (Animation) -> int
##		- Returns number of animation changed
static func recurse_animations(anim_player: AnimationPlayer, callback: Callable) -> int:
	var changed := 0
	for lib_name in anim_player.get_animation_library_list():
		var lib_changed := false
		var lib := anim_player.get_animation_library(lib_name)

		for animation_name in lib.get_animation_list():
			var animation := lib.get_animation(animation_name)
			var count = callback.call(animation)
			if count is int: # Possibly null
				changed += count
			try_save_resource(animation)
		try_save_resource(lib)
	return changed
		
		
static func try_save_resource(res: Resource):
	if not res.resource_path.is_empty() and not "::" in res.resource_path:
		ResourceSaver.save(res, res.resource_path)
