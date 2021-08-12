extends KinematicBody2D


var speed = 100

var target = Vector2()
var velocity = Vector2(32, 0)
var done = false

func updateVelocity(x):
	done = true
	target = x

func _physics_process(delta):
	velocity = position.direction_to(target) * (speed + delta)
	# look_at(target)
	if position.distance_to(target) > 2:
		velocity = move_and_slide(velocity)
	else:
		done = false

func updateAnimation(x):
	if(x == "BR"):
		$AnimatedSprite.animation = "BR"
	elif(x == "BL"):
		$AnimatedSprite.animation = "BL"
	elif(x == "TR"):
		$AnimatedSprite.animation = "TR"
	elif(x == "TL"):
		$AnimatedSprite.animation = "TL"
