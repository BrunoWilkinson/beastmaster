extends Control

# Design 
@export var round_intro_wait_time := 2
@export var round_end_wait_time := 4
@export var hit_min_timing := 0.5
@export var hit_max_timing := 1.5

# Player options
@export var rounds_to_win := 3

class BattleState:
	var round_number := 0
	var player1_score := 0
	var player2_score := 0
	var peer_id_winner := 0
	var hit_timing := 0.0
	var player1_hit_timing := 0.0
	var player2_hit_timing := 0.0
	var round_start_time := 0.0

	func is_first_round() -> bool:
		return round_number == 0

	func has_all_player_registered_hits() -> bool:
		return player1_hit_timing > 0.0 && player2_hit_timing > 0.0

var state: BattleState = null
var round_intro_timer: Timer = null
var hit_max_timing_timer: Timer = null
var hit_timing_timer: Timer = null
var round_end_timer: Timer = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state = BattleState.new()

	round_intro_timer = $RoundIntroTimer
	round_intro_timer.set_wait_time(round_intro_wait_time)
	round_intro_timer.set_autostart(false)
	round_intro_timer.timeout.connect(_on_round_intro_timeout)

	hit_max_timing_timer = $HitMaxTimingTimer
	hit_max_timing_timer.set_wait_time(hit_max_timing)
	hit_max_timing_timer.set_autostart(false)
	hit_max_timing_timer.timeout.connect(_on_hit_max_timing_timeout)

	hit_timing_timer = $HitTimingTimer
	hit_timing_timer.autostart = false
	hit_timing_timer.timeout.connect(_on_hit_timing_timeout)

	round_end_timer = $RoundEndTimer
	round_end_timer.set_wait_time(round_end_wait_time)
	round_end_timer.set_autostart(false)
	round_end_timer.timeout.connect(_on_round_end_timeout)

	Lobby.player_loaded.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("hit") && !hit_timing_timer.has_stopped():
		hit_timing_timer.set_paused(true)
		_register_hit.rpc_id(1, hit_timing_timer.get_time_left())
	
	if multiplayer.is_server() && state.has_all_player_registered_hits():
		hit_max_timing_timer.set_paused(true)
		_round_over.rpc_id(1)

func _on_round_intro_timeout() -> void:
	hit_max_timing_timer.start()
	hit_timing_timer.start()

func _on_hit_max_timing_timeout() -> void:
	if !multiplayer.is_server():
		return
		
	if !round_end_timer.is_stopped():
		return
	
	_round_over.rpc_id(1)

func _on_hit_timing_timeout() -> void:
	pass

func _on_round_end_timeout() -> void:
	if state.peer_id_winner == 0:
		return

	if !multiplayer.is_server():
		return

	if state.player1_score > rounds_to_win:
		_update_text.rpc("Round Winner is " + Lobby.players.find_key(Lobby.players.keys()[0])["Name"])
	elif state.player2_score > rounds_to_win:
		_update_text.rpc("Round Winner is " + Lobby.players.find_key(Lobby.players.keys()[1])["Name"])
	else:
		if state.peer_id_winner == -1:
			_update_text.rpc("It's a tie!")
		else:
			_update_text.rpc("Round Winner is " + Lobby.players.find_key(state.peer_id_winner)["Name"])
		_round_start()

func start_game() -> void:
	if multiplayer.is_server():
		_round_start()

@rpc("any_peer", "call_local", "reliable")
func _update_text(in_text: String) -> void:
	$Label.text = in_text

@rpc("authority", "call_local", "reliable")
func _sync_battle_state(in_battle_state: BattleState):
	state = in_battle_state

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_hit_timing: float) -> void:
	if multiplayer.is_server():
		state.player1_hit_timing = in_hit_timing
	else:
		state.player2_hit_timing = in_hit_timing

func _round_start() -> void:
	round_intro_timer.start()
	
	if state.is_first_round():
		await round_intro_timer.timeout

	state.round_number += 1
	state.hit_timing = randf_range(hit_min_timing, hit_max_timing)
	_sync_battle_state.rpc(state)	

func _round_over() -> void:
	var player1_result = abs(state.player1_hit_timing - state.hit_timing)
	var player2_result = abs(state.player2_hit_timing - state.hit_timing)

	# Smaller results wins
	if player1_result < player2_result:
		state.player1_score += 1
		state.peer_id_winner = multiplayer.get_unique_id()
	elif player1_result > player2_result:
		state.player2_score += 1
		state.peer_id_winner = Lobby.players.keys()[0]
	else:
		# TODO: handle a tie use case
		state.peer_id_winner = -1

	_sync_battle_state.rpc(state)
