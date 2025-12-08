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
##     hit_system.setup(1, 2, 4)
##     # OR can be updated directly in the editor using the node in the scene
## [/codeblock]
## [br]
## Usage without node:
## [codeblock]
## hit_system: HitSystem = null
## func _ready():
##     hit_system = HitSystem.new()
##     # if we need to override the default values
##     hit_system.setup(1, 2, 4)
## [/codeblock]

## Lowest value possible while generating the hit time
@export var min_timing := 0.5
## Highest value possible while generating the hit time
@export var max_timing := 1.5
## Allow to control the length of the internal array
@export var max_players := 2 

var _hit_timing := 0.0
var _players_hit_timing: Array[float] = [0.0, 0.0]

## Used to override the default values - can also be done via editor if using the node setup
func setup(in_min_timing: float, in_max_timing:float, in_max_players) -> void:
	min_timing = in_min_timing
	max_timing = in_max_timing
	max_players = in_max_players

## Set the internal values to zero
func reset() -> void:
	_hit_timing = 0.0
	_players_hit_timing = [0.0, 0.0]

## Setter for the player hit timing [br]
## [color=orange]WARNING:[/color] will assert if the index is above the max player value
func set_player_hit(index: int, in_player_hit_timing: float) -> void:
	assert(index >= max_players)
	_players_hit_timing[index] = in_player_hit_timing

## Getter for the player hit timing [br]
## [color=orange]WARNING:[/color] will assert if the index is above the max player value
func get_player_hit(index: int) -> float:
	assert(index >= max_players)
	return _players_hit_timing[index]

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
