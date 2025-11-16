extends Node
# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id: int, player_info: Dictionary[String, Variant])
signal player_disconnected(peer_id: int)
signal player_list_set()
signal server_disconnected

const PORT: int = 7000
const DEFAULT_SERVER_IP: String = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS: int = 1

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players: Dictionary[int, Dictionary] = {}

# This is the local player info. This should be modified locally
var local_player_info: Dictionary[String, Variant] = {
	"Name": "Player",
	"IsReady": false,
	"HasLoaded": false
}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

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
	_create_player(1, local_player_info)
	return Error.OK

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()

# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path: String) -> void:
	get_tree().change_scene_to_file(game_scene_path)

@rpc("any_peer", "call_local", "reliable")
func player_ready():
	if !multiplayer.is_server():
		return
	
	var peer_id := multiplayer.get_remote_sender_id()
	players[peer_id]["IsReady"] = !players[peer_id]["IsReady"]
	
	_set_players(players)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded() -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	players[peer_id]["HasLoaded"] = true
	
	if !multiplayer.is_server():
		return
	
	_set_players(players)
	
	var players_loaded: int = 0
	for key in players.keys():
		if players[key]["HasLoaded"]:
			players_loaded += 1
	
	if players_loaded == players.size():
		$/root/Game.start_game()
		players_loaded = 0
		
@rpc("call_local", "reliable")
func _set_players(in_players: Dictionary[int, Dictionary]):
	players = in_players
	player_list_set.emit()

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_peer_connected(id: int) -> void:
	if !multiplayer.is_server():
		return
	
	var player_info: Dictionary[String, Variant] = {
		"Name": "Player"
	}	
	_create_player(id, player_info)
	_set_players.rpc(players)

func _on_peer_disconnected(id: int):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	pass

func _on_connection_fail():
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	
func _create_player(in_player_id: int, in_player_info: Dictionary[String, Variant]):
	in_player_info["Name"] += " " + str(in_player_id)
	players[in_player_id] = in_player_info
	player_connected.emit(in_player_id, in_player_info)
