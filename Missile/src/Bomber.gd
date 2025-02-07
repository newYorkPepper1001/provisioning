# Bomber Scene
extends Node2D

var Explode = preload("res://Explode.tscn")
var rng = RandomNumberGenerator.new()

var is_hit = false
var velocity = Vector2(-1, 0)
var max_x = 1100
var max_y = 800
var min_x = -100

var targets
var can_bomb = false
var drop_target_x
var wave_end

signal bomber_dropping(start_loc, end_loc)

# Called when the node enters the scene tree for the first time.
func _ready():
	if randi() % 2:
		$BomberArea/BomberCollision/BomberSprite.visible = false
		$BomberArea/BomberCollision.disabled = true
		$BomberArea.scale = Vector2(.7, .7)
	else:
		$BomberArea/SatelliteCollision/SatelliteSprite.visible = false
		$BomberArea/SatelliteCollision.disabled = true
		$BomberArea.scale = Vector2(.7, 1)
	
	$BomberArea/FlightSound2D.play()
	
	var viewport = get_viewport_rect().size
	max_x = viewport.x + 100
	max_y = viewport.y / 2
	
	if randi() % 2:
		print("This bomber can drop bombs")
		can_bomb = true
		drop_target_x = rng.randf_range(30, viewport.x - 30)
	
	rng.randomize()
	var height = rand_range(100, max_y)
	var direction = rand_range(-1, 1) * 2.2
	direction = ceil(direction) if direction > 0 else floor(direction) 
	velocity = Vector2(direction, 0)

	if direction > 0:
		position = Vector2(0, height)
		$BomberArea/BomberCollision/BomberSprite.flip_h = true
		$BomberArea/SatelliteCollision/SatelliteSprite.flip_h = true
	else:
		position = Vector2(max_x - 50, height)
		
	print("Starting a bomber at position:", position, "  direction:", direction)
	var _err = $BomberArea.connect("area_entered", self, "bomber_hit")


func _process(_delta):
	if is_hit:
		return

	if wave_end:
		velocity = Vector2(10, 0) * velocity.normalized()
		
	position += velocity
	
	if position.x > max_x or position.x < min_x:
		print("bomber went too far off screen, ending")
		get_parent().set_bomber_over(self) # raise signal instead
		
		end_bomber()
	
	if can_bomb and position.x < drop_target_x + 10 and position.x > drop_target_x - 10:
		can_bomb = false
		var target
		var bomb_targets = targets.duplicate(true) # Create clone to not mess with original array
		var bombs = (randi() % 4) + 1
		print("Bomber trying to drop ", bombs, " bombs")
		for _i in range(bombs):
			print("Bomber sent signal to drop a bomb")
			target = randi() % bomb_targets.size()
			emit_signal("bomber_dropping", position, targets[target])
			bomb_targets.remove(target)


func bomber_hit(object):
	if is_hit:
		return
		
	print("Bomber: I hit something")
	is_hit = true
	$BomberArea/FlightSound2D.stop()
	
	var explode_instance = Explode.instance()
	explode_instance.position = $BomberArea.position
	add_child(explode_instance)
	$BomberArea/BomberCollision/BomberSprite.visible = false
	$BomberArea/SatelliteCollision/SatelliteSprite.visible = false
	explode_instance.connect("explode_end", self, "_on_bomber_explode")
	get_parent().set_bomber_hit(object) # raise signal instead


func _on_bomber_explode():
	print("The bomber is done exploding now")
	end_bomber()
	
func end_bomber():
	$BomberArea/FlightSound2D.stop()
	get_parent().remove_child(self)
	
func set_targets(new_targets):
	targets = new_targets
	
func set_wave_end():
	wave_end = true

	
