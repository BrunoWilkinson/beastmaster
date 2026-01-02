extends Node
class_name SteamInit
## Steam Initialization
##
## Handles the SteamGodot setup (AppId, Callbacks, etc...)

func _ready() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx(480, true)
	print("Did Steam initialize?: %s " % initialize_response)
	if initialize_response['status'] > Steam.STEAM_API_INIT_RESULT_OK:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
