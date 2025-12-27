extends Resource
class_name ScoreSystem
## Score management
## 
## [color=Orange]Dependency:[/color] Requires [HitSystem] [br][br]
## Update the round state based on values given, 
## and emit those update to other systems.

## Ref to the hit system resource
@export var _hit_system: HitSystem = null

## Score State
enum State {
	## A player as won
	WIN,
	## Either no one has press or all players have the same timing
	TIE,
	## Default state
	NONE
}

## Emit when the score gets updated
signal state_changed(state: State)

var _players_score: Dictionary[int, int]

var _state: State = State.NONE
var _winner_id: int = -1

func _setup_local_to_scene() -> void:
	assert(_hit_system != null)

## Add multiple players to the score system, init value will be zero
func register_players(in_players_id: Array[int]) -> void:
	for id in in_players_id:
		register_player(id)

## Add a player to the score system, init value will be zero
func register_player(in_player_id: int) -> void:
	assert(_players_score.find_key(in_player_id) == null)
	_players_score.get_or_add(in_player_id, 0)

## Getter for the player score
func get_player_score(in_player_id: int) -> int:
	return _players_score[in_player_id]

## Getter for the winner player id
func get_winner_id() -> int:
	return _winner_id

## Compare hit timings and determine if it's a TIE or WIN [br]
## This func will emit the state_changed signal
func update_score() -> void:
	assert(_players_score.size() > 0)
	
	if _hit_system.is_tie():
		_update_state(State.TIE)
		return
	
	_winner_id = _hit_system.find_lowest_hit_id()
	_players_score[_winner_id] += 1
	_update_state(State.WIN)

func _update_state(in_state: State) -> void:
	_state = in_state
	state_changed.emit(_state)
