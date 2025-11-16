extends Control

func _ready() -> void:
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)
	Lobby.player_list_set.connect(_on_player_list_set)
	_reset_ui()
	_on_player_list_set()
	
func _on_player_connected(peer_id: int, player_info: Dictionary[String, Variant]) -> void:
	_set_player_name(_get_player_label(peer_id), player_info["Name"])

func _on_player_disconnected(peer_id: int) -> void:
	_get_player_label(peer_id).hide()

func _on_server_disconnected() -> void:
	_reset_ui()

func _on_player_list_set():
	for peer_id in Lobby.players.keys():
		_set_player_name(_get_player_label(peer_id), Lobby.players[peer_id]["Name"])

func _set_player_name(label_node: Label, player_name: String) -> void:
	label_node.show()
	label_node.text = player_name

func _reset_ui() -> void:
	$PlayerOneLabel.hide()
	$PlayerTwoLabel.hide()

func _get_player_label(peer_id: int) -> Label:
	if peer_id != 1:
		return $PlayerTwoLabel

	return $PlayerOneLabel
