

require ("physics")
local ui = require("ui")

physics.start()
-- physics.setDrawMode ( "hybrid" ) -- Uncomment in order to show in hybrid mode	
physics.setGravity( 0, 9.8*1.35)
 
physics.start()
halfW=display.contentWidth*0.5
halfH=display.contentHeight*0.5
-- Audio for slash sound (sound you hear when user swipes his/her finger across the screen)
local slashSounds = {slash1 = audio.loadSound("slash1.wav"), slash2 = audio.loadSound("slash2.wav"), slash3 = audio.loadSound("slash3.wav")}
local slashSoundEnabled = true -- sound should be enabled by default on startup
local minTimeBetweenSlashes = 150 -- Minimum amount of time in between each slash sound
local minDistanceForSlashSound = 50 -- Amount of pixels the users finger needs to travel in one frame in order to play a slash sound

-- Audio for chopped fruit
local choppedSound = {chopped1 = audio.loadSound("chopped1.wav"), chopped2 = audio.loadSound("chopped2.wav")}

-- Audio for bomb
local preExplosion = audio.loadSound("preExplosion.wav")
local explosion = audio.loadSound("explosion.wav")

-- Adding a collision filter so the fruits do not collide with each other, they only collide with the catch platform
local fruitProp = {density = 1.0, friction = 0.3, bounce = 0.2, filter = {categoryBits = 2, maskBits = 1}}
local catchPlatformProp = {density = 1.0, friction = 0.3, bounce = 0.2, filter = {categoryBits = 1, maskBits = 2}}

-- Gush filter should not interact with other fruit or the catch platform
local gushProp = {density = 1.0, friction = 0.3, bounce = 0.2, filter = {categoryBits = 4, maskBits = 8} } 

-- Will contain all fruits available in the game 
local avalFruit = {}

-- Slash line properties (line that shows up when you move finger across the screen)
local maxPoints = 5
local lineThickness = 20
local lineFadeTime = 250
local endPoints = {}

-- Whole Fruit physics properties
local minVelocityY = 850
local maxVelocityY = 1100

local minVelocityX = -200
local maxVelocityX = 200

local minAngularVelocity = 100
local maxAngularVelocity = 200

-- Chopped fruit physics properties
local minAngularVelocityChopped = 100
local maxAngularVelocityChopped = 200

-- Splash properties
local splashFadeTime = 2500
local splashFadeDelayTime = 5000
local splashInitAlpha = .5
local splashSlideDistance = 50 -- The amoutn of of distance the splash slides down the background

-- Contains all the available splash images
local splashImgs = {}

-- Gush properties 
local minGushRadius = 10 
local maxGushRadius = 25
local numOfGushParticles = 15
local gushFadeTime = 500
local gushFadeDelay = 500

local minGushVelocityX = -350
local maxGushVelocityX = 350
local minGushVelocityY = -350
local maxGushVelocityY = 350

-- Timer references
local bombTimer
local fruitTimer

-- Game properties
local fruitShootingInterval = 1000
local bombShootingInterval = 5000

-- Groups for holding the fruit and splash objects
local splashGroup 
local fruitGroup 

function main()

	display.setStatusBar( display.HiddenStatusBar )

	setUpBackground()
	setUpCatchPlatform()
	initGroups()
	initFruitAndSplash()
	

	Runtime:addEventListener("touch", drawSlashLine)
	local gameStart = displayGameFirstPage()
	gameStart.alpha = 0.5
	
	
end

function startGame()
	score=0
	PointName=display.newText("Points: ",halfW+145,70)
	scoreText=display.newText(score,halfW+200,70)
        shootObject("fruit")
        TimeName = display.newText("Time",halfW, 30, native.systemFont, 50)
TimeName:setFillColor( 0.1, 0.5, 0.5 )
         secondsLeft=0
         clockText = display.newText( secondsLeft, display.contentCenterX+120, 30, native.systemFont, 50)
clockText:setFillColor( 0.1, 0.5, 0.5 )

local function updateTime()
	-- decrement the number of seconds
	secondsLeft = secondsLeft + 1
	
	-- time is tracked in seconds.  We need to convert it to minutes and seconds
	--local seconds = secondsLeft 
	
	-- make it a string using string format.  
	local timeDisplay = string.format( "%02d", secondsLeft )
	clockText.text = secondsLeft;
