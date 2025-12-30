extends Control

var start_game_button: Button = null
var ready_button: Button = null
var player_one_label: Label = null
var player_two_label: Label = null
var player_two_ready_label: Label = null

func _ready() -> void:
	start_game_button = $ActionContainer/StartGameButton
	assert(start_game_button != null)
	ready_button = $ActionContainer/ReadyButton
	assert(ready_button != null)
	player_one_label = $PlayerOneLabel
	assert(player_one_label != null)
	player_two_label = $PlayerTwoLabel
	assert(player_two_label != null)
	player_two_ready_label = $PlayerTwoReadyLabel
	assert(player_two_ready_label != null)
	
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)
	Lobby.player_list_changed.connect(_on_player_list_set)
	Lobby.player_ready_state_changed.connect(_on_player_ready_state_changed)
	
	start_game_button.button_down.connect(_on_start_game_button_down)
	start_game_button.visible = multiplayer.is_server()
	start_game_button.disabled = !Lobby.can_start_game()
	
	ready_button.button_down.connect(_on_ready_button_down)
	ready_button.visible = !multiplayer.is_server()
	
	_reset_ui()
	_on_player_list_set()
	
func _on_player_connected(player: Player) -> void:
	_set_player_name(_get_player_label(player.get_peer_id()), player.get_username())

func _on_player_disconnected(peer_id: int) -> void:
	_get_player_label(peer_id).hide()

func _on_server_disconnected() -> void:
	_reset_ui()

func _on_player_list_set() -> void:
	for player in Lobby.get_players():
		_set_player_name(_get_player_label(player.get_peer_id()), player.get_username())

func _on_player_ready_state_changed(_in_player_id: int, _is_ready: bool) -> void:
	start_game_button.disabled = !Lobby.can_start_game()
	
	if Lobby.can_start_game():
		ready_button.text = String("UnReady")
		player_two_ready_label.visible = true
	else:
		ready_button.text = String("Ready")
		player_two_ready_label.visible = false

func _set_player_name(label_node: Label, player_name: String) -> void:
	label_node.show()
	label_node.text = player_name

func _reset_ui() -> void:
	player_one_label.hide()
	player_two_label.hide()
	player_two_ready_label.hide()

func _get_player_label(peer_id: int) -> Label:
	if peer_id != 1:
		return player_two_label

	return player_one_label

func _on_start_game_button_down() -> void:
	if !Lobby.can_start_game():
		return
	Lobby.load_game.rpc("res://scenes/p2p_battle.tscn")

func _on_ready_button_down() -> void:
	Lobby.player_ready.rpc()
