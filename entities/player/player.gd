extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var label: Label = $Control/Label
@onready var stamina_bar: ProgressBar = $Control/StaminaBar
@onready var sprint_regen: Timer = $SprintRegen

const JUMP_VELOCITY : float = 4.5
const MAX_STAMINA : float = 100.0
const MAX_SPEED : int = 8
const MIN_SPEED : int = 2
const AVG_SPEED : int = 4

var DELTA_TIME : float

var speed : int = AVG_SPEED
var current_stamina : float = MAX_STAMINA
var is_sprinting : bool = false
var can_sprint : bool = true
var is_stamina_regen : bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	stamina_bar.max_value = MAX_STAMINA

func _input(event: InputEvent) -> void:
	# Handles the player camera movement through getting the mouse x and y axis
	if event is InputEventMouse:
		camera.rotate_x(-event.relative.y * 0.005)
		head.rotate_y(-event.relative.x * 0.005)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-70), deg_to_rad(70))

func _physics_process(delta: float) -> void:
	DELTA_TIME = get_process_delta_time()
	handle_movement(delta)
	move_and_slide()

func handle_movement(delta: float) -> void:
	label.text = "speed: " + str(sprint_regen.time_left)
	# Debug: end game
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if Input.is_action_pressed("sprint"):
			if can_sprint:
				is_sprinting = true
		else:
			is_sprinting = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		is_sprinting = false
	
	handle_sprint()

func handle_sprint() -> void:
	var was_sprinting : bool
	stamina_bar.value = current_stamina
	current_stamina = clampf(current_stamina, 0, MAX_STAMINA)
	
	if current_stamina == 0:
		can_sprint = false
		is_sprinting = false
	elif current_stamina == MAX_STAMINA:
		can_sprint = true
	
	if is_stamina_regen:
		current_stamina += 10 * DELTA_TIME
	
	if Input.is_action_just_released("sprint"):
		was_sprinting = true
	
	if is_sprinting:
		if can_sprint:
			speed = MAX_SPEED
			is_stamina_regen = false
			was_sprinting = false
			current_stamina -= 20 * DELTA_TIME
	else:
		speed = AVG_SPEED
		if sprint_regen.is_stopped() && was_sprinting:
			sprint_regen.start()
			was_sprinting = false


func _on_sprint_regen_timeout() -> void:
	is_stamina_regen = true
