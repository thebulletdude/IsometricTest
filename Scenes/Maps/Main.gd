extends Node

var astar = AStar2D.new()

onready var currentMap = $Map

#Images of the selector squares and arrows
onready var selection = preload("res://Resources/MapTools/Selector.tscn")
onready var selectionArrows = preload("res://Resources/MapTools/SelectorArrows.tscn")
onready var selectionArrowsTimer = $SelectorArrowsTimer
onready var camera = $MainCamera
onready var player = $YSort/Player
onready var movementTimer = $PlayerMoveTimer

#Used to hold data on which squares contain images
var usedCells = []
#This is to hold the selection square objects which have been created
var selectableArray = []
#This holds the actual point on the grid
var selectablePointArray = []
var arrowsLocation
#Variable to keep track of where the selector is.
var selectorCell
var canSelect = true
var cameraLocation
var playerLocation = Vector2(30, 3)
var playerMovement = 5

var movementPath = []
var moving = false
var tick = false
var movementCount = 1
var sent = false

#These are all used to dictate if the selection squares need to be turned on or off.
var select = false
var selecting = false
var back = false

func _ready():
	mapMapper()
	selectorCell = Vector2(30, 4)
	setCamera(currentMap.get_node("TileMap").map_to_world(Vector2(30, 3)))
	setPlayer(currentMap.get_node("TileMap").map_to_world(playerLocation))
	player.target = currentMap.get_node("TileMap").map_to_world(playerLocation)
func _process(_delta):
	if(!player.done):
		sent = false
	if(select && !selecting):
		select = false
		back = false
		selecting = true
		selectable()
		addArrows()
	elif(back && selecting):
		select = false
		back = false
		selecting = false
		removeArrows()
		deselect()
	#When something is moving. It will stop every other action by the player.
	#It will then tell the current player to move through the path created
	#through A*.
	elif(moving):
		if(movementCount < movementPath.size()):
			if(!sent):
				sent = true
				player.updateVelocity(currentMap.get_node("TileMap").map_to_world(movementPath[movementCount]))
				findDirection()
				#player.position = currentMap.get_node("TileMap").map_to_world(movementPath[movementCount])
				movementCount += 1
		else:
			movementCount = 1
			moving = false

#####################################
#Player Direction
#Does this by finding the difference in the vectors between the current and prev 
#position in the path
#####################################
func findDirection():
	var previous = movementPath[movementCount - 1]
	var current = movementPath[movementCount]
	#Find the difference
	var difference = current - previous
	
	#Sets the annimation
	if(difference == Vector2(-1, 0)):
		player.updateAnimation("TL")
	elif(difference == Vector2(1, 0)):
		player.updateAnimation("BR")
	elif(difference == Vector2(0, -1)):
		player.updateAnimation("TR")
	elif(difference == Vector2(0, 1)):
		player.updateAnimation("BL")

func _input(ev):
	#############################################################
	#The Code to dictate the selection squares being turned on and off
	#############################################################
	if ev is InputEventKey and ev.scancode == KEY_SPACE && !selecting:
		select = true
	if ev is InputEventKey and ev.scancode == KEY_E && selecting:
		selecting = false
		removeArrows()
		deselect()
		movementPath = astar.get_point_path(findIndex(playerLocation), findIndex(selectorCell))
		updatePlayerPosition(selectorCell)
		moving = true
	if ev is InputEventKey and ev.scancode == KEY_BACKSPACE:
		back = true
	#############################################################
	
	#############################################################
	#The decisions for where the selector will go
	#############################################################
	if(canSelect):
		if ev is InputEventKey and ev.scancode == KEY_A && selecting:
			if(locationCheck(-1, 0) == 1):
				selectorCell = Vector2(selectorCell[0] - 1, selectorCell[1])
				setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
				resetArrows()
			elif(locationCheck(-1, 0) == 2):
				if(isSelectable(Vector2(selectorCell[0] - 2, selectorCell[1]))):
					selectorCell = Vector2(selectorCell[0] - 2, selectorCell[1])
					setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
					resetArrows()
		if ev is InputEventKey and ev.scancode == KEY_D && selecting:
			if(locationCheck(1, 0) == 1):
				selectorCell = Vector2(selectorCell[0] + 1, selectorCell[1])
				setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
				resetArrows()
			elif(locationCheck(1, 0) == 2):
				if(isSelectable(Vector2(selectorCell[0] + 2, selectorCell[1]))):
					selectorCell = Vector2(selectorCell[0] + 2, selectorCell[1])
					setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
					resetArrows()
		if ev is InputEventKey and ev.scancode == KEY_S && selecting:
			if(locationCheck(0, 1) == 1):
				selectorCell = Vector2(selectorCell[0], selectorCell[1] + 1)
				setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
				resetArrows()
			elif(locationCheck(0, 1) == 2):
				if(isSelectable(Vector2(selectorCell[0], selectorCell[1] + 2))):
					selectorCell = Vector2(selectorCell[0], selectorCell[1] + 2)
					setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
					resetArrows()
		if ev is InputEventKey and ev.scancode == KEY_W && selecting:
			if(locationCheck(0, -1) == 1):
				selectorCell = Vector2(selectorCell[0], selectorCell[1] - 1)
				setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
				resetArrows()
			elif(locationCheck(0, -1) == 2):
				if(isSelectable((Vector2(selectorCell[0], selectorCell[1] - 2)))):
					selectorCell = Vector2(selectorCell[0], selectorCell[1] - 2)
					setCamera(currentMap.get_node("TileMap").map_to_world(selectorCell))
					resetArrows()
	#############################################################

