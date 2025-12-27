extends Node

# Player options
@export var rounds_to_win := 3

# Systems
var hit_system: HitSystem = null
var round_system: RoundSystem = null
var score_system: ScoreSystem = null

# Sprites
var player1: AnimatedSprite2D = null
var player2: AnimatedSprite2D = null

# HUD
var round_number: Label = null
var player1_score: Label = null
var player2_score: Label = null

# Debug Labels
var debug_round_state: Label = null
var debug_type: Label = null

func _ready() -> void:
	hit_system = $Hit
	assert(hit_system != null)

	round_system = $Round
	assert(round_system != null)
	round_system.setup(hit_system)
	round_system.state_changed.connect(on_round_state_changed)
	round_system.counter_changed.connect(on_round_counter_changed)

	score_system = $Score
	assert(score_system != null)
	score_system.setup(hit_system)
	score_system.state_changed.connect(on_score_state_changed)
	
	# register players into the systems
	for id in Lobby.players:
		score_system.register_player(id)
		hit_system.register_player(id)
	
	round_number = $HUD/RoundNumber
	round_number.visible = false
	
	player1_score = $HUD/Player1Score
	player1_score.text = "Player1 score: 0"
	
	player2_score = $HUD/Player2Score
	player2_score.text = "Player2 score: 0"
	
	player1 = $Player1
	assert(player1 != null)
	player2 = $Player2
	assert(player2 != null)
	
	debug_round_state = $HUD/RoundState
	assert(debug_round_state != null)
	debug_type = $HUD/Type
	assert(debug_type != null)

	on_round_state_changed(round_system.get_state())
	if multiplayer.is_server():
		Lobby.player_sync_changed.connect(_on_player_sync_changed)
		debug_type.text = "Server"
	else:
		debug_type.text = "Client"

	Lobby.player_loaded.rpc_id(1)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("hit") && round_system.get_state() == RoundSystem.State.BATTLE:
		_register_hit.rpc_id(1, round_system.get_timer().time_left)

func _on_player_sync_changed() -> void:
	if Lobby.has_players_finished_syncing():
		_set_round_state.rpc(RoundSystem.State.RESUME)

func start_game() -> void:
	if multiplayer.is_server():
		_set_round_state.rpc(RoundSystem.State.INTRO)

func on_round_state_changed(state: RoundSystem.State) -> void:
	
	if state == RoundSystem.State.INTRO:
		debug_round_state.text = "intro"
		score_system.update_score()
		hit_system.reset()
		_round_intro()
	elif state == RoundSystem.State.BATTLE:
		debug_round_state.text = "battle"
	elif state == RoundSystem.State.WAITING:
		debug_round_state.text = "waiting"
	elif state == RoundSystem.State.END:
		debug_round_state.text = "end"
		_round_over()
	elif state == RoundSystem.State.RESUME:
		debug_round_state.text = "resume"
	elif state == RoundSystem.State.WAITING:
		debug_round_state.text = "waiting"

func on_score_state_changed(state: ScoreSystem.State) -> void:
	if state == ScoreSystem.State.WIN:
		for id in Lobby.players:
			if id == 1:
				player1_score.text = _generate_score_text(id, 1)
			else:
				player2_score.text = _generate_score_text(id, 2)
	if state == ScoreSystem.State.TIE:
		## TODO: Update the UI scene nodes instead of printing
		print("on_score_state_changed() - TIE")

func on_round_counter_changed(counter: int) -> void:
	if !round_number.visible:
		round_number.visible = true
	round_number.text = "Round " + str(counter)

@rpc("call_local", "reliable")
func _set_round_state(in_round_state: RoundSystem.State) -> void:
	round_system.set_state(in_round_state)

@rpc("call_remote", "reliable")
func _sync_hit_timing(in_hit_timing: float) -> void:
	hit_system.set_hit_timing(in_hit_timing)
	Lobby.sync_done.rpc_id(1)

@rpc("call_remote", "reliable")
func _sync_players_hit_timing(in_players_hit_timing: Dictionary[int, float]) -> void:
	hit_system.set_players_hit_timing(in_players_hit_timing)
	Lobby.sync_done.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_timing: float) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	hit_system.set_player_hit(sender_id, in_timing)

func _round_intro() -> void:
	if !multiplayer.is_server():
		return

	_sync_players()
	hit_system.generate_hit_timing()
	_sync_hit_timing.rpc(hit_system.get_hit_timing())

func _round_over() -> void:
	if !multiplayer.is_server():
		return

	_sync_players()
	_sync_players_hit_timing.rpc(hit_system.get_players_hit_timing())

func _sync_players() -> void:
	_set_round_state.rpc(RoundSystem.State.WAITING)
	Lobby.set_players_syncing()

func _generate_score_text(in_player_id: int, in_player_number: int) -> String:
	return "Player" + str(in_player_number) + " score: " + str(score_system.get_player_score(in_player_id))
