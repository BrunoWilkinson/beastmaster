extends Control

@export var _battle_scene: PackedScene = null
@export var _waiting_room_scene: PackedScene = null
@export var _lobbies_scene: PackedScene = null
@export var _create_lobby: PackedScene = null

var _play_vs_ai_button: Button = null
var _host_button: Button = null
var _join_button: Button = null
var _settings_button: Button = null
var _exit_button: Button = null

func _ready() -> void:
	assert(_battle_scene != null)
	assert(_waiting_room_scene != null)
	assert(_lobbies_scene != null)
	assert(_create_lobby != null)

	_play_vs_ai_button = $VBoxContainer/PlayVsAI
	assert(_play_vs_ai_button != null)
	_play_vs_ai_button.button_down.connect(_play_vs_ai_button_down)
	
	_host_button = $VBoxContainer/HostGame
	assert(_host_button != null)
	_host_button.button_down.connect(_host_game_button_down)
	
	_join_button = $VBoxContainer/JoinGame
	assert(_join_button != null)
	_join_button.button_down.connect(_join_game_button_down)
	
	_settings_button = $VBoxContainer/Settings
	assert(_settings_button != null)
	_settings_button.button_down.connect(_settings_button_down)
	
	_exit_button = $VBoxContainer/ExitGame
	assert(_exit_button != null)
	_exit_button.button_down.connect(_exit_game_button_down)

func _play_vs_ai_button_down() -> void:
	get_tree().change_scene_to_packed(_battle_scene)

func _host_game_button_down() -> void:
	if Lobby.is_enet_enabled():
		Lobby.create_game()
		get_tree().change_scene_to_packed(_waiting_room_scene)
	else:
		get_tree().change_scene_to_packed(_create_lobby)

func _join_game_button_down() -> void:
	if Lobby.is_enet_enabled():
		Lobby.join_game(-1)
		get_tree().change_scene_to_packed(_waiting_room_scene)
	else:
		get_tree().change_scene_to_packed(_lobbies_scene)

func _settings_button_down() -> void:
	pass

func _exit_game_button_down() -> void:
	get_tree().quit()
