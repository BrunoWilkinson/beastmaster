extends Control

# Design 
@export var round_intro_wait_time := 2.0
@export var round_end_wait_time := 4.0

# Player options
@export var rounds_to_win := 3

# Multiplayer State
var round_number := 0
var player1_score := 0
var player2_score := 0
var peer_id_winner := 0

var label: Label = null

var hit_system: HitSystem = null
var round_system: RoundSystem = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hit_system = $Hit

	round_system = $Round
	round_system.setup(hit_system)
	round_system.state_changed.connect(on_round_state_chaned)

	label = $Label
	label.text = "WAITING"

	$RoundNumber.text = "Round 1"
	$Player1Score.text = "Player1 score: " + str(player1_score)
	$Player2Score.text = "Player2 score: " + str(player2_score)

	Lobby.player_loaded.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("hit") && round_system.get_state() == RoundSystem.State.BATTLE:
		print("HIT!")
		_register_hit.rpc_id(1, round_system.get_timer())

func start_game() -> void:
	if multiplayer.is_server():
		_round_intro()

func on_round_state_chaned(state: RoundSystem.State) -> void:
	if state == RoundSystem.State.INTRO:
		label.text = "ROUND INTRO"
		_round_intro()
	elif state == RoundSystem.State.BATTLE:
		label.text = "BATTLE"
		_round_battle()
	elif state == RoundSystem.State.END:
		label.text = "ROUND END"
		_round_over()

@rpc("call_local", "reliable")
func _set_state(in_state: RoundSystem.State):
	pass

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
	round_system.reset()

@rpc("call_local", "reliable")
func _reset_player_hit_timing():
	hit_system.reset()

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_timing: float):
	var sender_id = multiplayer.get_remote_sender_id()
	print(str(sender_id))
	if sender_id == 1:
		hit_system.set_player_hit(0, in_timing)
	else:
		hit_system.set_player_hit(1, in_timing)

func _round_intro() -> void:
	if round_number != 0:
		_reset_timer.rpc()
		_reset_player_hit_timing.rpc()

	round_number += 1
	hit_system.generate_hit_timing()

	_set_round_number.rpc(round_number)
	#_set_state.rpc(state)

func _round_battle():
	_reset_timer.rpc()
	# _set_state.rpc(state)

func _round_over() -> void:
	# Smaller results wins
	if hit_system.get_player_hit(0) < hit_system.get_player_hit(1):
		player1_score += 1
		peer_id_winner = multiplayer.get_unique_id()
	elif hit_system.get_player_hit(0) > hit_system.get_player_hit(1):
		player2_score += 1
		peer_id_winner = Lobby.players.keys()[0]
	else:
		# TODO: handle a tie use case
		peer_id_winner = -1

	_reset_timer.rpc()
	_set_players_scores.rpc(player1_score, player2_score)
	# _set_state.rpc(state)
