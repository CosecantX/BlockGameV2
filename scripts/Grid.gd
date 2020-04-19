extends Node2D

# grid variables
export (Vector2) var startPos
export (Vector2) var blockSize
export (Vector2) var gridSize

# array to hold blocks
var blocks = [
	preload("res://scenes/BlueBlock.tscn"),
	preload("res://scenes/GreenBlock.tscn"),
	preload("res://scenes/PurpleBlock.tscn"),
	preload("res://scenes/RedBlock.tscn"),
	preload("res://scenes/YellowBlock.tscn")
]
var greyBlock = preload("res://scenes/GreyBlock.tscn")

# array to hold bombs
var bombs = [
	preload("res://scenes/BlueBomb.tscn"),
	preload("res://scenes/GreenBomb.tscn"),
	preload("res://scenes/PurpleBomb.tscn"),
	preload("res://scenes/RedBomb.tscn"),
	preload("res://scenes/YellowBomb.tscn")
]
export (float) var bombSpawnChance = .5

# array to hold pieces
var grid = []

# array to hold blocks to drop
var dropGroup = []
export (int) var dropGroupOffset = 3
export (int) var dropGroupstartPos = 7

var stage = "gen"
var timer
var scoreNode
var popCounter = 0
var score = 0

func _ready():
	timer = $Timer
	scoreNode = $Score
	randomize()
	grid = initializeGrid()
	#fillGrid()

func _process(delta):
	match stage:
		"gen":
			score += popCounter * popCounter
			scoreNode.text = "Score: " + str(score)
			fillDropGroup()
			stage = "input"
			popCounter = 0
		"input":
			processInput()
		"drop":
			pass
		"bomb":
			popBlocks()
			stage = "gen"

func processInput():
	if Input.is_action_just_pressed("drop"):
		tryDrop()
	if Input.is_action_just_pressed("rotateCW"):
		rotateDropGroupCW()
	moveDropGroup()

func initializeGrid():
	var array = []
	for x in gridSize.x:
		array.append([])
		for y in gridSize.y:
			array[x].append(null)
	return array

func fillGrid():
	for x in gridSize.x:
		for y in gridSize.y:
			var rand = floor(rand_range(-4, blocks.size()))
			if rand < 0: continue
			var block = blocks[rand].instance()
			add_child(block)
			block.position = gridToPixel(Vector2(x, y))
			grid[x][y] = block

func fillDropGroup():
	var spawnBomb = randf() < bombSpawnChance
	if spawnBomb:
		for i in range(0, 3):
			var rand = floor(rand_range(0, blocks.size()))
			var block = blocks[rand].instance()
			add_child(block)
			dropGroup.append(block)
		var rand = floor(rand_range(0, bombs.size()))
		var bomb = bombs[rand].instance()
		add_child(bomb)
		#bomb.connect("tweenDone", self, "popBlocks")
		dropGroup.append(bomb)
	else:
		for i in range(0, 4):
			var rand = floor(rand_range(0, blocks.size()))
			var block = blocks[rand].instance()
			add_child(block)
			dropGroup.append(block)
	var pos = []
	pos.append(gridToPixel(Vector2(dropGroupstartPos, gridSize.y - 1)))
	pos.append(gridToPixel(Vector2(dropGroupstartPos + 1, gridSize.y - 1)))
	pos.append(gridToPixel(Vector2(dropGroupstartPos + 1, gridSize.y - 2)))
	pos.append(gridToPixel(Vector2(dropGroupstartPos, gridSize.y - 2)))
	for i in range(0, pos.size()):
		pos[i].x += dropGroupOffset
		pos[i].y -= dropGroupOffset
	for d in range(0, dropGroup.size()):
		dropGroup[d].set_position(pos[d])

func gridToPixel(gridPos: Vector2):
	return Vector2(
		startPos.x + blockSize.x * gridPos.x, 
		startPos.y + -blockSize.y * gridPos.y
		)

func pixelToGrid(pixelPos: Vector2):
	return Vector2(
		floor((pixelPos.x - startPos.x) / blockSize.x), 
		floor((pixelPos.y - startPos.y) / -blockSize.y)
		)

func drop(target: Vector2):
	if target.y == 0: return
	if grid[target.x][target.y] == null: return
	if grid[target.x][target.y - 1] == null:
		grid[target.x][target.y].move(gridToPixel(Vector2(target.x, target.y - 1)))
		grid[target.x][target.y - 1] = grid[target.x][target.y]
		grid[target.x][target.y] = null

func tryDrop():
	var drop = true
	for d in dropGroup:
		var pos = pixelToGrid(d.get_position())
		if grid[pos.x][pos.y] != null: drop = false
	if drop:
		for d in dropGroup:
			var pos = pixelToGrid(d.get_position())
			grid[pos.x][pos.y] = d
			d.set_position(gridToPixel(Vector2(pos.x, pos.y)))
		dropGroup = []
		timer.start()
		stage = "drop"
	else:
		pass # show failed drop animation
	for _i in range(0, gridSize.y):
		for x in gridSize.x:
			for y in gridSize.y:
				drop(Vector2(x, y))

func moveDropGroup():
	var col = clamp(pixelToGrid(get_global_mouse_position()).x, 0, gridSize.x - 2)
	var pos = []
	pos.append(gridToPixel(Vector2(col, gridSize.y - 1)))
	pos.append(gridToPixel(Vector2(col + 1, gridSize.y - 1)))
	pos.append(gridToPixel(Vector2(col + 1, gridSize.y - 2)))
	pos.append(gridToPixel(Vector2(col, gridSize.y - 2)))
	for i in range(0, pos.size()):
		pos[i].x += dropGroupOffset
		pos[i].y -= dropGroupOffset
	for d in range(0, dropGroup.size()):
		dropGroup[d].set_position(pos[d])

func rotateDropGroupCW():
	var temp = dropGroup[0]
	dropGroup[0].position = dropGroup[3].position
	dropGroup[3].position = dropGroup[2].position
	dropGroup[2].position = dropGroup[1].position
	dropGroup[1].position = temp.position
	dropGroup[0] = dropGroup[3]
	dropGroup[3] = dropGroup[2]
	dropGroup[2] = dropGroup[1]
	dropGroup[1] = temp

func findBomb():
	for x in gridSize.x:
		for y in gridSize.y:
			if grid[x][y]:
				if grid[x][y].bomb == true: 
					return grid[x][y]

func popBlocks():
	var bomb = findBomb()
	if bomb:
		var color = bomb.color
		bomb.marked = true
		for _i in range(0, gridSize.x * gridSize.y):
			markAndPop()
		for _i in range(0, gridSize.y):
			for x in gridSize.x:
				for y in gridSize.y:
					drop(Vector2(x, y))

func markAndPop():
	for x in gridSize.x:
		for y in gridSize.y:
			if grid[x][y]:
				if grid[x][y].marked == true: 
					grid[x][y].marked == false
					var color = grid[x][y].color
					if x > 0 and grid[x - 1][y] and grid[x - 1][y].color == color:
						grid[x - 1][y].marked = true
					if x < gridSize.x - 1 and grid[x + 1][y] and grid[x + 1][y].color == color:
						grid[x + 1][y].marked = true
					if y > 0 and grid[x][y - 1] and grid[x][y - 1].color == color:
						grid[x][y - 1].marked = true
					if y < gridSize.y - 1 and grid[x][y + 1] and grid[x][y + 1].color == color:
						grid[x][y + 1].marked = true
					grid[x][y].queue_free()
					grid[x][y] = null
					popCounter += 1

func _on_Timer_timeout():
	stage = "bomb"














