extends Node3D

@onready var hit_rect = $UI/HitRect  # UI hit indicator
@onready var spawns = $Map/Spawns  # Spawn points
@onready var navigation_region = $Map/NavigationRegion3D  # Zombie navigation area

var zombie = load("res://Scenes/Zombie.tscn")
var instance

func _ready():
	randomize()  # Seed random functions

func _process(_delta):
	pass

# Briefly shows hit effect
func _on_player_player_hit():
	hit_rect.visible = true
	await get_tree().create_timer(0.2).timeout
	hit_rect.visible = false

# Returns a random child from a parent node
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)

# Spawns a zombie at a random spawn point
func _on_zombie_spawn_timer_timeout():
	var spawn_point = _get_random_child(spawns).global_position
	instance = zombie.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)
