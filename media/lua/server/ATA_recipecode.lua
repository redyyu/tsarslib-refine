
require "recipecode"

function Recipe.OnCreate.transmitFirstItemCondition(items, result, player)
    if not result:getCondition() then return end

    local fixs = 1  -- getHaveBeenRepaired starts with 1
    local condition = result:getCondition()
    if items:size() > 0 then
        local item = items:get(0)
        local src_condition = item:getCondition() or 0
        if condition > src_condition then
            condition = src_condition
        end
        if item:getHaveBeenRepaired() > fixs then
            fixs = item:getHaveBeenRepaired()
        end
    end
    result:setCondition(condition)
    result:setHaveBeenRepaired(fixs)
end
