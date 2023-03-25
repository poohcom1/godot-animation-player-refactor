@tool
extends AcceptDialog

const AnimPlayerRefactor = preload("res://addons/anim_player_refactor/lib/anim_player_refactor.gd")
const AnimPlayerTree := preload("components/anim_player_tree.gd")
const EditInfo := preload("components/edit_info.gd")

const NodeSelect := preload("components/node_select.gd")

var _editor_plugin: EditorPlugin
var _editor_interface: EditorInterface
var _anim_player: AnimationPlayer

@onready var tree: AnimPlayerTree = $%AnimPlayerTree

@onready var root_node_tree: Tree = $%RootNodeTree

@onready var edit_dialogue: ConfirmationDialog = $%EditDialogue
@onready var edit_dialogue_input: LineEdit = $%EditInput
@onready var edit_dialogue_button: Button = $%EditDialogueButton
@onready var edit_full_path_toggle: CheckButton = $%EditFullPathToggle

@onready var node_select_dialogue: ConfirmationDialog = $%NodeSelectDialogue
@onready var node_select: NodeSelect = $%NodeSelect

var _selected_item: TreeItem


var is_full_path: bool:
	set(val): edit_full_path_toggle.button_pressed = val
	get: return edit_full_path_toggle.button_pressed


func init(editor_plugin: EditorPlugin) -> void:
	_editor_plugin = editor_plugin
	_editor_interface = editor_plugin.get_editor_interface()
	node_select.init(_editor_plugin)


func _ready() -> void:
	wrap_controls = true
	about_to_popup.connect(render)



func render():
	_anim_player = get_anim_player()

	title = (
		"Refactoring %s::%s"
		% [
			_anim_player.owner.scene_file_path.substr(6),
			_anim_player.owner.get_path_to(_anim_player)
		]
	)

	if not _anim_player or not _anim_player is AnimationPlayer:
		push_error("AnimationPlayer is null or invalid")
		return

	# Render track tree
	tree.render(_editor_plugin, _anim_player)

	# Render root node tree
	var root_node: Node = _anim_player.get_node(_anim_player.root_node)
	var node_path := str(_anim_player.owner.get_path_to(root_node))
	if node_path == ".":
		node_path = _anim_player.owner.name
	else:
		node_path = _anim_player.owner.name + "/" + node_path

	root_node_tree.clear()
	var root_node_item = root_node_tree.create_item()
	root_node_item.custom_minimum_height = root_node_tree.custom_minimum_size.y
	root_node_item.set_selectable(0, false)
	root_node_item.set_text(0, node_path)
	root_node_item.set_icon(
		0, _editor_interface.get_base_control().get_theme_icon(root_node.get_class(), "EditorIcons")
	)

	reset_size()


# Rename
var _current_info: EditInfo
func _on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	_current_info = item.get_metadata(column)
	_selected_item = item

	if id == 0:
		# Rename
		_render_edit_dialogue()
		edit_dialogue.popup_centered()
		edit_dialogue_input.grab_focus()
		edit_dialogue_input.select_all()
	elif id == 1:
		# Remove
		pass


func _render_edit_dialogue():
	var info := _current_info
	
	if info.type == EditInfo.Type.METHOD_TRACK:
		is_full_path = false
		edit_full_path_toggle.disabled = true
	else:
		edit_full_path_toggle.disabled = false
	
	if is_full_path:
		edit_dialogue_input.text = info.path
	else:
		match info.type:
			EditInfo.Type.NODE:
				edit_dialogue_input.text = info.path.get_name(info.path.get_name_count() - 1)
			EditInfo.Type.VALUE_TRACK, EditInfo.Type.METHOD_TRACK:
				edit_dialogue_input.text = info.path.get_concatenated_subnames()
	edit_dialogue_button.text = info.node_path
	if info.node:
		edit_dialogue_button.icon = _editor_interface.get_base_control().get_theme_icon(
			info.node.get_class(), "EditorIcons"
		)


func _on_full_path_toggled(pressed: bool):
	_render_edit_dialogue()


func _on_rename_confirmed(_arg0 = null):
	_rename(_selected_item, edit_dialogue_input.text)


func _rename(item: TreeItem, new: String):
	edit_dialogue.hide()
	if not _anim_player or not _anim_player is AnimationPlayer:
		push_error("AnimationPlayer is null or invalid")
		return

	if new.is_empty():
		return
	

	var info: EditInfo = item.get_metadata(0)
	match info.type:
		EditInfo.Type.NODE:
			var old := info.path
			var new_path = new
			if not is_full_path:
				new_path = ""
				for i in range(new_path.get_name_count() - 1):
					new_path += new_path.get_name(i) + "/"
				new_path += new
			AnimPlayerRefactor.rename_node_path(_anim_player, old, NodePath(new))
		EditInfo.Type.VALUE_TRACK:
			var old_path := info.path
			var new_path := NodePath(new)
			if not is_full_path:
				new_path = info.node_path.get_concatenated_names() + ":" + new
			AnimPlayerRefactor.rename_track_path(_anim_player, old_path, new_path)
		EditInfo.Type.METHOD_TRACK:
			var old_method := info.path.get_concatenated_subnames()
			var new_method := StringName(new)
			AnimPlayerRefactor.rename_method(_anim_player, info.node_path, old_method, new_method)
	await get_tree().create_timer(0.1).timeout
	render()


func _remove(tree_item: TreeItem):
	await get_tree().create_timer(0.1).timeout
	render()


# Change root
func _on_change_root_pressed():
	node_select_dialogue.popup_centered()
	node_select.render(get_anim_player())


func _on_node_select_confirmed():
	var path: NodePath = node_select.get_selected().get_metadata(0)

	AnimPlayerRefactor.change_root(get_anim_player(), path)

	await get_tree().create_timer(0.1).timeout
	render()


# Helper
func get_anim_player() -> AnimationPlayer:
	if not _editor_interface:
		return null
	var selection := _editor_interface.get_selection()
	var nodes := selection.get_selected_nodes()

	if nodes.size() == 1 and nodes[0] is AnimationPlayer:
		return nodes[0]

	return null


## Unused
func _on_item_edited():
	if not _anim_player or not _anim_player is AnimationPlayer:
		push_error("AnimationPlayer is null or invalid")
		return

	_rename(tree.get_edited(), tree.get_edited().get_text(0))
