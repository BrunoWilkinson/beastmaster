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
	## Round Introduction
	INTRO,
	## Round Battle
	BATTLE,
	## Round Ending
	END,
	## Pending state - Default
	WAITING
}

var _timer: float = 0.0
var _state: State = State.WAITING
var _hit_system: HitSystem = null

## Emit when the state has changed (requires an actual diff)
signal state_changed(state: State)

## [color=red]Critical:[/color] Mandatory to pass a ref to the hit timing system
func setup(in_hit_system: HitSystem) -> void:
	assert(_hit_system == null)
	_hit_system = in_hit_system

## Set values back to their init state [br] 
## [color=lightblue]Info:[/color] Expect for the [HitSystem] ref (it won't set to null)
func reset():
	_timer = 0.0
	_state = State.WAITING

## Getter for the current round state
func get_state() -> State:
	return _state

func get_timer() -> float:
	return _timer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _hit_system == null || _state == State.WAITING:
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
	
	_state = in_state
	state_changed.emit(_state)
