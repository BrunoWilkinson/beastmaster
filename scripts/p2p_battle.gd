extends Control

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Lobby.player_loaded.rpc_id(1)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_game() -> void:
	_update_text.rpc()

@rpc("any_peer", "call_local", "reliable")
func _update_text() -> void:
	$Label.text = "All players has loaded and the game has started"
