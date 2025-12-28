extends Node
class_name LobbySystem
## Player Lobby Management
##
## This system handles create and join of multiplayer sessions
## It will keep track of player data during the lifespan of the game

## Emit when a player joins the host
signal player_connected(peer_id: int, player_info: Player)
## Emit when a player leaves the host game
signal player_disconnected(peer_id: int)
## Emit when a player is_ready state changed
signal player_ready_state_changed(peer_id: int, is_ready: bool)
## Emit when the host updates the player list
signal player_list_set()
## Emit when the server
signal server_disconnected
## Emit when a player finished syncing
signal player_sync_changed()

const PORT: int = 7000
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS: int = 1

var _players: Dictionary[int, Player]
var _player_info: Player = null

func _ready() -> void:
	_player_info = Player.new()
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func get_players() -> Dictionary[int, Player]:
	return _players

func join_game(address: String = "")-> Error:
	if address.is_empty():
		address = DEFAULT_SERVER_IP

	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: = peer.create_client(address, PORT)
	if error != Error.OK:
		return error
	
	multiplayer.multiplayer_peer = peer
	return Error.OK

func create_game() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != Error.OK:
		return error
	multiplayer.multiplayer_peer = peer
	_player_info.set_is_ready(true)
	_add_player(1, _player_info)
	return Error.OK

func remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null
	_players.clear()

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path: String) -> void:
	get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_ready() -> void:
	if !multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	var player: Player = _players[peer_id]
	player.set_is_ready(!player.is_ready())
	_set_players.rpc(_players)
	
func can_start_game() -> bool:
	var result := false
	if _players.size() <= 1:
		return result
	for player: Player in _players.values():
		result = player.is_ready()
	return result
	
# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	if !multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_players[peer_id].set_has_loaded(true)
	var players_loaded: int = 0
	for player: Player in _players.values():
		if player.has_loaded():
			players_loaded += 1
	if players_loaded == _players.size():
		$/root/Game.start_game()

@rpc("any_peer", "call_remote", "reliable")
func sync_done() -> void:
	if !multiplayer.is_server():
		return
	var peer_id := multiplayer.get_remote_sender_id()
	_players[peer_id].set_is_syncing(false)
	player_sync_changed.emit()

func set_players_syncing() -> void:
	for id in _players:
		if multiplayer.get_unique_id() == id:
			continue
		_players[id].set_is_syncing(true)

func has_players_finished_syncing() -> bool:
	var result := false
	if _players.size() <= 1:
		return result
	for player: Player in _players.values():
		result = !player.is_syncing()
	return result

@rpc("call_local", "reliable")
func _set_players(in_packed_data: PackedByteArray):
	var packed_data := in_packed_data.decompress(100)
	var in_players: Dictionary[int, Player] = packed_data.decode_var(0, true)
	_players.merge(in_players)
	player_list_set.emit()

func _update_players() -> void:
	var packed_data: PackedByteArray
	packed_data.encode_var(0, _players, true)
	packed_data.compress()
	_set_players.rpc(packed_data)

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(id: int) -> void:
	if !multiplayer.is_server():
		return
	_add_player(id, _player_info)
	var packed_data: PackedByteArray
	packed_data.encode_var(0, _players, true)
	_set_players.rpc(packed_data)

func _on_peer_disconnected(id: int):
	_players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	pass

func _on_connection_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	_players.clear()
	server_disconnected.emit()
	
func _add_player(in_player_id: int, in_player_info: Player):
	in_player_info.set_username("Player" + str(_players.size() + 1))
	_players[in_player_id] = in_player_info
	player_connected.emit(in_player_id, in_player_info)
