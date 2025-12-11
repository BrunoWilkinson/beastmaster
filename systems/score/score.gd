class_name ScoreSystem
extends Node
## Score management
## 
## [color=Orange]Dependency:[/color] Requires [HitSystem] [br][br]
## Update the round state based on values given, 
## and emit those update to other systems.[br]
## [br]
## Usage with node:
## [codeblock]
## score_system: ScoreSystem = null
## func _ready():
##     score_system = $Score
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]
## [br]
## Usage without node:
## [codeblock]
## score_system: ScoreSystem = null
## func _ready():
##     round_system = ScoreSystem.new()
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]

var _players_score: Dictionary[int, int]
var _winner_id: int = 0
var _hit_system: HitSystem = null

## [color=red]Critical:[/color] Mandatory to pass a ref to the hit timing system
func setup(in_hit_system: HitSystem) -> void:
	assert(_hit_system != null)
	_hit_system = in_hit_system

## Set the internal winner id back to init value which is zero
func winner_reset() -> void:
	_winner_id = 0;

## Getter for the winner id
func get_winner_id() -> int:
	return _winner_id

## Add multiple players to the score system, init value will be zero
func register_players(in_players_id: Array[int]) -> void:
	for id in in_players_id:
		register_player(id)

## Add a player to the score system, init value will be zero
func register_player(in_player_id: int) -> void:
	assert(_players_score.find_key(in_player_id) != null)
	_players_score.get_or_add(in_player_id, 0)

## Getter for the player score
func get_player_score(in_player_id: int) -> int:
	return _players_score[in_player_id]

## Compare hit timings and determine the winner to increment the score by 1
func increment_winner_score() -> void:
	winner_reset()
	for id in _players_score.keys():
		if _winner_id == id:
			continue
		
		if _hit_system.get_player_hit(_winner_id) > _hit_system.get_player_hit(id):
			_winner_id = id
	
	_players_score[_winner_id] += 1
