
-- The bug with broken item is cause by `firstCondition = nil` in `ISInstallTuningVehiclePart`
-- when transmit first item condition to part item, that will cause error.


require "Tuning2/ISVehicleTuning2"


function ISVehicleTuning2:getAvailableItemsType(RecipeItem)
    local result = {};
    local recipeListBox = self:getRecipeListBox()
    RecipeItem = RecipeItem or recipeListBox.items[recipeListBox.selected].item
    if RecipeItem.use then
        for _, item_tbl in pairs(RecipeItem.use) do
            local full_type = item_tbl.fullType
            for _, container in pairs(self.containerListLua) do
                if item_tbl.isDrainable then
                    local array = container:FindAll(full_type)
                    local count = 0
                    for i=0,array:size()-1 do
                        local itemFromInventory = array:get(i)
                        local availableUses = itemFromInventory:getDrainableUsesInt()
                        if availableUses > 0 then
                            result[#result+1] = itemFromInventory
                            count = count + availableUses
                        end
                        if count > item_tbl.count then break end
                    end
                    result[full_type] = (result[full_type] or 0) + count
                else
                    -- local count = container:FindAll(full_type):size()
                    local count = container:getCountTypeEval(full_type, TSAR.predicateNotBroken)
                    result[full_type] = (result[full_type] or 0) + count
                end
            end
        end
    end
    if RecipeItem.tools then
        for _, item_tbl in pairs(RecipeItem.tools) do
            local full_type = item_tbl.fullType
            for _, container in pairs(self.containerListLua) do
                -- local arraySize = container:FindAll(full_type):size()
                local count = container:getCountTypeEval(full_type, TSAR.predicateNotBroken)
                result[full_type] = (result[full_type] or 0) + count
            end
        end
    end
    return result
end


function ISVehicleTuning2:getAllRequiredItems(RecipeItem)
    local result = {}
    if RecipeItem.use then
        for _, itemInList in pairs(RecipeItem.use) do
            local full_type = itemInList.fullType
            local count = 0
            for _, container in pairs(self.containerListLua) do
                local items_array = container:FindAll(full_type)
                local items_array = container:getAllTypeEval(full_type, TSAR.predicateNotBroken)
                for i=0, items_array:size()-1 do
                    local itemFromInventory = items_array:get(i)
                    if itemFromInventory:IsDrainable() then
                        local availableUses = itemFromInventory:getDrainableUsesInt()
                        if availableUses > 0 then
                            result[#result+1] = itemFromInventory
                            count = count + availableUses
                        end
                    else
                        result[#result+1] = itemFromInventory
                        count = count + 1
                    end
                    if count > itemInList.count then
                        break
                    end
                end
                if count > itemInList.count then
                    break
                end
            end
        end
    end
    if RecipeItem.tools then
        for _, itemInList in pairs(RecipeItem.tools) do
            local full_type = itemInList.fullType
            local count = 0
            for _, container in pairs(self.containerListLua) do
                local items_array = container:getAllTypeEval(full_type, TSAR.predicateNotBroken)
                for i=0, items_array:size()-1 do
                    result[#result+1] = items_array:get(i)
                    count = count + 1
                    if itemInList.count == count then
                        break
                    end
                end
                if itemInList.count == count then
                    break
                end
            end
        end
    end
    return result
end