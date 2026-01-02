extends Control

var _lobby_item_list: ItemList = null
var _join_button: Button = null
var _refresh_button: Button = null

var _lobby_mapping: Dictionary[String, int] = {}

func _ready() -> void:
	_lobby_item_list = $ScrollContainer/LobbyList
	assert(_lobby_item_list != null)
	
	_join_button = $Join
	assert(_join_button != null)
	
	_refresh_button = $Refresh
	assert(_refresh_button != null)

	Steam.lobby_match_list.connect(_on_lobby_match_list)
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	Steam.requestLobbyList()

	_join_button.button_down.connect(_on_join_button_down)
	_refresh_button.button_down.connect(_on_refresh_button_down)

func _on_join_button_down() -> void:
	if _lobby_item_list.is_anything_selected():
		var idx = _lobby_item_list.get_selected_items()[0]
		var text = _lobby_item_list.get_item_text(idx)
		Lobby.join_game(_lobby_mapping[text])

func _on_lobby_match_list(lobbies: Array) -> void:
	_lobby_mapping.clear()
	_lobby_item_list.deselect_all()
	_lobby_item_list.clear()

	for index in lobbies.size():
		var lobby_id = lobbies[index]
		var lobby_name := Steam.getLobbyData(lobby_id, "name")
		if lobby_name.is_empty():
			lobby_name = "Lobby " + str(index + 1)
		_lobby_mapping.get_or_add(lobby_name, lobby_id)
		_lobby_item_list.add_item(lobby_name)

	_lobby_item_list.select(0)

func _on_refresh_button_down() -> void:
	Steam.requestLobbyList()