end

-- run them timer
local countDownTimer = timer.performWithDelay( 1000, updateTime, secondsLeft )
	
	bombTimer = timer.performWithDelay(bombShootingInterval, function(event) shootObject("bomb") end, 0)
	fruitTimer = timer.performWithDelay(fruitShootingInterval, function(event) shootObject("fruit") end, 0)
end

function initGroups()
	 splashGroup = display.newGroup()
	 fruitGroup = display.newGroup()
end

function setUpBackground()
	
	local background = display.newImage("bg.png", true)
	background.x = display.contentWidth / 2
	background.y = display.contentHeight / 2
	
end

-- Populates avalFruit with all the fruit images and thier widths and heights
function initFruitAndSplash()
	
	local watermelon = {}
	watermelon.whole = "watermelonWhole.png"
	watermelon.top = "watermelonTop.png"
	watermelon.bottom = "watermelonBottom.png"
	watermelon.splash = "redSplash.png"
	table.insert(avalFruit, watermelon)
	
	local strawberry = {}
	strawberry.whole = "strawberryWhole.png"
	strawberry.top = "strawberryTop.png"
	strawberry.bottom = "strawberryBottom.png"
	strawberry.splash = "redSplash.png"
	table.insert(avalFruit, strawberry)
	
	-- Initialize splash images
	table.insert(splashImgs, "splash1.png")
	table.insert(splashImgs, "splash2.png")
	table.insert(splashImgs, "splash3.png")
end


