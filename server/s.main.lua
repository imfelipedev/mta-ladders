--// Ladders class

local Ladders = {}

function Ladders:constructor()
    self.using = {}
    self.colshape = {}
    self.player_diff = 0.3
    self.colshape_diff = 2
    self.object_height = 6
    return self:setup()
end

function Ladders:setup()
    self.config = getConfig()

    self.__onPlayerKey__ = function(player, key, state)
        return self:onPlayerKey(player, key, state)
    end

    for i = 1, #self.config.ladders do 
        local ladder = self.config.ladders[i]
        self:create(ladder.x, ladder.y, ladder.z, ladder.r, ladder.dimension, ladder.height)
    end
    return outputDebugString(getResourceName(resource).." - resource started succesfully", 4, 0, 174, 255)
end

function Ladders:create(x, y, z, r, dimension, height)
    local objects = {}
    local total = math.ceil(height / self.object_height)
    local colshape = createColTube(x, y, z -0.9, 0.6, height)
    for i = 1, total do 
        local newX = x + math.cos(math.rad(r + 90)) * 0.55
        local newY = y + math.sin(math.rad(r + 90)) * 0.55
        local newZ = z + (i - 1) * self.object_height
        if i >= total then 
            local overflow = (z + self.object_height) - (z + height)
            newZ = z - overflow
        end

        objects[i] = self:createLadderObject(newX, newY, newZ, r)
    end

    self.colshape[colshape] = { data = { x = x, y = y, z = z, r = r, dimension = dimension, height = height }, element = colshape, objects = objects }
    return colshape
end

function Ladders:destroy(colshape)
    local colshapeCache = self.colshape[colshape]
    if not colshapeCache then 
        return false 
    end

    if colshapeCache.using then 
        self:removePlayerUsing(colshapeCache.using, colshapeCache)
    end

    if isElement(colshapeCache.element) then 
        destroyElement(colshapeCache.element)
    end

    for i = 1, #colshapeCache.objects do 
        if isElement(colshapeCache.objects[i]) then 
            destroyElement(colshapeCache.objects[i])
        end
    end

    self.colshape[colshape] = nil 
    return true
end

function Ladders:createLadderObject(x, y, z, r)
    local object = createObject(1437, x, y, z, 10, 0, r)
    setElementCollisionsEnabled(object, false)
    setObjectBreakable(object, false)
    return object
end

function Ladders:syncPlayerAnimation(player, bool, rotation)
    local players = getElementsByType("player")
    triggerClientEvent(players, "ladders:sync", resourceRoot, player, bool, rotation)
    return true
end

function Ladders:updatePlayerAnimation(player, speed, rotation)
    setPedAnimationSpeed(player, "ladder_up_a", speed)
    setElementRotation(player, 0, 0, rotation, "default", true)
    return true
end

function Ladders:setPlayerAnimation(player)
    setTimer(function(player)
        if isTimer(sourceTimer) then 
            killTimer(sourceTimer)
        end

        setPedAnimationSpeed(player, "ladder_up_a", 0)
    end, 100, 1, player)
    return true
end

function Ladders:isPlayerUsing(player)
    if self.using[player] then 
        return self.using[player]
    end
    return false 
end

function Ladders:addPlayerUsing(player, colshape)
    if self.using[player] then 
        return false 
    end

    local _, _, playerZ = getElementPosition(player)
    self.using[player] = { 
        colshape = colshape,
        object = createObject(1337,  colshape.data.x, colshape.data.y, playerZ)
    }

    colshape.using = player
    self:setPlayerAnimation(player)
    self:setPlayerLadder(player, colshape, true)
    self:syncPlayerAnimation(player, true, colshape.data.r)
    return true
end

function Ladders:removePlayerUsing(player, colshape)
    local playerCache = self.using[player]
    if not playerCache then 
        return false 
    end

    if isElement(playerCache.object) then 
        destroyElement(playerCache.object)
    end

    if self.colshape[playerCache.colshape.element] then 
        self.colshape[playerCache.colshape.element].using = nil
    end

    local _, _, playerZ = getElementPosition(player)
    if colshape and (playerZ + self.colshape_diff) >= (colshape.data.z + colshape.data.height) then 
        local x, y, z = self:getPositionFromElementOffset(player, 0, 1, 0)
        setElementPosition(player, x, y, z + 1, false)
    end

    self.using[player] = nil 
    self:syncPlayerAnimation(player, false, 0)
    self:setPlayerLadder(player, colshape, false)
    return true
end

