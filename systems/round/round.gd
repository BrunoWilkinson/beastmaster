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

var _state: State = State.WAITING
var _wait_state: State = State.WAITING
var _counter := 0

var _hit_system: HitSystem = null
var _timer: Timer = null

## [color=red]Critical:[/color] Mandatory to pass a ref to the hit timing system
func setup(in_hit_system: HitSystem) -> void:
	assert(_hit_system == null)
	_hit_system = in_hit_system
	_hit_system.all_player_registered_hits.connect(_on_all_player_registered_hits)
	
	_timer = Timer.new()
	_timer.set_one_shot(true)
	_timer.timeout.connect(_on_timeout)
	get_parent().add_child(_timer)

## Set values back to their init state [br] 
## [color=lightblue]Info:[/color] Expect for the [HitSystem] ref (it won't set to null)
func reset():
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
func get_timer() -> Timer:
	return _timer

## Getter for the current round number
func get_counter() -> int:
	return _counter

func _on_timeout() -> void:
	assert(_hit_system != null)

	if _state == State.INTRO:
		_update_state(State.BATTLE)
	elif _state == State.BATTLE:
		_update_state(State.END)
	elif _state == State.END:
		_update_state(State.INTRO)

func _on_all_player_registered_hits() -> void:
	if _state == State.BATTLE:
		_update_state(State.END)

func _update_state(in_state: State) -> void:
	assert(_timer != null)

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

	if _state == State.INTRO:
		_timer.set_wait_time(intro_duration)
		_counter += 1
		counter_changed.emit(_counter)
	elif _state == State.BATTLE:
		_timer.set_wait_time(_hit_system.get_hit_timing())
	elif _state == State.END:
		_timer.set_wait_time(end_duration)

	_timer.start()
	state_changed.emit(_state)
