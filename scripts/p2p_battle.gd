extends Control

@export var hit_min_timing := 2.0
@export var hit_max_timing := 6.0
@export var rounds_to_win := 3
@export var round_intro_duration := 2
@export var round_duration := 1.5
@export var round_end_duration := 4

# State shared across all peers
var battle_state: Dictionary = {
	"round_number": 0,
	"round_start_time": 0.0,
	"player1_score": 0,
	"player2_score": 0,
	"hit_timing": 0.0,
	"player1_hit_timing": 0.0,
	"player2_hit_timing": 0.0,
	"winner": 0
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_loaded.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var time_now := Time.get_unix_time_from_system()
	var round_start_time := time_now - battle_state["round_start_time"] as float
	
	if round_start_time > time_now:
		return

	if Input.is_action_just_pressed("hit"):
		_register_hit.rpc_id(1, time_now)
	
	if multiplayer.is_server():
		var has_players_registered_hit = battle_state["player1_hit_timing"] > 0 && battle_state["player2_hit_timing"] > 0
		var has_time_ran_out = false
		if has_players_registered_hit || has_time_ran_out:
			_round_over.rpc_id(1)

func start_game() -> void:
	_update_text.rpc()

@rpc("any_peer", "call_local", "reliable")
func _update_text() -> void:
	$Label.text = "All players has loaded and the game has started"

@rpc("authority", "call_local", "reliable")
func _sync_battle_state(in_battle_state: Dictionary):
	battle_state = in_battle_state

@rpc("any_peer", "call_local", "reliable")
func _register_hit(in_hit_timing: float) -> void:
	if multiplayer.is_server():
		battle_state["player1_hit_timing"] = in_hit_timing
	else:
		battle_state["player2_hit_timing"] = in_hit_timing

# Server function
@rpc("authority", "call_local", "reliable")
func _round_start() -> void:
	var is_first_round = battle_state["round_number"] == 0
	battle_state["round_number"] += 1
	battle_state["hit_timing"] = randf_range(hit_min_timing, hit_max_timing)

	if is_first_round:
		_sync_battle_state(battle_state)
	else:
		await get_tree().create_timer(round_intro_duration).timeout
		_sync_battle_state(battle_state)

@rpc("authority", "call_local", "reliable")
func _round_over() -> void:
	pass
