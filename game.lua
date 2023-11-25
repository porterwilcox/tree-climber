
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local mathHelpers = require("helpers.mathHelpers")

local GameState = require("states.GameState")
local Anchor = require("models.Anchor")
local Building = require("models.Building")
local SkyLantern = require("models.SkyLantern")
local Firework = require("models.Firework")
local Character = require("models.Character")

local phyics = require("physics")
physics.start()
physics.setGravity( 0, 9.8 )
-- physics.setDrawMode( "hybrid" )

local backgroundGroup
local uiGroup
local gameGroup
local characterGroup

local gs = GameState:new()

local flightMonitorTimerId

local function initMountains()
	local mountains = display.newRect( backgroundGroup, display.contentCenterX, display.contentCenterY, 478, 800 )
	mountains.fill = {
		type = "image",
		filename = "assets/images/mountains.png"
	}
	gs:setState("mountains", mountains)
end

local function initBuildings()
	Building.initTwo(display.contentHeight * 2)
	Building.initTwo(display.contentHeight)
	Building.initTwo(0)
	Building.initTwo(-display.contentHeight)
	Building.initTwo(-display.contentHeight * 2)
end

local function initCharacter()
	local character = Character:new(characterGroup)
	gs:setState("character", character)
end

local function restart()
	transition.cancelAll();

	gs:getState("mountains"):removeSelf()
	initMountains()

	Firework.clearFireworkTimerGenerator()
	local fireworks = gs:getState("fireworks")
	while #fireworks > 0 do
		fireworks[#fireworks]:Delete()
	end

	SkyLantern.clearSkyLanternTimerGenerator()
	local skyLanterns = gs:getState("skyLanterns")
	while #skyLanterns > 0 do
		skyLanterns[#skyLanterns]:Delete()
	end

	-- remove all the buildings
	local buildings = gs:getState("buildings")
	for i = 1, #buildings do
		-- remove anchors
		local anchors = buildings[i]._obj.anchors
		for j = 1, #anchors do
			anchors[j]._obj:removeSelf()
		end
		buildings[i]._obj:removeSelf()
	end
	gs:setState("buildings", {})
	initBuildings()

	gs:getState("character")._obj:removeSelf()
	initCharacter()
end

local function monitorFlight()
	flightMonitorTimerId = timer.performWithDelay( 25, function()
		if (gs:getState("character"):isOffScreen()) then
			timer.cancel(flightMonitorTimerId) 
			flightMonitorTimerId = nil
			timer.performWithDelay( 500, restart, 1 )
		end
	end, 0 )
end

local function flightEnd()
	if flightMonitorTimerId ~= nil then 
		timer.cancel(flightMonitorTimerId) 
		flightMonitorTimerId = nil
	end
end

local function startSwing(event)
    if event.phase == "began" then
		flightEnd()
		gs:getState("character"):swing()
	elseif event.phase == "moved" then
		gs:getState("character"):setLinearDamping(event.x)
    elseif event.phase == "ended" then
		gs:getState("character"):release()
		monitorFlight()
    end
end
Runtime:addEventListener("touch", startSwing)

-- -----------------------------------------------------------------------------------
-- Scene event functions
-- -----------------------------------------------------------------------------------

function scene:create( event )

	local sceneGroup = self.view
	-- Code here runs when the scene is first created but has not yet appeared on screen

	backgroundGroup = display.newGroup()
	sceneGroup:insert(backgroundGroup)

	local sky = display.newRect( backgroundGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
	-- sky:setFillColor( 52/255, 52/255, 52/255 )
	sky.fill = {
		type = "image",
		filename = "assets/images/sky.png"
	}

    uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	gameGroup = display.newGroup()
	gs:setState("gameGroup", gameGroup)
	sceneGroup:insert(gameGroup)

	characterGroup = display.newGroup()
	sceneGroup:insert(characterGroup)

	initMountains()
	initBuildings()
end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
		
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		initCharacter()
		Firework:new( display.contentCenterX, display.contentCenterY )
	end
end


function scene:hide( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is on screen (but is about to go off screen)

	elseif ( phase == "did" ) then
		-- Code here runs immediately after the scene goes entirely off screen

	end
end


function scene:destroy( event )

	local sceneGroup = self.view
	-- Code here runs prior to the removal of scene's view

end


-- -----------------------------------------------------------------------------------
-- Scene event function listeners
-- -----------------------------------------------------------------------------------
scene:addEventListener( "create", scene )
scene:addEventListener( "show", scene )
scene:addEventListener( "hide", scene )
scene:addEventListener( "destroy", scene )
-- -----------------------------------------------------------------------------------

return scene
