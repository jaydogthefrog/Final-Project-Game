extends Node3D

const SPEED = 40.0  # Movement speed

@onready var mesh = $MeshInstance3D  # Visual representation of the object
@onready var ray = $RayCast3D  # Raycast for collision detection
@onready var particles = $GPUParticles3D  # Particles for impact effect

func _ready():
	pass

# Moves the object forward each frame and handles collisions
func _process(delta):
	position += transform.basis * Vector3(0, 0, -SPEED) * delta  # Move forward
	if ray.is_colliding():
		mesh.visible = false  # Hide the mesh on collision
		particles.emitting = true  # Start particle effect
		ray.enabled = false  # Disable further collisions
		if ray.get_collider().is_in_group("enemy"):
			ray.get_collider().hit()  # Trigger 'hit' function on enemy
		await get_tree().create_timer(1.0).timeout  # Wait 1 second
		queue_free()  # Remove the node

# Frees the node when timer times out
func _on_timer_timeout():
	queue_free()
