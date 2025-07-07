extends CharacterBody3D

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var label: Label = $Control/Label
@onready var stamina_bar: ProgressBar = $Control/StaminaBar

const JUMP_VELOCITY : float = 4.5
const MAX_STAMINA : float = 100.0

var speed : int = 5
var current_stamina : float = MAX_STAMINA
var is_sprinting : bool = false

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
	stamina_bar.value = current_stamina
	current_stamina = clampf(current_stamina, 0, MAX_STAMINA)
	
	if !is_sprinting:
		await get_tree().create_timer(1).timeout
		current_stamina += 1
	else:
		current_stamina -= 0.01
	
	handle_movement(delta)
	move_and_slide()

func handle_movement(delta: float) -> void:
	label.text = "speed: " + str(speed)
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
			handle_sprint()
		else:
			speed = 5
			is_sprinting = false
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

func handle_sprint() -> void:
	if current_stamina != 0:
		speed = 15
		is_sprinting = true
