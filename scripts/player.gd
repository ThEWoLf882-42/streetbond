extends CharacterBody3D

const SPEED = 100

@onready var camera = $Camera3D

const limit = 500

func _physics_process(delta: float) -> void:
	var input_dir := Input.get_vector("a", "d", "w", "s")
	var cam_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	camera.position = camera.position + Vector3(0, cam_dir.y, cam_dir.y)
	rotation.y = rotation.y + cam_dir.x / 20
	if position.x > limit || position.x < -limit || position.y > limit || position.y < -limit:
		direction = Vector3(0,0,0)
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()
