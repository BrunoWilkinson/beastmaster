extends Control

# Player options
@export var rounds_to_win := 3

var label: Label = null

var hit_system: HitSystem = null
var round_system: RoundSystem = null
var score_system: ScoreSystem = null

func _ready() -> void:
	hit_system = $Hit

	round_system = $Round
	round_system.setup(hit_system)
	round_system.state_changed.connect(on_round_state_changed)
	round_system.counter_changed.connect(on_round_counter_changed)

	score_system = $Score
	score_system.setup(hit_system)
	score_system.state_changed.connect(on_score_state_changed)
	
	for id in Lobby.players:
		score_system.register_player(id)
		hit_system.register_player(id)

	label = $Label
	on_round_state_changed(round_system.get_state())

	$RoundNumber.visible = false
	$Player1Score.text = "Player1 score: 0"
	$Player2Score.text = "Player2 score: 0"

	if multiplayer.is_server():
		Lobby.player_sync_changed.connect(_on_player_sync_changed)
		$Type.text = "Server"
	else:
		$Type.text = "Client"

	Lobby.player_loaded.rpc_id(1)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("hit") && round_system.get_state() == RoundSystem.State.BATTLE:
		_register_hit.rpc_id(1, round_system.get_timer())

func _on_player_sync_changed() -> void:
	print("Server waiting on player sync")
	if Lobby.has_players_finished_syncing():
		print("Server resuming")
		_set_round_state.rpc(RoundSystem.State.RESUME)

func start_game() -> void:
	if multiplayer.is_server():
		_set_round_state.rpc(RoundSystem.State.INTRO)

func on_round_state_changed(state: RoundSystem.State) -> void:
	print("on_round_state_changed: " + str(state) + " - id: " + str(multiplayer.get_unique_id()))
	if state == RoundSystem.State.INTRO:
		label.text = "INTRO"
		score_system.update_score()
		hit_system.reset()
		_round_intro()
	elif state == RoundSystem.State.BATTLE:
		label.text = "BATTLE"
	elif state == RoundSystem.State.WAITING:
		label.text = "WAITING"
	elif state == RoundSystem.State.END:
		label.text = "END"
		_round_over()

func on_score_state_changed(state: ScoreSystem.State) -> void:
	if state == ScoreSystem.State.WIN:
		for id in Lobby.players:
			var text: String = "Player" + str(id) + " score: " + str(score_system.get_player_score(id))
			print(text)
			if id == 1:
				$Player1Score.text = text
			else:
				$Player2Score.text = text
	if state == ScoreSystem.State.TIE:
		print("on_score_state_changed() - TIE")

func on_round_counter_changed(counter: int) -> void:
	if !$RoundNumber.visible:
		$RoundNumber.visible = true
	$RoundNumber.text = "Round " + str(counter)

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
	print("Hit registered - id: " + str(sender_id))
	hit_system.set_player_hit(sender_id, in_timing)

func _round_intro() -> void:
	if !multiplayer.is_server():
		return

	_set_round_state.rpc(RoundSystem.State.WAITING)
	Lobby.set_players_syncing()

	hit_system.generate_hit_timing()
	_sync_hit_timing.rpc(hit_system.get_hit_timing())

func _round_over() -> void:
	if !multiplayer.is_server():
		return

	_set_round_state.rpc(RoundSystem.State.WAITING)
	Lobby.set_players_syncing()

	_sync_players_hit_timing.rpc(hit_system.get_players_hit_timing())
