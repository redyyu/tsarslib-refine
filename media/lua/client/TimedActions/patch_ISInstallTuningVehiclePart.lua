require "TimedActions/ISInstallTuningVehiclePart"


function ISInstallTuningVehiclePart:perform()
-- print("ISInstallTuningVehiclePart:perform")
    local inventory = self.character:getInventory()

    local firstCondition = nil

    if self.use then
        
        for itemName, num in pairs(self.use) do
            itemName = itemName:gsub("__", ".")
            local item = inventory:getBestCondition(itemName, TSAR.predicateNotBroken)
            if not firstCondition and item then
                firstCondition = item:getCondition()
            end
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

    local args = {
        vehicle = self.vehicle:getId(), 
        partName = self.part:getId(),
        modelName = self.modelName,
        condition = firstCondition
    }
    
    sendClientCommand(self.character, 'atatuning2', 'installTuning', args)

    local pdata = getPlayerData(self.character:getPlayerNum());
    if pdata ~= nil then
        pdata.playerInventory:refreshBackpacks();
        pdata.lootInventory:refreshBackpacks();
    end
    
    self.vehicle:getEmitter():stopSoundByName(self.sound)
    self.character:playSound(RandomSoundPerform[ZombRand(#RandomSoundPerform) + 1])
    UIManager.getSpeedControls():SetCurrentGameSpeed(1);
    -- needed to remove from queue / start next.
    ISBaseTimedAction.perform(self)
end
