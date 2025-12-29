extends Control

func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)
	Lobby.player_list_changed.connect(_on_player_list_set)
	Lobby.player_ready_state_changed.connect(_on_player_ready_state_changed)
	$ActionContainer/StartGameButton.button_down.connect(_on_start_game_button_down)
	$ActionContainer/StartGameButton.visible = multiplayer.is_server()
	$ActionContainer/StartGameButton.disabled = !Lobby.can_start_game()
	$ActionContainer/ReadyButton.button_down.connect(_on_ready_button_down)
	$ActionContainer/ReadyButton.visible = !multiplayer.is_server()
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
	$ActionContainer/StartGameButton.disabled = !Lobby.can_start_game()
	
	if Lobby.can_start_game():
		$ActionContainer/ReadyButton.text = String("UnReady")
		$PlayerTwoReadyLabel.visible = true
	else:
		$ActionContainer/ReadyButton.text = String("Ready")
		$PlayerTwoReadyLabel.visible = false

func _set_player_name(label_node: Label, player_name: String) -> void:
	label_node.show()
	label_node.text = player_name

func _reset_ui() -> void:
	$PlayerOneLabel.hide()
	$PlayerTwoLabel.hide()
	$PlayerTwoReadyLabel.hide()

func _get_player_label(peer_id: int) -> Label:
	if peer_id != 1:
		return $PlayerTwoLabel

	return $PlayerOneLabel

func _on_start_game_button_down() -> void:
	if !Lobby.can_start_game():
		return
	Lobby.load_game.rpc("res://scenes/p2p_battle.tscn")

func _on_ready_button_down() -> void:
	Lobby.player_ready.rpc()
