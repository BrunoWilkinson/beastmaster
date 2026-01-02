extends Control

var _lobby_item_list: ItemList = null
var _join_button: Button = null

func _ready() -> void:
	_lobby_item_list = $ScrollContainer/LobbyList
	assert(_lobby_item_list != null)
	
	_join_button = $Join
	assert(_join_button != null)

	for i in range(1, 50):
		_lobby_item_list.add_item("Lobby " + str(i))
	_join_button.button_down.connect(_on_join_button_down)

func _on_join_button_down() -> void:
	if _lobby_item_list.is_anything_selected():
		var idx = _lobby_item_list.get_selected_items()[0]
		var text = _lobby_item_list.get_item_text(idx)
		print(text)