function Ladders:setPlayerLadder(player, colshape, bool)
    if not bool then
        unbindKey(player, "s", "both", self.__onPlayerKey__)
        unbindKey(player, "w", "both", self.__onPlayerKey__)
        unbindKey(player, "space", "both", self.__onPlayerKey__)
        return true
    end

    local playerCache = self.using[player]
    if not playerCache then 
        return false 
    end

    setElementAlpha(playerCache.object, 0)
    attachElements(player, playerCache.object)
    bindKey(player, "s", "both", self.__onPlayerKey__)
    bindKey(player, "w", "both", self.__onPlayerKey__)
    bindKey(player, "space", "both", self.__onPlayerKey__)
    setElementCollisionsEnabled(playerCache.object, false)
    return false
end

function Ladders:onColShapeHit(colshape, element)
    local colshapeCache = self.colshape[colshape]
    if not colshapeCache then 
        return false 
    end

    if colshapeCache.using then 
        return false 
    end

    local elementType = getElementType(element)
    if elementType ~= "player" then 
        return false 
    end

    local isElementHasVehicle = getPedOccupiedVehicle(element)
    if isElementHasVehicle then
        return false 
    end
    
    local elementDimension = getElementDimension(element)
    if colshapeCache.data.dimension ~= elementDimension then 
        return false 
    end
    return self:addPlayerUsing(element, colshapeCache)
end

function Ladders:onColShapeLeave(colshape, element)
    local colshapeCache = self.colshape[colshape]
    if not colshapeCache then 
        return false 
    end    

    if not colshapeCache.using then 
        return false 
    end

    if colshapeCache.using ~= element then 
        return false 
    end
    return self:removePlayerUsing(element, colshapeCache)
end

function Ladders:onPlayerKey(player, key, state)
    local playerCache = self.using[player]
    if not playerCache then 
        return false 
    end

    if state == "up" then 
        stopObject(playerCache.object)
        return self:updatePlayerAnimation(player, 0, playerCache.colshape.data.r)
    end

    if key == "space" then 
        return self:removePlayerUsing(player, playerCache.colshape) 
    end

    self:updatePlayerAnimation(player, 1, playerCache.colshape.data.r)

    if key == "w" then 
        local time = self:getPlayerTimeAnimation(player, playerCache.colshape, "up")
        local targetZ = (playerCache.colshape.data.z + playerCache.colshape.data.height) + self.colshape_diff
        return moveObject(playerCache.object, time, playerCache.colshape.data.x, playerCache.colshape.data.y, targetZ)
    end

    if key == "s" then 
        local time = self:getPlayerTimeAnimation(player, playerCache.colshape, "down")
        return moveObject(playerCache.object, time, playerCache.colshape.data.x, playerCache.colshape.data.y, playerCache.colshape.data.z)
    end
    return false
end

function Ladders:getPlayerTimeAnimation(player, colshape, state)
    local _, _, playerZ = getElementPosition(player)
    local ladderHeight = colshape.data.z + colshape.data.height
    local totalLaddersObject = math.ceil(colshape.data.height / self.object_height)
    local totalAnimationTime = self.config.main.duration_animation * totalLaddersObject
    if state == "up" then 
        local percentage = (ladderHeight - playerZ) / ladderHeight
        return totalAnimationTime * percentage
    end

    local percentage = (playerZ - colshape.data.z) / ladderHeight
    return totalAnimationTime * percentage
end

function Ladders:getPositionFromElementOffset(element, offX, offY, offZ)
    local m = getElementMatrix(element)
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1]
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2]
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3]
    return x, y, z 
end

--// Export functions

function isPlayerUsingLadder(player)
    return Ladders:isPlayerUsing(player)
end

function removePlayerLadder(player)
    return Ladders:removePlayerUsing(player)
end

function createLadder(x, y, z, r, dimension, height)
    return Ladders:create(x, y, z, r, dimension, height)
end

function destroyLadder(element)
    return Ladders:destroy(element)
end

--// Mta events

addEventHandler("onResourceStart", resourceRoot, function()
    return Ladders:constructor()
end)

addEventHandler("onColShapeHit", resourceRoot, function(element)
    return Ladders:onColShapeHit(source, element)
end)

addEventHandler("onColShapeLeave", resourceRoot, function(element)
    return Ladders:onColShapeLeave(source, element)
end)

addEventHandler("onPlayerQuit", root, function()
    return Ladders:removePlayerUsing(source)
end)

addEventHandler("onPlayerWasted", root, function()
    return Ladders:removePlayerUsing(source)
end)