local physics = require("physics")
physics.start()

local tableHelpers = require( "helpers.tableHelpers" )

local GameState = require("states.GameState")
local gs = GameState:new()

local Owl = {}
Owl.__index = Owl

local id = 1

local owlImages = {
    {
        type = "image",
        filename = "assets/images/owls/owl-fly-1.png"
    },
    {
        type = "image",
        filename = "assets/images/owls/owl-fly-2.png"
    },
    {
        type = "image",
        filename = "assets/images/owls/owl-perched.png"
    }
}

function Owl:new( anchor )
    local owl = display.newCircle( gs:getState("topGroup"), anchor.x, anchor.y-10, 15 )

    physics.removeBody(anchor)
    anchor.physicalBodyExists = false

    owl.fill = owlImages[3]  --set the owl to the perched image
    owl.anchor = anchor
    owl.id = id
    owl.name = "owl"
    id = id + 1
    owl.xScale = 0.7
    owl.yScale = 0.7
    local self = setmetatable({ _obj = owl }, Owl)
    self:animate()
    return self
end

function Owl:move(unitsToMove, ms)
    local owl = self._obj

    transition.to(owl, {time = ms, y = owl.y + unitsToMove, transition = easing.outSine })
end

function Owl:animate()
    local owl = self._obj

    local flyAway  -- forward declaration
    local flyBack  -- forward declaration

    local perchedTime = math.random(300, 2500)
    local flyBackTime = 4000--math.random(250, 5000)

    -- Function to cycle through flying images
    local function cycleFlyingImages()
        local imageIndex = 1
        return function()
            owl.fill = owlImages[imageIndex]  -- Corrected array name
            imageIndex = imageIndex == 1 and 2 or 1
        end
    end

    flyAway = function()
        local changeImage = cycleFlyingImages()
        local imageTimer = timer.performWithDelay(150, changeImage, 0)

        local screenWidth = display.actualContentWidth
        local flyOffTargetX = owl.x > screenWidth / 2 and -50 or screenWidth + 50

        if flyOffTargetX == -50 then
            owl.xScale = -1
        else
            owl.xScale = 1
        end
        owl.yScale = 1

        physics.addBody(owl.anchor, "static", {radius = 120, isSensor = true})
        owl.anchor.physicalBodyExists = true

        owl.transition = transition.to(owl, {
            time = 1500,
            x = flyOffTargetX,
            onComplete = function()
                timer.cancel(imageTimer)
                owl.timer = timer.performWithDelay(flyBackTime, flyBack)
            end
        })
    end

    flyBack = function()
        local changeImage = cycleFlyingImages()
        local imageTimer = timer.performWithDelay(150, changeImage, 0)

        owl.xScale = owl.xScale * -1

        owl.transition = transition.to(owl, {
            time = 1500,
            x = owl.anchor.x,
            onComplete = function()
                local character = gs:getState("character")
                if character ~= nil and character._obj.swingable ~= nil and character._obj.swingable.id == owl.anchor.id then 
                   character:release()
                end

                timer.cancel(imageTimer)
                owl.fill = owlImages[3]  -- Corrected array name
                owl.xScale = owl.xScale * 0.7
                owl.yScale = owl.yScale * 0.7

                physics.removeBody(owl.anchor)
                owl.anchor.physicalBodyExists = false

                owl.timer = timer.performWithDelay(perchedTime, flyAway)
            end
        })
    end

    owl.timer = timer.performWithDelay(perchedTime, flyAway)
end

function Owl:delete()
    local owl = self._obj
    if owl.deleted then return end

    timer.cancel( owl.timer )
    transition.cancel( owl.transition )
    owl:removeSelf()
    owl.deleted = true
end

return Owl