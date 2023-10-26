
local composer = require( "composer" )

local scene = composer.newScene()

-- -----------------------------------------------------------------------------------
-- Code outside of the scene event functions below will only be executed ONCE unless
-- the scene is removed entirely (not recycled) via "composer.removeScene()"
-- -----------------------------------------------------------------------------------

local GameState = require("states.GameState")
local Character = require("models.Character")
local Anchor = require("models.Anchor")

local phyics = require("physics")
physics.start()
physics.setGravity( 0, 9.8 )
physics.setDrawMode( "hybrid" )

local uiGroup
local backgroundGroup
local treeGroup

local gs = GameState:new()

local flightMonitorTimerId

local function initAnchor()
	local anchor = Anchor:new( treeGroup, display.contentCenterX, 600 )
	gs:addTableMember("anchors", anchor)

	anchor = Anchor:new( treeGroup, 90, 200 )
	gs:addTableMember("anchors", anchor)

end

local function initCharacter()
	local character = Character:new(treeGroup)
	gs:setState("character", character)
end

local function restart()
	gs:getState("character")._ref:removeSelf()
	initCharacter()
end

local function monitorFlight()
	flightMonitorTimerId = timer.performWithDelay( 25, function()
		if (gs:getState("character"):isOffScreen()) then
			timer.cancel(flightMonitorTimerId) 
			flightMonitorTimerId = nil
			restart()
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
		gs:getState("character"):setPivotJointMotorTorque(event.x)
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

    uiGroup = display.newGroup()
	sceneGroup:insert(uiGroup)

	backgroundGroup = display.newGroup()
	sceneGroup:insert(backgroundGroup)

	treeGroup = display.newGroup()
	gs:setState("treeGroup", treeGroup)
	sceneGroup:insert(treeGroup)

end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)
		
	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		initAnchor()
		initCharacter()

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
