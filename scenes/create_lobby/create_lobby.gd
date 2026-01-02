extends Node

@export var _waiting_room_scene: PackedScene = null

var _lobby_name_line_edit: LineEdit = null
var _create_button: Button = null

func _ready() -> void:
	assert(_waiting_room_scene != null)
	
	_lobby_name_line_edit = $VBoxContainer/LobbyName
	assert(_lobby_name_line_edit != null)
	
	_create_button = $Create
	assert(_create_button != null)
	
	_create_button.button_down.connect(_on_create_button_down)

func _on_create_button_down() -> void:
	Lobby.create_lobby_with_host(_lobby_name_line_edit.text)
	get_tree().change_scene_to_packed(_waiting_room_scene)
