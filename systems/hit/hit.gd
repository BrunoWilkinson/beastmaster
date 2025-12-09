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

var _hit_timing := 0.0
var _players_hit_timing: Dictionary[int, float]

## Used to override the default values - can also be done via editor if using the node setup
func setup(in_min_timing: float, in_max_timing:float) -> void:
	min_timing = in_min_timing
	max_timing = in_max_timing

## Set the internal values to zero
func reset() -> void:
	_hit_timing = 0.0
	for player_id in _players_hit_timing:
		_players_hit_timing[player_id] = 0.0

## Setter for the player hit timing [br]
func set_player_hit(in_player_id: int, in_player_hit_timing: float) -> void:
	_players_hit_timing[in_player_id] = in_player_hit_timing

## Getter for the player hit timing [br]
func get_player_hit(in_player_id: int) -> float:
	return _players_hit_timing[in_player_id]

## Generate a random hit timing based on the min and max
func generate_hit_timing() -> float:
	_hit_timing = randf_range(min_timing, max_timing)
	return _hit_timing

## Getter for the current generated hit timing
func get_hit_timing() -> float:
	return _hit_timing

## Check if all the player have a hit value registered
func has_all_player_registered_hits() -> bool:
	var result: bool = false
	for hit in _players_hit_timing:
		result = hit > 0.0
	return result