func setCamera(location):
	camera.position = location
	
func setPlayer(location):
	player.position = location
	

#Updates the players position to the hande in cordinate. Based off the Tilemap
func updatePlayerPosition(pos):
	playerLocation = pos
	
	##################################
	#This is to update the selector cell and ensure it staays on the map
	##################################
	var temp = Vector2(pos.x, pos.y + 1)
	if(isSelectable(temp)):
		selectorCell = temp
	else:
		selectorCell = Vector2(pos.x, pos.y - 1)
	selectablePointArray.clear() 


#Use this to get an array of all of the cordinates with a graphic
func mapMapper():
	usedCells.append(currentMap.get_node("TileMap").get_used_cells())
	var count = 0
	
	##############################################################
	#Implemets an A* algoritm and connects all of the cells together.
	##############################################################
	for n in usedCells:
		for z in n:
			astar.add_point(count, z)
			count += 1
	
	var adjacentCells = []
	for x in usedCells:
		for z in x:
			adjacentCells.append(Vector2(z[0] + 1, z[1]))
			adjacentCells.append(Vector2(z[0] - 1, z[1]))
			adjacentCells.append(Vector2(z[0], z[1] + 1))
			adjacentCells.append(Vector2(z[0], z[1] - 1))
			for y in adjacentCells:
				if(isSelectable(y)):
					var temp = findIndex(y)
					if(y != z):
						astar.connect_points(findIndex(z), temp, true)
			adjacentCells.clear()

func checkAbove():
	pass
		
func findIndex(point):
	var count = 0
	for n in usedCells:
		for z in n:
			if(z == point):
				return count
			count += 1
	
#Used to find if the location is availabe to be selected or not. If it can returns true.
func locationCheck(x, y):
	var checkingCell = Vector2(selectorCell[0] + x, selectorCell[1] + y)
	if(checkingCell == playerLocation):
		return 2
	for n in selectablePointArray:
		if(n == checkingCell):
			return 1
	return 0
	
func isSelectable(point):
	for n in usedCells:
		for z in n:
			if(z == point):
				return true
	return false
	

#Use this to create a visual of what is selectable
func selectable():
	var currentCell
	for n in usedCells:
		for z in n:
			var globalCell = currentMap.get_node("TileMap").map_to_world(z)
			if(z[0] == playerLocation[0] && z[1] == playerLocation[1]):
				pass
			elif(isInSelectable(z)):
				pass
			else:
				#Translates the grid cordinate to global grid
				currentCell = globalCell
				selectablePointArray.append(z)
				var temp = selection.instance()
				temp.position = currentCell
				$YSort.add_child(temp)
				selectableArray.append(temp)
			
#Recieves the distance on the tilemap
func tileDistance(global, local):
	return sqrt(pow(local[1] - global[1], 2) + pow(local[0] - global[0], 2)) 
	
func isInSelectable(n):
	if(tileDistance(playerLocation, n) > playerMovement):
		return true
	else:
		if(astar.get_point_path(findIndex(playerLocation), findIndex(n)).size() > playerMovement + 1):
			return true
		else:
			return false
	
func addArrows():
	var currentCell = currentMap.get_node("TileMap").map_to_world(selectorCell)
	var temp = selectionArrows.instance()
	temp.position = currentCell
	$YSort.add_child(temp)
	arrowsLocation = temp
func removeArrows():
	$YSort.remove_child(arrowsLocation)
	
#Erases the selectable visual
func deselect():
	for n in selectableArray:
		$YSort.remove_child(n)
	selectableArray.clear()

#Takes away the current arrow and creates a new one in a new location. Sets the timer
func  resetArrows():
	removeArrows()
	addArrows()
	canSelect = false
	selectionArrowsTimer.start(.2)

func _on_SelectorArrowsTimer_timeout():
	canSelect = true


func _on_PlayerMoveTimer_timeout():
	print("tick")
	movementCount += 1
	tick = false
	
