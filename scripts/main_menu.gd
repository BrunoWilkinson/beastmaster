extends Control

func _ready() -> void:
	$VBoxContainer/PlayVsAI.button_down.connect(_play_vs_ai_button_down)
	$VBoxContainer/HostGame.button_down.connect(_host_game_button_down)
	$VBoxContainer/JoinGame.button_down.connect(_join_game_button_down)
	$VBoxContainer/Settings.button_down.connect(_settings_button_down)
	$VBoxContainer/ExitGame.button_down.connect(_exit_game_button_down)
	
func _play_vs_ai_button_down() -> void:
	get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _host_game_button_down() -> void:
	Lobby.create_game()
	get_tree().change_scene_to_file("res://scenes/waiting_room.tscn")
	
func _join_game_button_down() -> void:
	Lobby.join_game()
	get_tree().change_scene_to_file("res://scenes/waiting_room.tscn")
	
func _settings_button_down() -> void:
	pass

func _exit_game_button_down() -> void:
	get_tree().quit()
