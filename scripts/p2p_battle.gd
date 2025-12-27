extends Node

# Player options
@export var rounds_to_win := 3

# Systems
@export var hit_system: HitSystem = null
@export var score_system: ScoreSystem = null
var round_system: RoundSystem = null

# Sprites
var player1: AnimatedSprite2D = null
var player2: AnimatedSprite2D = null

# Sound
var hit_sound: AudioStreamPlayer = null

# HUD
var round_number: Label = null
var player1_score: Label = null
var player2_score: Label = null
var hit_indicator: ColorRect = null

# Debug Labels
var debug_round_state: Label = null
var debug_type: Label = null

func _ready() -> void:
	assert(hit_system != null)
	assert(score_system != null)
	
	round_system = $Round
	assert(round_system != null)
	
	round_system.state_changed.connect(on_round_state_changed)
	round_system.counter_changed.connect(on_round_counter_changed)
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
	
	hit_indicator = $HUD/HitIndicator
	assert(hit_indicator != null)
	hit_indicator.visible = false

	hit_sound = $HitSound
	assert(hit_sound != null)

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
		if round_system.get_state() == RoundSystem.State.END:
			score_system.update_score()

func start_game() -> void:
	if multiplayer.is_server():
		_set_round_state.rpc(RoundSystem.State.INTRO)

func on_round_state_changed(state: RoundSystem.State) -> void:
	if state == RoundSystem.State.INTRO:
		hit_indicator.visible = false
		debug_round_state.text = "intro"
		hit_system.reset()
		_round_intro()
	elif state == RoundSystem.State.BATTLE:
		hit_indicator.visible = true
		hit_sound.play()
		debug_round_state.text = "battle"
	elif state == RoundSystem.State.WAITING:
		hit_indicator.visible = false
		debug_round_state.text = "waiting"
	elif state == RoundSystem.State.END:
		hit_indicator.visible = false
		debug_round_state.text = "end"
		_round_over()

func on_score_state_changed(state: ScoreSystem.State) -> void:
	if state == ScoreSystem.State.WIN:
		var winner_id := score_system.get_winner_id()
		if winner_id == 1:
			player1_score.text = "Player1 score: " + str(score_system.get_player_score(winner_id))
			player2.play("death")
		else:
			player2_score.text = "Player2 score: " + str(score_system.get_player_score(winner_id))
			player1.play("death")
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
	score_system.update_score()
	Lobby.sync_done.rpc_id(1)

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_timing: float) -> void:
	var sender_id = multiplayer.get_remote_sender_id()
	hit_system.set_player_hit(sender_id, in_timing)

func _round_intro() -> void:
	player1.play("idle")
	player2.play("idle")
	
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
