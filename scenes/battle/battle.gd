extends Node2D

enum AIDifficulty { EASY, NORMAL, HARD }

@export_category("Debug")
@export var debug_show_elapsed_time = false

@export_category("Battle AI Difficulty")
@export var easy_hit_time := 2.0
@export var normal_hit_time := 1.5
@export var hard_hit_time := 1.0
@export var select_ai_diffculty = AIDifficulty.EASY

@export_category("Battle Rules")
@export var start_battle_time := 3.0
@export var hit_min_duration := 1.0
@export var hit_max_duration := 3.0
@export var max_round := 3
@export var best_of_rounds := 2

@export_category("UI settings")
@export var normal_font_size = 32
@export var large_font_size = 48
@export var label_show_time = 2.0

var start_time: float
var time_now: float
var ai_difficulty := {
	AIDifficulty.EASY: easy_hit_time,
	AIDifficulty.NORMAL: normal_hit_time,
	AIDifficulty.HARD: hard_hit_time
}
var info_label: Label;
var round_label: Label;
var player_score_label: Label;
var enemy_score_label: Label;

var has_round_started := false
var is_round_over := false
var is_game_over := false
var can_hit := false
var round_count := 0
var player_score := 0
var enemy_score := 0

var debug_elapsed_time_label: Label;

func _ready() -> void:
	$ColorRect.size = get_viewport_rect().size
	$HUD.size = get_viewport_rect().size
		
	debug_elapsed_time_label = get_node("HUD/DebugTimeElapse")
	debug_elapsed_time_label.visible = debug_show_elapsed_time
	
	info_label = get_node("HUD/InfoLabel")
	round_label = get_node("HUD/RoundLabel")
	enemy_score_label = get_node("HUD/EnemyScoreLabel")
	player_score_label = get_node("HUD/PlayerScoreLabel")

	$ShowInfoTimer.timeout.connect(_on_show_info_timer_timeout)
	$HitTimer.timeout.connect(_on_hit_timer_timeout)
	
	# dirty hack due to how the logic is setup
	best_of_rounds -= 1
	
	update_player_score(0)
	update_enemy_score(0)
	reset_state()

func _process(_delta: float) -> void:
	time_now = abs(Time.get_unix_time_from_system() - start_time)
	if debug_elapsed_time_label.visible:
		debug_elapsed_time_label.text = str(time_now)
		
	if is_game_over:
		return
	
	if time_now >= start_battle_time && !has_round_started:
		round_start()
	
	if Input.is_action_just_pressed("one_hit") && has_round_started:
		if can_hit:
			var timer_wait_time = get_node("HitTimer").wait_time
			var player_hit_time = time_now - start_battle_time - timer_wait_time
			if ai_difficulty[select_ai_diffculty] > player_hit_time:
				round_over(true)
			else:
				round_over(false)
		else:
			round_over(false)

func get_ready() -> void:
	info_label.visible = true
	info_label.text = "Get Ready"
	$ShowInfoTimer.start()
	
func round_start() -> void:
	has_round_started = true
	info_label.visible = true
	info_label.text = "Round Start"
	$ShowInfoTimer.start()
	$HitTimer.start()

func round_over(has_won: bool) -> void:
	is_round_over = true
	info_label.visible = true
	info_label.label_settings.font_size = large_font_size
	if has_won:
		info_label.text = "Round Won"
		update_player_score(1)
	else:
		info_label.text = "Round Lost"
		update_enemy_score(1)
	$ShowInfoTimer.stop()
	$HitTimer.stop()
	$ShowInfoTimer.wait_time *= 2
	$ShowInfoTimer.start()
	
func game_over(has_won: bool) -> void:
	is_game_over = true
	info_label.visible = true
	info_label.label_settings.font_size = large_font_size * 2
	if has_won:
		info_label.text = "Game Won"
	else:
		info_label.text = "Game Lost"
	$ShowInfoTimer.stop()
	$HitTimer.stop()

func update_round() -> void:
	round_count += 1
	round_label.text = "Round " + str(round_count)
	
func update_player_score(amount: int) -> void:
	player_score += amount
	player_score_label.text = "Player Score: " + str(player_score)
	
func update_enemy_score(amount: int) -> void:
	enemy_score += amount
	enemy_score_label.text = "Enemy Score: " + str(enemy_score)
	
func reset_state() -> void:
	has_round_started = false
	is_round_over = false
	can_hit = false
	
	$ShowInfoTimer.wait_time = label_show_time
	info_label.label_settings.font_size = normal_font_size
	info_label.visible = false
	
	$HitTimer.wait_time = randf_range(hit_min_duration, hit_max_duration) + $ShowInfoTimer.wait_time
	start_time = Time.get_unix_time_from_system()
	
	if player_score - enemy_score > best_of_rounds:
		game_over(true)
	elif enemy_score - player_score > best_of_rounds:
		game_over(false)
	else:
		update_round()
		get_ready()

func _on_show_info_timer_timeout() -> void:
	if is_game_over:
		return
	
	info_label.visible = false
	if is_round_over:
		reset_state()
	
func _on_hit_timer_timeout() -> void:
	if is_round_over || is_game_over:
		return 
	
	can_hit = true
	info_label.visible = true
	info_label.text = "NOW"
	info_label.label_settings.font_size *= 2
	$ShowInfoTimer.start()
