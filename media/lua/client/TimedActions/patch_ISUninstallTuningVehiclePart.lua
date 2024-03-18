require "TimedActions/ISUninstallTuningVehiclePart"


function ISUninstallTuningVehiclePart:perform()
	local vehicleName = self.vehicle:getScript():getName()
    local partName = self.part:getId()
    local inventory = self.character:getInventory()
    local args = {
        vehicle = self.vehicle:getId(), 
        partName = partName,
        modelName = self.modelName
    }
    
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
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISUninstallTuningVehiclePart:new(character, part, time, modelName)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.vehicle = part:getVehicle()
	o.part = part
	o.modelName = modelName
	o.resultTable = resultTable
    o.maxTime = (time - (character:getPerkLevel(Perks.Mechanics) * (time/15))) * 100;
	if character:isTimedActionInstant() then
		o.maxTime = 1;
	end
	if ISVehicleMechanics.cheat then o.maxTime = 1; end
	o.jobType = getText("Tooltip_Vehicle_Uninstalling", part:getInventoryItem():getDisplayName());
    
    -- заполнение переменных из таблицы тюнинга
    local vehicleName = o.vehicle:getScript():getName()
    local partName = part:getId()
    if ATA2TuningTable[vehicleName] 
            and ATA2TuningTable[vehicleName].parts[partName] 
            and ATA2TuningTable[vehicleName].parts[partName][modelName].uninstall then
        local ltable = ATA2TuningTable[vehicleName].parts[partName][modelName].uninstall
        if ltable.sound and GameSounds.isKnownSound(ltable.sound) then
            o.sound = ltable.sound
        else
            o.sound = "ATA2InstallGeneral"
        end
        if ltable.use then
            o.use = ltable.use
        end
        if ltable.animation then
            o.animation = ltable.animation
        end
    end
    
	return o
end

