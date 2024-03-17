require "TimedActions/ISBaseTimedAction"


ISCleanVehicleAction = ISBaseTimedAction:derive("ISCleanVehicleAction")


function ISCleanVehicleAction:isValid()
    return self.vehicle:isInArea(self.area, self.character) and 
           self.bleach and 
           self.bleach:getThirstChange() < self.thirstNeed  --thirst is negative floot.
end

function ISCleanVehicleAction:waitToStart()
    self.character:faceThisObject(self.vehicle)
    return self.character:shouldBeTurning()
end


function ISCleanVehicleAction:update()
    self.cleaner:setJobDelta(self:getJobDelta())
end


function ISCleanVehicleAction:start()
    self:setActionAnim(CharacterActionAnims.Pour)
    self:setOverrideHandModels(self.cleaner:getType(), nil)
end

function ISCleanVehicleAction:stop()
    self.cleaner:setJobDelta(0.0)
    ISBaseTimedAction.stop(self)
end


function ISCleanVehicleAction:perform()
    -- copy from vanilla. ThirstChange is negative floot,
    -- must minus negative number, check if it is >= 0 `:Use` whole bottle.
    -- the sample in vanilla is did samething, only different math.
    --[[
        function ISCleanBlood:perform()
            self.character:stopOrTriggerSound(self.sound)
            local bleach = self.character:getInventory():getItemFromType("Bleach");
            bleach:setThirstChange(bleach:getThirstChange() + 0.05);
            if bleach:getThirstChange() > -0.05 then
                bleach:Use();
            end
            self.square:removeBlood(false, false);
            -- needed to remove from queue / start next.
            ISBaseTimedAction.perform(self);
        end
    ]]--

    self.bleach:setThirstChange(self.bleach:getThirstChange() - self.thirstNeed)  --thirst is negative floot.
    if self.bleach:getThirstChange() >= self.thirstNeed then 
        self.bleach:Use() -- consume the bleach
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
    self.cleaner:setJobDelta(0.0)
end

function ISCleanVehicleAction:create()
    ISBaseTimedAction.create(self)
end

function ISCleanVehicleAction:new(character, vehicle, area, skinIndex, cleaner, bleach, uses, bleach_unit)
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
    o.bleach = bleach
    o.cleaner = cleaner
    o.uses = uses
    o.vehicle = vehicle
    o.area = area
    o.skinIndex = skinIndex
    o.thirstNeed = uses * (bleach_unit or -0.05) --0.05 for 1 unit of bleach, remember thirst is negative floot.
    o.maxTime = uses * 100
    return o
end
