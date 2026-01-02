extends Node
class_name LobbySystem
## Player Lobby Management
##
## This system handles create and join of multiplayer sessions
## It will keep track of player data during the lifespan of the game

## Emit when a player joins the game
signal player_connected(player: Player)
## Emit when a player leaves the game
signal player_disconnected(peer_id: int)
## Emit when the player list had changed
signal player_list_changed()
## Emit when all players have loaded
signal players_loaded()
## Emit when a player is_ready state changed
signal player_ready_state_changed(peer_id: int, is_ready: bool)
## Emit when the server
signal server_disconnected
## Emit when a player finished syncing
signal player_sync_changed()

const PORT: int = 7000
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS: int = 1

var _players: Array[Player]

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

## Create a game as the host
func create_game() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error != Error.OK:
		return error

	multiplayer.multiplayer_peer = peer
	_create_player(1)
	return Error.OK

## Join a host game
func join_game(address: String = "")-> Error:
	if address.is_empty():
		address = DEFAULT_SERVER_IP

	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: = peer.create_client(address, PORT)
	if error != Error.OK:
		return error
	
	multiplayer.multiplayer_peer = peer
	return Error.OK

## Getter for the local list of players
func get_players() -> Array[Player]:
	return _players

## Get the player index in the local list via the peer id
func find_player_index_by_id(in_peer_id: int) -> int:
	var index := _players.find_custom(func(player: Player): return player.get_peer_id() == in_peer_id)
	assert(index != -1)
	return index

## Get the player data in the local list via the peer id
func find_player_by_id(in_peer_id: int) -> Player:
	var index := find_player_index_by_id(in_peer_id)
	assert(_players[index] != null)
	return _players[index]

## To set all other peers syncing state to true
func set_players_syncing() -> void:
	if !multiplayer.is_server():
		return

	for player in _players:
		if multiplayer.get_unique_id() == player.get_peer_id():
			continue
		player.set_is_syncing(true)

## Check if all players have finished syncing
func has_players_finished_syncing() -> bool:
	if _players.size() <= 1:
		return false
	return _players.all(func(player: Player): return !player.is_syncing())

## Check if all player are ready
func can_start_game() -> bool:
	if _players.size() <= 1:
		return false
	return _players.all(func(player: Player): return player.is_ready())

## [color=Orange]RPC function[/color][br]
## Load a scene over the network
@rpc("call_local", "reliable")
func load_game(in_game_scene_path: String) -> void:
	get_tree().change_scene_to_file(in_game_scene_path)

## [color=Orange]RPC function[/color][br]
## Update the ready state of a player for all peers
@rpc("any_peer", "call_local", "reliable")
func player_ready() -> void:
	var player: Player = _get_player_by_sender_id()
	player.set_is_ready(!player.is_ready())
	player_ready_state_changed.emit(player.get_peer_id(), player.is_ready())

## [color=Orange]RPC function[/color][br]
## Update the loading state of a player for all peers
@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	_get_player_by_sender_id().set_has_loaded(true)
	if multiplayer.is_server() && _players.all(func(player: Player): return player.has_loaded()):
		players_loaded.emit()

## [color=Orange]RPC function[/color][br]
## Called by any player to update their syncing state to done
@rpc("any_peer", "call_remote", "reliable")
func sync_done() -> void:
	_get_player_by_sender_id().set_is_syncing(false)
	if multiplayer.is_server():
		player_sync_changed.emit()

@rpc("call_local", "reliable")
func _add_player(in_packed_data: PackedByteArray):
	var new_player: Player = Player.new()
	new_player.set_data_from_packet(in_packed_data)
	var index := _players.find_custom(func(player: Player): return player.get_peer_id() == new_player.get_peer_id())
	if index == -1:
		_players.append(new_player)
	else:
		_players[index] = new_player
	player_list_changed.emit()

func _on_peer_connected(id: int) -> void:
	if !multiplayer.is_server():
		return
	
	_create_player(id)
	for player in _players:
		assert(player != null)
		_add_player.rpc(player.get_packet())

func _on_peer_disconnected(id: int):
	_players.erase(find_player_by_id(id))
	player_disconnected.emit(id)

func _on_connected_to_server():
	pass

func _on_connection_fail():
	_remove_multiplayer_peer()

func _on_server_disconnected():
	_remove_multiplayer_peer()
	server_disconnected.emit()

func _create_player(in_peer_id: int):
	var player := Player.new()

	player.set_peer_id(in_peer_id)
	player.set_username("Player" + str(_players.size() + 1))
	if in_peer_id == 1:
		player.set_is_ready(true)

	_players.append(player)
	player_connected.emit(player)

func _get_player_by_sender_id() -> Player:
	var peer_id := multiplayer.get_remote_sender_id()
	return find_player_by_id(peer_id)

func _remove_multiplayer_peer() -> void:
	multiplayer.multiplayer_peer = null
	_players.clear()