function getRandomFruit()

	local fruitProp = avalFruit[math.random(1, #avalFruit)]
	local fruit = display.newImage(fruitProp.whole)
	fruit.whole = fruitProp.whole
	fruit.top = fruitProp.top
	fruit.bottom = fruitProp.bottom
	fruit.splash = fruitProp.splash
	
	return fruit
	
end

function getBomb()

	local bomb = display.newImage( "bomb.png")
	return bomb
end

function shootObject(type)
	
	local object = type == "fruit" and getRandomFruit() or getBomb()
	
	fruitGroup:insert(object)
	
	object.x = display.contentWidth / 2
	object.y = display.contentHeight  + object.height * 2

	fruitProp.radius = object.height / 2
	physics.addBody(object, "dynamic", fruitProp)

	if(type == "fruit") then
		object:addEventListener("touch", function(event) chopFruit(object) end)
	else
		 
                 --object:removeSelf()
                 --object = nil
                 
		object:addEventListener("touch",function(event) bombTouchFunction(object) end)
		
	end
	
	-- Apply linear velocity 
	local yVelocity = getRandomValue(minVelocityY, maxVelocityY) * -1 -- Need to multiply by -1 so the fruit shoots up 
	local xVelocity = getRandomValue(minVelocityX, maxVelocityX)
	object:setLinearVelocity(xVelocity,  yVelocity)
		
	-- Apply angular velocity (the speed and direction the fruit rotates)
	local minAngularVelocity = getRandomValue(minAngularVelocity, maxAngularVelocity)
	local direction = (math.random() < .5) and -1 or 1
	minAngularVelocity = minAngularVelocity * direction
	object.angularVelocity = minAngularVelocity
	
end
function bombTouchFunction(object)
	
	playRandomChoppedSound()
	 score=math.floor(score*0.5)
	 scoreText.text=score
	 if(score==0)then
	explodeBomb(object,function(event) bombTouchFunction(object) end);
         end
	--createFruitPiece(fruit, "top")
	--createFruitPiece(fruit, "bottom")
	
	--createSplash(fruit)
	--createGush(fruit)
	
	object:removeSelf()
	

end

function explodeBomb(bomb,list)

	bomb:removeEventListener("touch",list)
            
	-- The bomb should not move while exploding
	bomb.bodyType = "kinematic"
	bomb:setLinearVelocity(0,  0)
	bomb.angularVelocity = 0
	
	-- Shake the stage
	local stage = display.getCurrentStage()
	
	local moveRightFunction
	local moveLeftFunction
	local rightTrans
	local leftTrans
	local shakeTime = 50
	local shakeRange = {min = 1, max = 25}

 	moveRightFunction = function(event) rightTrans = transition.to(stage, {x = math.random(shakeRange.min,shakeRange.max), y = math.random(shakeRange.min, shakeRange.max), time = shakeTime, onComplete=moveLeftFunction}); end 
	moveLeftFunction = function(event) leftTrans = transition.to(stage, {x = math.random(shakeRange.min,shakeRange.max) * -1, y = math.random(shakeRange.min,shakeRange.max) * -1, time = shakeTime, onComplete=moveRightFunction});  end 
	
	moveRightFunction()

	local linesGroup = display.newGroup()

	-- Generate a bunch of lines to simulate an explosion
 	local drawLine = function(event)

		local line = display.newLine(halfW, halfH, display.contentWidth * 2, display.contentHeight * 2)
		line.rotation = math.random(1,360)
		line.width = math.random(15, 25)
		linesGroup:insert(line)
	end
	local lineTimer = timer.performWithDelay(100, drawLine, 0)
	-- Function that is called after the pre explosion
	
	local explode = function(event)
	
		audio.play(explosion)
		blankOutScreen(bomb, linesGroup);
		timer.cancel(lineTimer)
		stage.x = 0 
		stage.y = 0
		transition.cancel(leftTrans)
		transition.cancel(rightTrans)
		scoreText:removeSelf()
                TimeName:removeSelf()
		clockText:removeSelf()
               PointName:removeSelf()
	end 
   
	-- Play the preExplosion sound first followed by the end explosion
	audio.play(preExplosion, {onComplete = explode})
	
	timer.cancel(fruitTimer)
	timer.cancel(bombTimer)	
	
      -- end
end
function blankOutScreen(bomb, linesGroup)
	
	local gameOver = displayGameOver()
	gameOver.alpha = 0 -- Will reveal the game over screen after the explosion
	
	-- Create an explosion animation
	local circle = display.newCircle( halfW, halfH, 5 )
	local circleGrowthTime = 300
	local dissolveDuration = 1000
	
	local dissolve = function(event) transition.to(circle, {alpha = 0, time = dissolveDuration, delay = 0, onComplete=function(event) gameOver.alpha = 1 end}); gameOver.alpha = 1  end
	
	circle.alpha = 0
	transition.to(circle, {time=circleGrowthTime, alpha = 1, width = display.contentWidth * 3, height = display.contentWidth * 3, onComplete = dissolve})
	
	-- Vibrate the phone
	system.vibrate()
	
	
	--bomb:removeSelf()
	linesGroup:removeSelf()
	
end

function displayGameOver()
	
	-- Will return a group so that we can set the alpha of the entier menu
	local group = display.newGroup()
	
	-- Dim the background with a transperent square
	local back = display.newRect( 0,0, display.contentWidth*2, display.contentHeight*2 )
	back:setFillColor(0,0,0, 255 * .1)
	group:insert(back)
	
	local gameOver = display.newImage( "gameover.png")
	gameOver.x = display.contentWidth / 2
	gameOver.y = display.contentHeight / 2
	group:insert(gameOver)	
	
	local replayButton = ui.newButton{
		default = "replayButton.png",
		over = "replayButton.png",
		onRelease = function(event) group:removeSelf(); HighName:removeSelf(); HighscoreText:removeSelf(); startGame() end
	}
	group:insert(replayButton)
	
	replayButton.x = display.contentWidth / 2
	replayButton.y = gameOver.y + gameOver.height / 2 + replayButton.height / 2
	HighName = display.newText("Highscore: ", display.contentCenterX, 30, native.systemFont, 50)
	HighName:setFillColor( 0.1, 0.5, 1 )
	      
	   HighscoreText = display.newText( secondsLeft, display.contentCenterX+130, 30, native.systemFont, 50)
	  HighscoreText:setFillColor( 0.1, 0.5, 0.5 )

	
	return group
end
 
function displayGameFirstPage()
	
	-- Will return a group so that we can set the alpha of the entier menu
	local group = display.newGroup()
	
	-- Dim the background with a transperent square
	local back = display.newRect( 0,0, display.contentWidth*2, display.contentHeight*2 )
	back:setFillColor(0,0,0, 255 * .1)
	group:insert(back)
	
	local titleLogo = display.newText("Fruit Ninja",0,0,native.systemFont,80)
		titleLogo.x = display.contentWidth * 0.5
	        titleLogo.y = 225
	titleLogo:setFillColor( 1, 0, 0.5 )
local Ownertext = display.newText("Akshay and Adithya",0,0,native.systemFont,35)
	 Ownertext.x = display.contentWidth * 0.5
	         Ownertext.y = 700
	          Owner = display.newText("(1MS13CS019)   (1MS13CS010)",0,0,native.systemFont,35)
	 Owner.x = display.contentWidth * 0.5
	         Owner.y = 800
	        
	        
	local function upTime()
	 local Instr = display.newText("Instructions?",0,0,native.systemFont,35)
	  Instr.alpha=1     
	
	 Instr.x = display.contentWidth * 0.5
	         Instr.y = 330
	         Instr:setFillColor( 1, 0.75, 0.5 )
	         local Instrtext = display.newText("If you chop a fruit score increases by\n 1 , if you touch a bomb score\n reduces to half , if score \n is 0 then gameover",0,0,native.systemFont,31)
		 	Instrtext.alpha=0
		 	Instrtext.x = display.contentWidth * 0.5
	         Instrtext.y = 400
             Instr:addEventListener("touch",function(event) Instrtext.alpha=1 Instr.alpha=0 end)
	local gameStart = display.newImage( "start_btn.png")
		gameStart.x = display.contentWidth / 2
		gameStart.y = display.contentHeight / 2
	group:insert(gameStart)
	
	local replayButton = ui.newButton{
		default = "start_btn.png",
		over = "start_btn.png",
		onRelease = function(event) group:removeSelf(); startGame()
		titleLogo:removeSelf()
		Instrtext:removeSelf()
		Instr:removeSelf()
		
		 Ownertext:removeSelf()
		  Owner:removeSelf()
                titleLogo = nil
        end
	}
	group:insert(replayButton)
	
	replayButton.x = display.contentWidth / 2
	replayButton.y = display.contentHeight / 2
	
	 end
  local countDownTimer = timer.performWithDelay( 3000, upTime, secondsLeft )
	return group
   end
-- Return a random value between 'min' and 'max'
function getRandomValue(min, max)
	return min + math.abs(((max - min) * math.random()))
end


function playRandomSlashSound()
	
	audio.play(slashSounds["slash" .. math.random(1, 3)])
end

function playRandomChoppedSound()
	
	audio.play(choppedSound["chopped" .. math.random(1, 2)])
end

function getRandomSplash()

 	return display.newImage(splashImgs[math.random(1, #splashImgs)])
end

function chopFruit(fruit)
	
	playRandomChoppedSound()
	score=score+1
	scoreText.text=score
	createFruitPiece(fruit, "top")
	createFruitPiece(fruit, "bottom")
	
	createSplash(fruit)
	createGush(fruit)
	
	fruit:removeSelf()
return score
end

-- Creates a gushing effect that makes it look like juice is flying out of the fruit
function createGush(fruit)

	local i
	for  i = 0, numOfGushParticles do
		local gush = display.newCircle( fruit.x, fruit.y, math.random(minGushRadius, maxGushRadius) )
		gush:setFillColor(255, 0, 0, 255)
		
		gushProp.radius = gush.width / 2
		physics.addBody(gush, "dynamic", gushProp)

		local xVelocity = math.random(minGushVelocityX, maxGushVelocityX)
		local yVelocity = math.random(minGushVelocityY, maxGushVelocityY)

		gush:setLinearVelocity(xVelocity, yVelocity)
		
		transition.to(gush, {time = gushFadeTime, delay = gushFadeDelay, width = 0, height = 0, alpha = 0, onComplete = function(event) gush:removeSelf() end})		
	end

end

function createSplash(fruit)
	
	local splash = getRandomSplash()
	splash.x = fruit.x
	splash.y = fruit.y
	splash.rotation = math.random(-90,90)
	splash.alpha = splashInitAlpha
	splashGroup:insert(splash)
	
	transition.to(splash, {time = splashFadeTime, alpha = 0,  y = splash.y + splashSlideDistance, delay = splashFadeDelayTime, onComplete = function(event) splash:removeSelf() end})		
	
end

-- Chops the fruit in half
-- Uses some trig to calculate the position 
-- of the top and bottom part of the chopped fruit (http://en.wikipedia.org/wiki/Rotation_matrix#Rotations_in_two_dimensions)
function createFruitPiece(fruit, section)

	local fruitVelX, fruitVelY = fruit:getLinearVelocity()

	-- Calculate the position of the chopped piece
	local half = display.newImage(fruit[section])
	half.x = fruit.x - fruit.x -- Need to have the fruit's position relative to the origin in order to use the rotation matrix
	local yOffSet = section == "top" and -half.height / 2 or half.height / 2
	half.y = fruit.y + yOffSet - fruit.y
	
	local newPoint = {}
	newPoint.x = half.x * math.cos(fruit.rotation * (math.pi /  180)) - half.y * math.sin(fruit.rotation * (math.pi /  180))
	newPoint.y = half.x * math.sin(fruit.rotation * (math.pi /  180)) + half.y * math.cos(fruit.rotation * (math.pi /  180))
	
	half.x = newPoint.x + fruit.x -- Put the fruit back in its original position after applying the rotation matrix
	half.y = newPoint.y + fruit.y
	fruitGroup:insert(half)
	
	-- Set the rotation 
	half.rotation = fruit.rotation
	fruitProp.radius = half.width / 2 -- We won't use a custom shape since the chopped up fruit doesn't interact with the player 
	physics.addBody(half, "dynamic", fruitProp)
	
	-- Set the linear velocity  
	local velocity  = math.sqrt(math.pow(fruitVelX, 2) + math.pow(fruitVelY, 2))
	local xDirection = section == "top" and -1 or 1
	local velocityX = math.cos((fruit.rotation + 90) * (math.pi /  180)) * velocity * xDirection
	local velocityY = math.sin((fruit.rotation + 90) * (math.pi /  180)) * velocity
	half:setLinearVelocity(velocityX,  velocityY)

	-- Calculate its angular velocity 
 	local minAngularVelocity = getRandomValue(minAngularVelocityChopped, maxAngularVelocityChopped)
	local direction = (math.random() < .5) and -1 or 1
	half.angularVelocity = minAngularVelocity * direction
end

-- Creates a platform at the bottom of the game "catch" the fruit and remove it
function setUpCatchPlatform()
	
	local platform = display.newRect( 0, 0, display.contentWidth * 4, 50)
	platform.x =  (display.contentWidth / 2)
	platform.y = display.contentHeight + display.contentHeight
	physics.addBody(platform, "static", catchPlatformProp)
	
	platform.collision = onCatchPlatformCollision
	platform:addEventListener( "collision", platform )
end

function onCatchPlatformCollision(self, event)
	-- Remove the fruit that collided with the platform
	event.other:removeSelf()
end

-- Draws the slash line that appears when the user swipes his/her finger across the screen
function drawSlashLine(event)
	
	-- Play a slash sound
	if(endPoints ~= nil and endPoints[1] ~= nil) then
		local distance = math.sqrt(math.pow(event.x - endPoints[1].x, 2) + math.pow(event.y - endPoints[1].y, 2))
		if(distance > minDistanceForSlashSound and slashSoundEnabled == true) then 
			playRandomSlashSound();  
			slashSoundEnabled = false
			timer.performWithDelay(minTimeBetweenSlashes, function(event) slashSoundEnabled = true end)
		end
	end
	
	-- Insert a new point into the front of the array
	table.insert(endPoints, 1, {x = event.x, y = event.y, line= nil}) 

	-- Remove any excessed points
	if(#endPoints > maxPoints) then 
		table.remove(endPoints)
	end

	for i,v in ipairs(endPoints) do
		local line = display.newLine(v.x, v.y, event.x, event.y)
		line.width = lineThickness
		transition.to(line, {time = lineFadeTime, alpha = 0, width = 0, onComplete = function(event) line:removeSelf() end})		
	end

	if(event.phase == "ended") then		
		while(#endPoints > 0) do
			table.remove(endPoints)
		end
	end
end


main()