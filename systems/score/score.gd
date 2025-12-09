class_name ScoreSystem
extends Node
## Score management
## 
## [color=Orange]Dependency:[/color] Requires [HitSystem] [br][br]
## Update the round state based on values given, 
## and emit those update to other systems.[br]
## [br]
## Usage with node:
## [codeblock]
## score_system: ScoreSystem = null
## func _ready():
##     score_system = $Score
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]
## [br]
## Usage without node:
## [codeblock]
## score_system: ScoreSystem = null
## func _ready():
##     round_system = ScoreSystem.new()
##     # CRITICAL: Mandatory to pass a ref to the hit timing system
##     round_system.setup(hit_system)
## [/codeblock]

@export var max_player := 2

var _players_score: Dictionary[int, int]
var _hit_system: HitSystem = null

## [color=red]Critical:[/color] Mandatory to pass a ref to the hit timing system
func setup(in_hit_system: HitSystem) -> void:
	assert(_hit_system != null)
	_hit_system = in_hit_system

func _increment_winner_score() -> void:
	var winner_id: int = 0
	for id in _players_score.keys():
		if winner_id == id:
			continue
		
		if _hit_system.get_player_hit(winner_id) > _hit_system.get_player_hit(id):
			winner_id = id
	
	_players_score[winner_id] += 1
