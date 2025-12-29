extends Resource
class_name Player
## Player
##
## This resource is meant to store all the data relevant to a player
## Also has helper function to convert the data into byte for RPCs

var _peer_id: int = -1
var _username: String = ""
var _is_ready: bool = false
var _has_loaded: bool = false
var _is_syncing: bool = false

func _init() -> void:
	_peer_id = -1
	_username = ""
	_is_ready = false
	_has_loaded = false
	_is_syncing = false

## Transform the player object into byte array
func get_packet() -> PackedByteArray:
	return var_to_bytes([
		_peer_id,
		_username,
		_is_ready,
		_has_loaded,
		_is_syncing
	])

## Set the data from a byte array
func set_data_from_packet(in_packed_data: PackedByteArray) -> void:
	var unpacked_data: Array[Variant] = bytes_to_var(in_packed_data)
	_peer_id = unpacked_data[0]
	_username = unpacked_data[1]
	_is_ready = unpacked_data[2]
	_has_loaded = unpacked_data[3]
	_is_syncing = unpacked_data[4]

## Setter for the peer id
func set_peer_id(in_peer_id) -> void:
	_peer_id = in_peer_id

## Getter for the peer id
func get_peer_id() -> int:
	return _peer_id

## Setter for the username
func set_username(in_username: String) -> void:
	_username = in_username

## Getter for the username
func get_username() -> String:
	return _username

## Setter for the ready state
func set_is_ready(in_is_ready: bool) -> void:
	_is_ready = in_is_ready

## Getter for the ready state
func is_ready() -> bool:
	return _is_ready

## Setter for the loaded state
func set_has_loaded(in_has_loaded: bool) -> void:
	_has_loaded = in_has_loaded

## Getter for the loaded state
func has_loaded() -> bool:
	return _has_loaded

## Setter for the syncing state
func set_is_syncing(in_is_syncing: bool) -> void:
	_is_syncing = in_is_syncing

## Getter for the syncing state
func is_syncing() -> bool:
	return _is_syncing
