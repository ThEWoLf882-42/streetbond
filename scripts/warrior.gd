extends CharacterBody3D


const JUMP_VELOCITY = 4.5

var unit_id
@export var team = 1
@export var health = 4
@export var damage = 2
@export var speed = 20
@export var attack_speed = 2
@export var price = 4
var state = 0
var level = 1
var xp = 0
var direction
var targets = [ ]
var enemys = [ ]
var base_health = health
var atk_nb = 0

@onready var base_1: Node3D = $"../base1"
@onready var base_2: Node3D = $"../base2"

@onready var health_team1: ProgressBar = $stats/SubViewport/health
@onready var health_team2: ProgressBar = $stats/SubViewport/health2
var health_bar
@onready var level_bar = $stats/SubViewport/level
var model
@onready var timer: Timer = $Timer
@onready var animation_player = $AnimationPlayer
const DMG = preload("res://mat/dmg.tres")
const DGR = preload("res://mat/danger.tres")
#"material_overlay"
func _ready():
	model = get_node("man/Plane")
	#var mat = model.get_surface_material(0)
	#mat.albedo_color = Color(randf(), randf(), randf())
	#model.set_surface_material(0, DMG)
	model.material_overlay = null
	if team == 1:
		health_bar = health_team1
		health_team2.visible = false
		targets.append(base_2)
	if team == 2:
		health_bar = health_team2
		health_team1.visible = false
		targets.append(base_1)
	level_bar.text = str(level)
	
	#health_bar.max_value = health
	health_bar.max_value = 2 * level
	health_bar.value = xp

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	#states
	# 1 -> run
	# 2 -> shase
	# 3 -> attack
	if state == 0 || state == 1:
		var trgt = targets.back()
		if is_instance_valid(trgt):
			direction = (trgt.position - position).normalized()
			look_at(trgt.position)
	if state == 2:
		direction = 0
		if enemys.is_empty():
			state = 0
			timer.stop()
		
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	move_and_slide()
	
	#dead
	if health <= 0 || (unit_id == 6 && atk_nb >= 6):
		if (unit_id == 6):
			for enm in enemys:
				attack(enm, -2)
		var win = price / 2 if price / 2 > 1 else 1
		if team == 1:
			base_2.money += win
		if team == 2:
			base_1.money += win
		queue_free()

func level_up(xpers):
	xp += xpers
	health_bar.value = xp
	if xp >= level * 2:
		xp = 0
		level += 1
		level_bar.text = str(level)
		#health_bar.max_value = base_health * level
		#health += base_health
		#health_bar.value = health
		
		health_bar.max_value = 2 * level
		health_bar.value = xp

# nta7r
func take_dmg(dmg):
	if (unit_id == 6):
		return false
	health -= dmg
	#if health_bar.value < dmg:
		#dmg = health_bar.value
	#health_bar.value = health
	if health > 0:
		return false
	else:
		return true

func hit_animation():
	model.material_overlay = DMG
	await get_tree().create_timer(0.05).timeout
	model.material_overlay = DGR
	await get_tree().create_timer(0.05).timeout
	model.material_overlay = DMG
	model.material_overlay = null

func attack(enemy, dmg):
	var enemy_lvl = enemy.level
	var is_killed = enemy.take_dmg(dmg * level)
	atk_nb += 1
	if is_killed:
		level_up(enemy_lvl)
		targets.erase(enemy)
		enemys.erase(enemy)
	await enemy.hit_animation()

# attack
func _on_timer_timeout() -> void:
	if not enemys.is_empty():
		if unit_id == 6:
			for enemy in enemys:
				attack(enemy, damage)
		else:
			var enemy = enemys.front()
			attack(enemy, damage)
		if unit_id == 9:
			for enemy in enemys:
				attack(enemy, -1)
	timer.start(attack_speed)
	

# enemy sighted
func _on_view_body_entered(body: Node3D) -> void:
	if (state == 0):
		#var pos = (body.position - position).normalized()
		#if position.distance_to(pos) > 5 && team != body.team:
		if  body.team && team != body.team:
			targets.append(body)
			state = 1
	

# enemy lost
func _on_view_body_exited(body: Node3D) -> void:
	if targets.has(body) && body != base_1 && body != base_2:
		targets.erase(body)

# enemy on range
func _on_hitbox_body_entered(body: Node3D) -> void:
	#body.take_dmg(50)
	if (body.team != team):
		enemys.append(body)
		timer.start(attack_speed)
		print("attack")
		state = 2

# enemy out of range
func _on_hitbox_body_exited(body: Node3D) -> void:
	if (enemys.has(body)):
		enemys.erase(body)
