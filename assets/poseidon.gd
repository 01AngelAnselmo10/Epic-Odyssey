extends CharacterBody2D

# Propiedades del minijefe
@export var speed = 300.0  # Velocidad de movimiento
@export var patrol_distance = 200.0  # Distancia de patrulla
@export var health = 100.0  # Salud del minijefe
@export var attack_damage = 10.0  # Daño por ataque
@export var attack_cooldown = 2.0  # Tiempo entre ataques
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")  # Gravedad del proyecto

var character = null  # Referencia al jugador (cambiado de player a character)
var is_chasing = false  # Estado: persiguiendo o patrullando
var patrol_direction = 1.0  # Dirección inicial de patrulla (1 o -1)
var initial_position = Vector2.ZERO  # Posición inicial para patrullar
var can_attack = true  # Controla el enfriamiento del ataque

@onready var timer = $Timer  # Referencia al Timer
@onready var animated_sprite = $poseidon_sprite  # Referencia al AnimatedSprite2D

func _ready():
	initial_position = position  # Guardar posición inicial
	timer.wait_time = attack_cooldown
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))

func _physics_process(delta):
	# Aplicar gravedad si no está en el suelo
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0  # Resetear velocidad vertical si está en el suelo

	if is_chasing and character:
		# Perseguir al jugador
		var direction = (character.global_position - global_position).normalized()
		velocity.x = direction.x * speed  # Solo afecta el eje X para persecución
		move_and_slide()
		
		# Voltear sprite según dirección
		if animated_sprite:  # Verificar que animated_sprite exista
			if direction.x > 0:
				animated_sprite.flip_h = false
			elif direction.x < 0:
				animated_sprite.flip_h = true
			
		# Atacar si está en rango
		if can_attack:
			attack()
	else:
		# Patrullar
		velocity.x = speed * patrol_direction
		move_and_slide()
		
		# Cambiar dirección al alcanzar el límite de patrulla
		if abs(position.x - initial_position.x) > patrol_distance:
			patrol_direction *= -1
			if animated_sprite:  # Verificar que animated_sprite exista
				animated_sprite.flip_h = !animated_sprite.flip_h

# Detectar al jugador entrando en el rango
func _on_area_2d_body_entered(body):
	if body.is_in_group("players"):
		character = body  # Cambiado de player a character
		is_chasing = true

# Detectar al jugador saliendo del rango
func _on_area_2d_body_exited(body):
	if body.is_in_group("players"):
		character = null  # Cambiado de player a character
		is_chasing = false

# Función de ataque
func attack():
	if character and can_attack:  # Cambiado de player a character
		print("Miniboss ataca al jugador!")
		can_attack = false
		timer.start()

# Reestablecer el ataque después del enfriamiento
func _on_timer_timeout():
	can_attack = true

# Recibir daño
func take_damage(damage):
	health -= damage
	print("Miniboss salud:", health)
	if health <= 0:
		die()

# Muerte del minijefe
func die():
	print("Miniboss derrotado!")
	queue_free()  # Eliminar el minijefe
