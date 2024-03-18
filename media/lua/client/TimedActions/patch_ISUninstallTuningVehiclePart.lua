require "Tuning2/TimedActions/ISUninstallTuningVehiclePart"

local function ReduceUses(inventoryItem, availableUses)
    inventoryItem:setUsedDelta(inventoryItem:getUsedDelta() - inventoryItem:getUseDelta() * availableUses)
    if inventoryItem:getDrainableUsesInt() < 0 then inventoryItem:setUsedDelta(0.0f) end
end

local RandomSoundPerform = {
    "PrisonMetalDoorBlocked",
    "MetalDoorBlocked",
    "MetalGateBlocked",
    "AddBarricadeMetal",
}

function ISUninstallTuningVehiclePart:perform()
	local vehicleName = self.vehicle:getScript():getName()
    local partName = self.part:getId()
    local inventory = self.character:getInventory()
    local args = { vehicle = self.vehicle:getId(), 
                    partName = partName,
                    modelName = self.modelName }
    sendClientCommand(self.character, 'atatuning2', 'uninstallTuning', args)
    
    if self.use then
        for itemName, num in pairs(self.use) do
            itemName = itemName:gsub("__", ".")
            local item = inventory:getFirstTypeEval(itemName, TSAR.predicateNotBroken)
            if item then
                if item:IsDrainable() then
                    local array = inventory:FindAll(itemName)
                    for i=0,array:size()-1 do
                        item = array:get(i)
                        local availableUses = item:getDrainableUsesInt()
                        if availableUses >= num then
                            ReduceUses(item, num, self.character)
                            num = 0
                        else
                            ReduceUses(item, availableUses, self.character)
                            num = num - availableUses
                        end
                        if num == 0 then break end
                    end
                else
                    for i=1,num do
                        self.character:getInventory():RemoveOneOf(itemName)
                    end
                end
            end
        end
    end
    self.vehicle:getEmitter():stopSoundByName(self.sound)
    self.character:playSound(RandomSoundPerform[ZombRand(#RandomSoundPerform) + 1])
    UIManager.getSpeedControls():SetCurrentGameSpeed(1);

	ISBaseTimedAction.perform(self)
end
