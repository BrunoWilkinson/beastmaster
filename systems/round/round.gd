class_name RoundSystem
extends Node
## Round management
##
## [color=Orange]Dependency:[/color] Requires [HitSystem] [br][br]
## Update the round state based on values given, 
## and emit those update to other systems.[br]
## [br]
## Usage with node:
## [codeblock]
## round_system: RoundSystem = null
## func _ready():
##     round_system = $RoundSystem
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]
## [br]
## Usage without node:
## [codeblock]
## hit_system: HitSystem = null
## func _ready():
##     round_system = HitSystem.new()
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]

## How long the round intro will last
@export var intro_duration := 2.0
## How long the round end will last
@export var end_duration := 4.0

## Round State
enum State {
	## Set player score and increment round
	INTRO,
	## Player can register hits
	BATTLE,
	## Figure out the winner
	END,
	## Resume from state before waiting
	RESUME,
	## Waiting for the clients - Default
	WAITING
}

## Emit when the state has changed (requires an actual diff)
signal state_changed(state: State)
signal counter_changed(counter: int)

var _timer: float = 0.0
var _state: State = State.WAITING
var _wait_state: State = State.WAITING
var _counter := 0

var _hit_system: HitSystem = null

## [color=red]Critical:[/color] Mandatory to pass a ref to the hit timing system
func setup(in_hit_system: HitSystem) -> void:
	assert(_hit_system == null)
	_hit_system = in_hit_system

## Set values back to their init state [br] 
## [color=lightblue]Info:[/color] Expect for the [HitSystem] ref (it won't set to null)
func reset():
	_timer = 0.0
	_state = State.WAITING
	_wait_state = State.WAITING

## Getter to prev state
func get_wait_state() -> State:
	return _wait_state

## Setter to override the current state
func set_state(in_state: State) -> void:
	_update_state(in_state)

## Getter for the current round state
func get_state() -> State:
	return _state

## Getter for the current round timer
func get_timer() -> float:
	return _timer

## Getter for the current round number
func get_counter() -> int:
	return _counter

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	assert(_hit_system != null)
	if _state == State.WAITING || _state == State.RESUME:
		return

	_timer += delta

	if _state == State.INTRO && _timer >= intro_duration:
		_update_state(State.BATTLE)
	elif _state == State.BATTLE && (_timer >= _hit_system.get_hit_timing() || _hit_system.has_all_player_registered_hits()):
		_update_state(State.END)
	elif _state == State.END && _timer >= end_duration:
		_update_state(State.INTRO)

func _update_state(in_state: State) -> void:
	if (_state == in_state):
		return

	if in_state == State.WAITING:
		_wait_state = _state
		_state = in_state
		return

	if in_state == State.RESUME:
		_state = _wait_state
		_wait_state = State.WAITING
		return

	_state = in_state
	_timer = 0
	
	if _state == State.INTRO:
		_counter += 1
		counter_changed.emit(_counter)

	state_changed.emit(_state)
