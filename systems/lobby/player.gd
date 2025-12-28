extends Resource
class_name Player

var _username: String
var _is_ready: bool = false
var _has_loaded: bool = false
var _is_syncing: bool = false

func _init() -> void:
	_username = ""
	_is_ready = false
	_has_loaded = false
	_is_syncing = false

func set_username(in_username: String) -> void:
	_username = in_username

func get_username() -> String:
	return _username

func set_is_ready(in_is_ready: bool) -> void:
	_is_ready = in_is_ready

func is_ready() -> bool:
	return _is_ready

func set_has_loaded(in_has_loaded: bool) -> void:
	_has_loaded = in_has_loaded

func has_loaded() -> bool:
	return _has_loaded

func set_is_syncing(in_is_syncing: bool) -> void:
	_is_syncing = in_is_syncing

func is_syncing() -> bool:
	return _is_syncing
