require "TimedActions/ISBaseTimedAction"


ISPaintVehicleAction = ISBaseTimedAction:derive("ISPaintVehicleAction")


function ISPaintVehicleAction:isValid()
    if self.vehicle:isInArea(self.area, self.character) and self.paintItems and self.paintBrush then
        for _, paint in ipairs(self.paintItems) do
            if not paint.paintCan then
                return false    
            elseif paint.paintCan:getUsedDelta() < (paint.paintCan:getUseDelta() * paint.uses) then
                return false
            end
        end
        return true
    else
        return false
    end
end

function ISPaintVehicleAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end


function ISPaintVehicleAction:start()
    self:setActionAnim(CharacterActionAnims.Paint)
    self:setOverrideHandModels(self.paintBrush:getType(), nil)
end


function ISPaintVehicleAction:update()
    self.paintBrush:setJobDelta(self:getJobDelta())
end

function ISPaintVehicleAction:stop()
    self.paintBrush:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end


function ISPaintVehicleAction:perform()
	for _, paint in ipairs(self.paintItems) do
        paint.paintCan:setUsedDelta(paint.paintCan:getUsedDelta() - (paint.paintCan:getUseDelta() * paint.uses))
    end

    self.vehicle:setSkinIndex(self.skinIndex)
    self.vehicle:updateSkin()
    local args = {
        vehicle = self.vehicle:getId(),
        index = self.skinIndex,
    }
    sendClientCommand(self.character, 'vehicle', 'setSkinIndex', args)
    -- sendClientCommand(self.character, 'commonlib', 'updatePaintVehicle', {vehicle = self.vehicle:getId(), index = self.skinIndex})
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
    self.paintBrush:setJobDelta(0.0)
end

function ISPaintVehicleAction:create()
    ISBaseTimedAction.create(self)
end

function ISPaintVehicleAction:new(character, vehicle, area, skinIndex, paintBrush, paintItems)
    if type(character) == 'number' then
        character = getSpecificPlayer(character)
        -- getSpecificPlayer param as int (player num).
    end
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.stopOnWalk = true
    o.stopOnRun = true
    o.character = character
    o.paintItems = paintItems
    o.paintBrush = paintBrush
    o.vehicle = vehicle
    o.area = area
    o.skinIndex = skinIndex
    o.maxTime = 0
    for _, paint in ipairs(paintItems) do
        o.maxTime = o.maxTime + (paint.uses * 100)
    end
    return o
end
