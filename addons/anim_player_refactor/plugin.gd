@tool
extends EditorPlugin

const RefactorDialogueScene := preload("scenes/refactor_dialogue/refactor_dialogue.tscn")
const RefactorDialogue := preload("scenes/refactor_dialogue/refactor_dialogue.gd")

const AnimPlayerInspectorButton := preload("scenes/inspector_button/inspector_button.gd")

const EditorUtil := preload("lib/editor_util.gd")

var activate_button: AnimPlayerInspectorButton
var refactor_dialogue: RefactorDialogue

var anim_menu_button: MenuButton

var _last_anim_player: AnimationPlayer
const SCENE_TREE_IDX := 0
var _scene_tree: Tree

func _enter_tree() -> void:
	# Create dialogue
	refactor_dialogue = RefactorDialogueScene.instantiate()
	get_editor_interface().get_base_control().add_child(refactor_dialogue)
	refactor_dialogue.init(self)
	# Create menu button
	_add_refactor_option(func(): 
		refactor_dialogue.popup_centered()
		refactor_dialogue.reset_size()
	)
	

func _exit_tree() -> void:
	if refactor_dialogue and refactor_dialogue.is_inside_tree():
		get_editor_interface().get_base_control().remove_child(refactor_dialogue)
		refactor_dialogue.queue_free()

	_remove_refactor_option()


func _handles(object: Object) -> bool:
	if object is AnimationPlayer:
		_last_anim_player = object
	return false


# Editor methods
func get_anim_player() -> AnimationPlayer:
	# Check for pinned animation
	if not _scene_tree:
		var _scene_tree_editor = EditorUtil.find_editor_control_with_class(
			get_editor_interface().get_base_control(),
			"SceneTreeEditor"
		)
		
		if not _scene_tree_editor:
			push_error("[Animation Refactor] Could not find scene tree editor. Please report this.")
			return null
			
		_scene_tree = _scene_tree_editor.get_child(SCENE_TREE_IDX)
		
	if not _scene_tree:
		push_error("[Animation Refactor] Could not find scene tree editor. Please report this.")
		return null
		
	var found_anim := EditorUtil.find_active_anim_player(
		get_editor_interface().get_base_control(),
		_scene_tree
	)
	
	if found_anim:
		return found_anim
	
	# Get latest edited
	return _last_anim_player


# Plugin buttons
func _add_refactor_option(on_pressed: Callable):
	var base_control := get_editor_interface().get_base_control()
	if not anim_menu_button:
		anim_menu_button = EditorUtil.find_animation_menu_button(base_control)
	anim_menu_button.get_popup().add_separator()
	anim_menu_button.get_popup().add_icon_item(
		base_control.get_theme_icon(&"Reload", &"EditorIcons"), "Refactor"
	)
	anim_menu_button.get_popup().index_pressed.connect(_on_menu_button_pressed)


func _remove_refactor_option():
	var base_control := get_editor_interface().get_base_control()
	
	var item_count := anim_menu_button.get_popup().item_count
	anim_menu_button.get_popup().remove_item(item_count - 1) # Item
	anim_menu_button.get_popup().remove_item(item_count - 2) # Separator

	anim_menu_button.get_popup().index_pressed.disconnect(_on_menu_button_pressed)


func _on_menu_button_pressed(idx: int):
	if idx == self.anim_menu_button.get_popup().item_count - 1:
		refactor_dialogue.popup_centered()

