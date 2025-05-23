extends CharacterBody2D

signal player_died  # Nueva señal para indicar que el jugador ha muerto

@export var move_speed: float
@export var jump_speed: float
@export var attack_damage: int
@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_area = $AttackArea
var is_facing_right = true
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var attack_var: bool = false
var current_attack_animation: String = ""  # Almacena la animación de ataque actual

func _ready():
	# Conectar la señal animation_finished al iniciar el nodo
	animated_sprite.animation_finished.connect(_on_attack_animation_finished)
	attack_area.body_entered.connect(_on_attack_area_body_entered)
	attack_area.monitoring = false
	add_to_group("players")

func _physics_process(delta):
	# Ejecutar siempre movimiento, salto y física
	jump(delta)
	move_x()
	flip()
	move_and_slide()
	update_animations()
	attack()  # Llama a attack después de otras acciones

func jump(delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = -jump_speed
	if not is_on_floor():
		velocity.y += gravity * delta

func flip():
	if (is_facing_right and velocity.x < 0) or (not is_facing_right and velocity.x > 0):
		scale.x *= -1
		is_facing_right = not is_facing_right
		attack_area.position.x = abs(attack_area.position.x) * (1 if is_facing_right else -1)

func move_x():
	var input_axis = Input.get_axis("move_left", "move_right")
	velocity.x = input_axis * move_speed

func update_animations():
	if attack_var:  # Prioriza la animación de ataque
		# Solo reproducir la animación almacenada si no es la actual
		if animated_sprite.animation != current_attack_animation:
			animated_sprite.play(current_attack_animation)
		return
	if not is_on_floor():
		if velocity.y < 0:
			animated_sprite.play("jump")
		else:
			animated_sprite.play("fall")
		return
	if velocity.x:
		animated_sprite.play("run")
	else:
		animated_sprite.play("idle")

func attack():
	if Input.is_action_just_pressed("attack") and not attack_var:  # Solo inicia ataque si no está atacando
		attack_var = true
		# Seleccionar la animación al inicio del ataque y almacenarla
		current_attack_animation = "moving_attack" if is_on_floor() and velocity.x != 0 else "attack"
		animated_sprite.play(current_attack_animation)
		attack_area.monitoring = true
		print("Started attack animation:", current_attack_animation)

func _on_attack_animation_finished():
	if animated_sprite.animation in ["attack", "moving_attack"]:  # Restablece para ambas animaciones de ataque
		print("Attack animation finished:", animated_sprite.animation)
		attack_var = false
		current_attack_animation = ""  # Limpiar la animación almacenada
		attack_area.monitoring = false

func _on_attack_area_body_entered(body):
	if body.is_in_group("enemy"):
		body.take_damage(attack_damage)
		print("golpeaste un enemigo con ", attack_damage, "puntos de daño")

func _on_player_died():
	emit_signal("player_died")  # Emitir la señal cuando el jugador "muere"

# Nueva función para manejar daño y muerte
func take_damage(damage: int):
	var health = 100  # Salud inicial (puedes hacerla @export si quieres ajustarla)
	health -= damage
	print("Player health:", health)
	if health <= 0:
		_on_player_died()  # Llamar a _on_player_died cuando la salud llegue a 0
