extends Control

# Design 
@export var round_intro_wait_time := 2.0
@export var round_end_wait_time := 4.0

# Player options
@export var rounds_to_win := 3

# Multiplayer State
var peer_id_winner := 0

var label: Label = null

var hit_system: HitSystem = null
var round_system: RoundSystem = null
var score_system: ScoreSystem = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	hit_system = $Hit

	round_system = $Round
	round_system.setup(hit_system)
	round_system.state_changed.connect(on_round_state_chaned)
	round_system.counter_changed.connect(on_round_counter_changed)

	score_system = $Score
	score_system.setup(hit_system)
	
	for id in Lobby.players.keys():
		score_system.register_player(id)

	label = $Label
	label.text = "WAITING"

	$RoundNumber.text = "Round 1"
	$Player1Score.text = "Player1 score: 0"
	$Player2Score.text = "Player2 score: 0"

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

func on_round_counter_changed(counter: int) -> void:
	_set_round_counter.rpc(counter)

@rpc("call_local", "reliable")
func _set_state(in_state: RoundSystem.State):
	pass

@rpc("call_local", "reliable")
func _set_players_scores(in_player1_score: int, in_player2_score):
	pass

@rpc("call_local", "reliable")
func _set_round_counter(in_round_counter: int):
	$RoundNumber.text = "Round " + str(in_round_counter)

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
	if round_system.get_counter() != 0:
		_reset_timer.rpc()
		_reset_player_hit_timing.rpc()

	hit_system.generate_hit_timing()

	_set_round_counter.rpc(round_system.get_counter())
	#_set_state.rpc(state)

func _round_battle():
	_reset_timer.rpc()
	# _set_state.rpc(state)

func _round_over() -> void:
	score_system.increment_winner_score()
	
	for id in Lobby.players.keys():
		var text: String = "Player" + str(id) + " score: " + str(score_system.get_player_score(id))
		if id == 1:
			$Player1Score.text = text
		else:
			$Player2Score.text = text
	
	_reset_timer.rpc()
	#_set_players_scores.rpc(player1_score, player2_score)
	# _set_state.rpc(state)
