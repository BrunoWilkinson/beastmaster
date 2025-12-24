class_name HitSystem
extends Node
## Handles hit timings
##
## Allow to generate hit timing for the players,
## and store them to be used by other systems.[br]
## [br]
## Usage with node:
## [codeblock]
## hit_system: HitSystem = null
## func _ready():
##     hit_system = $Hit
##     # if we need to override the default values
##     hit_system.setup(1, 2)
##     # OR can be updated directly in the editor using the node in the scene
## [/codeblock]
## [br]
## Usage without node:
## [codeblock]
## hit_system: HitSystem = null
## func _ready():
##     hit_system = HitSystem.new()
##     # if we need to override the default values
##     hit_system.setup(1, 2)
## [/codeblock]

## Lowest value possible while generating the hit time
@export var min_timing := 0.5
## Highest value possible while generating the hit time
@export var max_timing := 1.5

## Emit a signal when all players have pressed the hit input
signal all_player_registered_hits()

var _hit_timing := 0.0
var _players_hit_timing: Dictionary[int, float]

## Used to override the default values [br]
## Can also be done via editor if using the node setup
func setup(in_min_timing: float, in_max_timing:float) -> void:
	min_timing = in_min_timing
	max_timing = in_max_timing

## Add multiple players to the score system, init value will be zero
func register_players(in_players_id: Array[int]) -> void:
	for id in in_players_id:
		register_player(id)

## Add a player to the score system, init value will be zero
func register_player(in_player_id: int) -> void:
	assert(_players_hit_timing.find_key(in_player_id) == null)
	_players_hit_timing.get_or_add(in_player_id, 0)
	if has_all_player_registered_hits():
		all_player_registered_hits.emit()

## Set the internal values to zero
func reset() -> void:
	_hit_timing = 0.0
	for player_id in _players_hit_timing:
		_players_hit_timing[player_id] = 0.0

## Setter for the player hit timing
func set_player_hit(in_player_id: int, in_player_hit_timing: float) -> void:
	_players_hit_timing[in_player_id] = in_player_hit_timing

## Getter for the player hit timing
func get_player_hit(in_player_id: int) -> float:
	return _players_hit_timing[in_player_id]

## Setter for the players hit timing value
func set_players_hit_timing(in_player_hit_timing: Dictionary[int, float]) -> void:
	_players_hit_timing = in_player_hit_timing

## Getter for the players hit timing value
func get_players_hit_timing() -> Dictionary[int, float]:
	return _players_hit_timing

## Generate a random hit timing based on the min and max
func generate_hit_timing() -> float:
	_hit_timing = randf_range(min_timing, max_timing)
	return _hit_timing

## Setter for the hit timing value
func set_hit_timing(in_hit_timing: float) -> void:
	_hit_timing = in_hit_timing

## Getter for the current generated hit timing
func get_hit_timing() -> float:
	return _hit_timing

## Check if all the player have a hit value registered
func has_all_player_registered_hits() -> bool:
	var result: bool = false
	for id in _players_hit_timing:
		result = _players_hit_timing[id] > 0.0
	return result

## Find the player id with the lowest hit timing (winner of the round) [br]
## Returns -1 if fails to found an id
func find_lowest_hit_id() -> int:
	var timings: Array[float] = _players_hit_timing.values().filter(func(timing): return timing != 0.0)
	timings.sort()
	var lowest_timing: float = timings[0]
	
	for id in _players_hit_timing:
		if _players_hit_timing[id] == lowest_timing:
			return id
	
	return -1

## Check if all players have the same hit timings
func is_tie() -> bool:
	var timings: Array[float] = _players_hit_timing.values()
	for timing in timings:
		var duplicates = timings.count(timing)
		if duplicates == timings.size():
			return true
	
	return false
