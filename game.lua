
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
local topGroup

local startSwing

local gs = GameState:new()

local flightMonitorTimerId

local function initMountains()
	local mountains = display.newRect( backgroundGroup, display.contentCenterX, display.contentCenterY, 478, 800 )
	mountains.fill = {
		type = "image",
		-- filename = "assets/images/mountains.png"
		filename = "assets/images/ai-background-3.png"
	}
	gs:setState("mountains", mountains)
end

local function initBuildings()
	Building.initTwo(display.contentHeight * 2, true) -- allows for navigating downward one screen length
	Building.initTwo(display.contentHeight) -- starting buildings
	Building.initTwo(0) -- 2nd set
	Building.initTwo(-display.contentHeight) -- 3rd set
	Building.initTwo(-display.contentHeight * 2) -- 4th set
	Building.initTwo(-display.contentHeight * 3) -- 5th set
	Building.initTwo(-display.contentHeight * 4) -- 6th set
	Building.initTwo(-display.contentHeight * 5) -- 7th set
	Building.initTwo(-display.contentHeight * 6) -- 8th set
	Building.initTwo(-display.contentHeight * 7) -- 9th set
	Building.initTwo(-display.contentHeight * 8) -- 10th set
	Building.initTwo(-display.contentHeight * 9) -- 11th set
	Building.initTwo(-display.contentHeight * 10) -- 12th set
	Building.initTwo(-display.contentHeight * 11) -- 13th set
	Building.initTwo(-display.contentHeight * 12) -- 14th set
	Building.initTwo(-display.contentHeight * 13) -- 15th set
	Building.initTwo(-display.contentHeight * 14) -- 16th set
	Building.initTwo(-display.contentHeight * 15) -- 17th set
	Building.initTwo(-display.contentHeight * 16) -- 18th set
	Building.initTwo(-display.contentHeight * 17) -- 19th set
	Building.initTwo(-display.contentHeight * 18) -- 20th set
	Building.initTwo(-display.contentHeight * 19) -- 21st set
	Building.initTwo(-display.contentHeight * 20) -- 22nd set
	Building.initTwo(-display.contentHeight * 21) -- 23rd set
	Building.initTwo(-display.contentHeight * 22) -- 24th set
	Building.initTwo(-display.contentHeight * 23) -- 25th set
end

local function initCharacter()
	local character = Character:new(characterGroup)
	gs:setState("character", character)
end

local gameLives = 2
local function restart()
	local character = gs:getState("character")._obj
	if character.swinging then return end

	Runtime:removeEventListener("touch", startSwing)

	if character.removeSelf then
		character:removeSelf()
	end

	gameLives = gameLives - 1

	if gameLives > 0 then	
		transition.pauseAll()
	
		local overlay = display.newRect( topGroup, display.contentCenterX, display.contentCenterY, display.contentWidth, display.contentHeight )
    	overlay:setFillColor(0, 0, 0, 0.7) -- semi-transparent black overlay

		local continueButton = display.newText( topGroup, "Continue", display.contentCenterX, display.contentCenterY + 100, native.systemFont, 44)
		continueButton:setFillColor(1, 1, 1)
		continueButton:addEventListener("tap", function()
			overlay:removeSelf()
			continueButton:removeSelf()
			transition.resumeAll()
			if Firework.clearFireworkTimerGenerator() then
				Firework.startFireworkTimerGenerator()
			end
			Runtime:addEventListener("touch", startSwing)
			initCharacter()
		end)

		return 
	end
	
	gameLives = 2
	composer.gotoScene( "menu", { time=800, effect="crossFade" } )

	timer.performWithDelay( 800, function()
		transition.cancelAll();

		gs:getState("mountains"):removeSelf()

		Firework.clearFireworkTimerGenerator()
		local fireworks = gs:getState("fireworks")
		while #fireworks > 0 do
			fireworks[#fireworks]:delete()
		end

		SkyLantern.clearSkyLanternTimerGenerator()
		local skyLanterns = gs:getState("skyLanterns")
		while #skyLanterns > 0 do
			skyLanterns[#skyLanterns]:delete()
		end

		-- remove all the buildings
		local buildings = gs:getState("buildings")
		for i = 1, #buildings do
			-- remove anchors
			local anchors = buildings[i]._obj.anchors
			for j = 1, #anchors do
				anchors[j]:delete()
			end
			buildings[i]._obj:removeSelf()
		end
		gs:setState("buildings", {})
	end, 1)
end

local function monitorFlight()
	flightMonitorTimerId = timer.performWithDelay( 25, function()
		local character = gs:getState("character")
		if (character ~= nil and character:isOffScreen()) then
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

startSwing = function(event)
    if event.phase == "began" then
		flightEnd()
		gs:getState("character"):swing() --ChatGPT Please Help Here! why is character nil on this line after restart? specifically when navigating back to the game from the menu after losing a first game? why is this method even running?
	elseif event.phase == "moved" then
		gs:getState("character"):setLinearDamping(event.x)
    elseif event.phase == "ended" then
		gs:getState("character"):release()
		monitorFlight()
    end
end

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

	topGroup = display.newGroup()
	gs:setState("topGroup", topGroup)
	sceneGroup:insert(topGroup)
end


function scene:show( event )

	local sceneGroup = self.view
	local phase = event.phase

	if ( phase == "will" ) then
		-- Code here runs when the scene is still off screen (but is about to come on screen)

		local fireworks = gs:getState("fireworks")
		while #fireworks > 0 do
			fireworks[#fireworks]:delete()
		end
		initMountains()
		initBuildings()

	elseif ( phase == "did" ) then
		-- Code here runs when the scene is entirely on screen

		timer.performWithDelay( 250, initCharacter, 1 )
		Runtime:addEventListener("touch", startSwing)
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
