extends Control

# Design 
@export var round_intro_wait_time := 2.0
@export var round_end_wait_time := 4.0
@export var hit_min_timing := 0.5
@export var hit_max_timing := 1.5

# Player options
@export var rounds_to_win := 3

# Multiplayer State
var round_number := 0
var player1_score := 0
var player2_score := 0
var peer_id_winner := 0

var hit_timing := 0.0
var player1_hit_timing := 0.0
var player2_hit_timing := 0.0

enum State {
	ROUND_INTRO,
	ROUND_BATTLE,
	ROUND_END,
	WAITING
}
var label: Label = null
var state: State = State.WAITING
var timer := 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label = $Label
	label.text = "WAITING"
	
	$RoundNumber.text = "Round 1"
	$Player1Score.text = "Player1 score: " + str(player1_score)
	$Player2Score.text = "Player2 score: " + str(player2_score)
	
	Lobby.player_loaded.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state != State.WAITING:
		timer += delta

	if state == State.ROUND_INTRO:
		label.text = "ROUND INTRO"
	elif state == State.ROUND_BATTLE:
		label.text = "BATTLE"
	elif state == State.ROUND_END:
		label.text = "ROUND END"

	if state == State.ROUND_INTRO && timer >= round_intro_wait_time:
		if multiplayer.is_server():
			_round_battle()
	elif state == State.ROUND_BATTLE && (timer >= hit_timing || _has_all_player_registered_hits()):
		if multiplayer.is_server():
			_round_over()
	elif state == State.ROUND_END && timer >= round_end_wait_time:
		if multiplayer.is_server():
			_round_intro()

	if Input.is_action_just_pressed("hit") && state == State.ROUND_BATTLE:
		print("HIT!")
		_register_hit.rpc_id(1, timer)

func start_game() -> void:
	if multiplayer.is_server():
		_round_intro()

@rpc("call_local", "reliable")
func _set_state(in_state: State):
	state = in_state

@rpc("call_local", "reliable")
func _set_players_scores(in_player1_score: int, in_player2_score):
	player1_score = in_player1_score
	player2_score = in_player2_score
	$Player1Score.text = "Player1 score: " + str(player1_score)
	$Player2Score.text = "Player2 score: " + str(player2_score)

@rpc("call_local", "reliable")
func _set_round_number(in_round_number: int):
	round_number = in_round_number
	$RoundNumber.text = "Round " + str(round_number)

@rpc("call_local", "reliable")
func _reset_timer():
	timer = 0.0

@rpc("call_local", "reliable")
func _reset_player_hit_timing():
	player1_hit_timing = 0.0
	player2_hit_timing = 0.0

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_timing: float):
	var sender_id = multiplayer.get_remote_sender_id()
	print(str(sender_id))
	if sender_id == 1:
		player1_hit_timing = in_timing
	else:
		player2_hit_timing = in_timing

func _has_all_player_registered_hits() -> bool:
	return player1_hit_timing > 0.0 && player2_hit_timing > 0.0

func _round_intro() -> void:
	state = State.ROUND_INTRO
	if round_number != 0:
		_reset_timer.rpc()
		_reset_player_hit_timing.rpc()

	round_number += 1
	hit_timing = randf_range(hit_min_timing, hit_max_timing)

	_set_round_number.rpc(round_number)
	_set_state.rpc(state)

func _round_battle():
	state = State.ROUND_BATTLE
	_reset_timer.rpc()
	_set_state.rpc(state)

func _round_over() -> void:
	state = State.ROUND_END

	# Smaller results wins
	if player1_hit_timing < player2_hit_timing:
		player1_score += 1
		peer_id_winner = multiplayer.get_unique_id()
	elif player1_hit_timing > player2_hit_timing:
		player2_score += 1
		peer_id_winner = Lobby.players.keys()[0]
	else:
		# TODO: handle a tie use case
		peer_id_winner = -1

	_reset_timer.rpc()
	_set_players_scores.rpc(player1_score, player2_score)
	_set_state.rpc(state)
