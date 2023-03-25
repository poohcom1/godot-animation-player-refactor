@tool
extends EditorPlugin

const RefactorDialogueScene := preload("scenes/refactor_dialogue/refactor_dialogue.tscn")
const RefactorDialogue := preload("scenes/refactor_dialogue/refactor_dialogue.gd")

const AnimPlayerInspectorButton := preload("scenes/inspector_button/inspector_button.gd")

var activate_button: AnimPlayerInspectorButton
var refactor_dialogue: RefactorDialogue

var anim_menu_button: MenuButton

func _enter_tree() -> void:
	# Create dialogue
	refactor_dialogue = RefactorDialogueScene.instantiate()
	get_editor_interface().get_base_control().add_child(refactor_dialogue)
	refactor_dialogue.init(self)
	# Create menu button
	add_refactor_option(func(): 
		refactor_dialogue.popup_centered()
		refactor_dialogue.reset_size()
	)

func _exit_tree() -> void:
	if refactor_dialogue and refactor_dialogue.is_inside_tree():
		get_editor_interface().get_base_control().remove_child(refactor_dialogue)
		refactor_dialogue.queue_free()

	remove_refactor_option()

# Plugin buttons
func add_refactor_option(on_pressed: Callable):
	var base_control := get_editor_interface().get_base_control()
	anim_menu_button = _find_menu_button(base_control)
	anim_menu_button.get_popup().add_separator()
	anim_menu_button.get_popup().add_icon_item(
		base_control.get_theme_icon(&"Reload", &"EditorIcons"), "Refactor"
	)
	anim_menu_button.get_popup().index_pressed.connect(_on_menu_button_pressed)


func remove_refactor_option():
	var base_control := get_editor_interface().get_base_control()
	
	var item_count := anim_menu_button.get_popup().item_count
	anim_menu_button.get_popup().remove_item(item_count - 1) # Item
	anim_menu_button.get_popup().remove_item(item_count - 2) # Separator

	anim_menu_button.get_popup().index_pressed.disconnect(_on_menu_button_pressed)


func _on_menu_button_pressed(idx: int):
	if idx == self.anim_menu_button.get_popup().item_count - 1:
		refactor_dialogue.popup_centered()


var _anim_menu_button_cache: MenuButton
func _find_menu_button(node: Node) -> MenuButton:
	if _anim_menu_button_cache:
		return _anim_menu_button_cache
	
	if node is MenuButton and node.text == "Animation":
		_anim_menu_button_cache = node
		return node
	
	for child in node.get_children():
		var menu_button = _find_menu_button(child)
		if menu_button:
			return menu_button
		
	return null
