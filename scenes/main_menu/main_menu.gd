extends Control

@export var battle_scene: PackedScene = null
@export var waiting_room_scene: PackedScene = null

var play_vs_ai_button: Button = null
var host_button: Button = null
var join_button: Button = null
var settings_button: Button = null
var exit_button: Button = null

func _ready() -> void:
	play_vs_ai_button = $VBoxContainer/PlayVsAI
	assert(play_vs_ai_button != null)
	play_vs_ai_button.button_down.connect(_play_vs_ai_button_down)
	
	host_button = $VBoxContainer/HostGame
	assert(host_button != null)
	host_button.button_down.connect(_host_game_button_down)
	
	join_button = $VBoxContainer/JoinGame
	assert(join_button != null)
	join_button.button_down.connect(_join_game_button_down)
	
	settings_button = $VBoxContainer/Settings
	assert(settings_button != null)
	settings_button.button_down.connect(_settings_button_down)
	
	exit_button = $VBoxContainer/ExitGame
	assert(exit_button != null)
	exit_button.button_down.connect(_exit_game_button_down)
	
	assert(battle_scene != null)
	assert(waiting_room_scene != null)

func _play_vs_ai_button_down() -> void:
	get_tree().change_scene_to_packed(battle_scene)

func _host_game_button_down() -> void:
	Lobby.create_game()
	get_tree().change_scene_to_packed(waiting_room_scene)

func _join_game_button_down() -> void:
	Lobby.join_game()
	get_tree().change_scene_to_packed(waiting_room_scene)

func _settings_button_down() -> void:
	pass

func _exit_game_button_down() -> void:
	get_tree().quit()
