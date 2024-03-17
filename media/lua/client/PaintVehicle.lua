require "TimedActions/ISCleanVehicleAction.lua"
require "TimedActions/ISPaintVehicleAction.lua"


PaintVehicle = {}
PaintVehicle.ghs = " <RGB:" .. getCore():getGoodHighlitedColor():getR() .. "," .. getCore():getGoodHighlitedColor():getG() .. "," .. getCore():getGoodHighlitedColor():getB() .. "> "
PaintVehicle.bhs = " <RGB:" .. getCore():getBadHighlitedColor():getR() .. "," .. getCore():getBadHighlitedColor():getG() .. "," .. getCore():getBadHighlitedColor():getB() .. "> "

local UNIT_BLEACH = -0.05

local predicateNotBroken = function(item)
	return not item:isBroken()
end


PaintVehicle.getFirstTypeCleaner = function(playerObj)
    local playerInv = playerObj:getInventory()
    
	return playerInv:getFirstTypeRecurse("Mop") or
           playerInv:getFirstTypeEvalRecurse("Broom", predicateNotBroken) or
           playerInv:getFirstTypeRecurse("DishCloth") or
           playerInv:getFirstTypeRecurse("BathTowel")
end


PaintVehicle.onPainting = function(playerObj, vehicle, newSkinIndex, paintBrush, paintItems)
    if paintBrush and paintItems then
        local enough_paintCan = true
        local paintCan = nil
        for _, paint in ipairs(paintItems) do
            paintCan = paint.paintCan
            if not paintCan or round(paintCan:getUsedDelta() / paintCan:getUseDelta()) < paint.uses then
                enough_paintCan = false
            end
        end
        if paintBrush and enough_paintCan then
            ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), paintBrush, true, false)
                                           -- player, HandItem, itemToEquip, asPrimayHand, asTwoHand,
            if paintCan then
                ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), paintCan, true, false)
            end
            ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, "Engine"))
            ISTimedActionQueue.add(ISPaintVehicleAction:new(playerObj, vehicle, "Engine", newSkinIndex, paintBrush, paintItems))
        end
    end
end

PaintVehicle.onCleaning = function(playerObj, vehicle, newSkinIndex, cleaner, bleach, uses)
    if cleaner and bleach then
        ISWorldObjectContextMenu.equip(playerObj, playerObj:getPrimaryHandItem(), cleaner, true, false)
                                       -- player, HandItem, itemToEquip, asPrimayHand, asTwoHand,
        ISWorldObjectContextMenu.equip(playerObj, playerObj:getSecondaryHandItem(), bleach, false, false)
        ISTimedActionQueue.add(ISPathFindAction:pathToVehicleArea(playerObj, vehicle, "Engine"))
        ISTimedActionQueue.add(ISCleanVehicleAction:new(playerObj, vehicle, "Engine", newSkinIndex, cleaner, bleach, uses or 1, UNIT_BLEACH))
    end
end


PaintVehicle.getOrCreatePaintMenu = function(context, optName)
    if not optName then
        optName = getText("ContextMenu_Vehicle_PAINT")
    end

    local paintMenuOpt = context:getOptionFromName(optName)
    local paintSubMenu = nil

    if paintMenuOpt then
        paintSubMenu = context:getSubMenu(paintMenuOpt.subOption)
        if not paintSubMenu then
            paintSubMenu = ISContextMenu:getNew(context)
            context:addSubMenu(paintMenuOpt, paintSubMenu)
        end
    else
        paintMenuOpt = context:addOption(optName, nil, nil)
        paintSubMenu = ISContextMenu:getNew(context)
        context:addSubMenu(paintMenuOpt, paintSubMenu)
    end
    return paintMenuOpt, paintSubMenu
end


PaintVehicle.createPaintMenuOpt = function(paintMenu, playerObj, context, vehicle, skinIndex, optionName, paintTable)
    local playerInv = playerObj:getInventory()
    local paintBrush = playerInv:getFirstTypeRecurse("Paintbrush")
    local paintItems = {}
    local haveAllPaintCan = true
    local paintMenuAvailable = false

    for paint_type, paint_uses in pairs(paintTable) do
        local paint_can = playerInv:getFirstTypeRecurse(paint_type)
        if not paint_can then
            haveAllPaintCan = false
        end
        table.insert(paintItems, {
            name = paint_type,
            paintCan = paint_can,
            uses = paint_uses,
        })
    end

    writeOpt = paintMenu:addOptionOnTop(optionName, 
                                        playerObj,
                                        PaintVehicle.onPainting,
                                        vehicle, 
                                        skinIndex,
                                        paintBrush,
                                        paintItems)
    if vehicle and paintBrush and haveAllPaintCan then
        paintMenuAvailable = true
    else
        writeOpt.toolTip = ISWorldObjectContextMenu.addToolTip()
        writeOpt.toolTip:setName(optionName)
        local desc_write = ""
        local brushScriptItem = ScriptManager.instance:getItem("Base.Paintbrush")
        if paintBrush then
            desc_write = desc_write .. PaintVehicle.ghs .. brushScriptItem:getDisplayName() .. " <LINE> "
        else
            desc_write = desc_write ..  PaintVehicle.bhs .. brushScriptItem:getDisplayName() .. " <LINE> "
            writeOpt.onSelect = nil
            writeOpt.notAvailable = true
        end
        
        for _, paint in ipairs(paintItems) do
            local paintCan = paint.paintCan
            local remain_uses = 0
            if paintCan then
                remain_uses = round(paintCan:getUsedDelta() / paintCan:getUseDelta())
            end

            local paintScriptItem = ScriptManager.instance:getItem(paint.name)
            if remain_uses > paint.uses then
                desc_write = desc_write .. PaintVehicle.ghs..paintScriptItem:getDisplayName()
            else
                desc_write = desc_write .. PaintVehicle.bhs..paintScriptItem:getDisplayName()
                writeOpt.onSelect = nil
                writeOpt.notAvailable = true
            end
            desc_write = desc_write .. " " .. remain_uses .. "/" .. paint.uses.." unit <LINE> "
        end
        
        writeOpt.toolTip.description = desc_write
    end

    return paintMenuAvailable
end


PaintVehicle.createCleanMenuOpt = function(paintMenu, playerObj, context, vehicle, skinIndex, optionName, uses)
    local playerInv = playerObj:getInventory()

    local cleaner = PaintVehicle.getFirstTypeCleaner(playerObj)
    local bleach = playerInv:getFirstTypeRecurse("Bleach")
    local cleanMenuAvailable = false
    if not uses then
        uses = 1
    end

    cleanOpt = paintMenu:addOptionOnTop(optionName,
                                        playerObj, 
                                        PaintVehicle.onCleaning,
                                        vehicle,
                                        skinIndex,
                                        cleaner,
                                        bleach,
                                        uses)

    if vehicle and cleaner and bleach and bleach:getThirstChange() < - (uses * UNIT_BLEACH) then
        --thirst is negative floot, 0.05 is for 1 unit same with clean Blood.
        cleanMenuAvailable = true
    else
        cleanOpt.toolTip = ISWorldObjectContextMenu.addToolTip()
        cleanOpt.toolTip:setName(optionName)
        local desc_clean = ""
        local mopScriptItem = ScriptManager.instance:getItem("Base.Mop")
        local broomScriptItem = ScriptManager.instance:getItem("Base.Broom")
        local dishclothmopScriptItem = ScriptManager.instance:getItem("Base.DishCloth")
        local towelScriptItem = ScriptManager.instance:getItem("Base.BathTowel")

        if cleaner then
            desc_clean = desc_clean ..  PaintVehicle.ghs .. cleaner:getDisplayName() .. " <LINE> "
        else
            local cleaners_name = mopScriptItem:getDisplayName() .. "/".. broomScriptItem:getDisplayName() .. "/" 
            cleaners_name = cleaners_name .. dishclothmopScriptItem:getDisplayName() .. "/" .. towelScriptItem:getDisplayName()

            desc_clean = desc_clean ..  PaintVehicle.bhs .. cleaners_name .. " <LINE> "
            cleanOpt.onSelect = nil
            cleanOpt.notAvailable = true
        end

        local bleachScriptItem = ScriptManager.instance:getItem("Base.Bleach")
        if bleach and bleach:getThirstChange() < (uses * UNIT_BLEACH) then  --thirst is negative floot
            desc_clean = desc_clean .. PaintVehicle.ghs.. bleachScriptItem:getDisplayName() .. " <LINE> "
        else
            desc_clean = desc_clean .. PaintVehicle.bhs.. bleachScriptItem:getDisplayName() .. " <LINE> "
            cleanOpt.onSelect = nil
            cleanOpt.notAvailable = true
        end

        cleanOpt.toolTip.description = desc_clean
    end
    
    return cleanMenuAvailable
end


PaintVehicle.doPrepareOutsideVehicleMenu = function(player, func, context, vehicle, test)
    local playerObj = player
    if type(player) == 'number' then
        playerObj = getSpecificPlayer(player)
    end
    
    local vehicle = playerObj:getVehicle()

    if not vehicle then
        if JoypadState.players[player+1] then
            local px = playerObj:getX()
            local py = playerObj:getY()
            local pz = playerObj:getZ()
            local sqs = {}
            sqs[1] = getCell():getGridSquare(px, py, pz)
            local dir = playerObj:getDir()
            if (dir == IsoDirections.N) then        sqs[2] = getCell():getGridSquare(px-1, py-1, pz); sqs[3] = getCell():getGridSquare(px, py-1, pz);   sqs[4] = getCell():getGridSquare(px+1, py-1, pz);
            elseif (dir == IsoDirections.NE) then   sqs[2] = getCell():getGridSquare(px, py-1, pz);   sqs[3] = getCell():getGridSquare(px+1, py-1, pz); sqs[4] = getCell():getGridSquare(px+1, py, pz);
            elseif (dir == IsoDirections.E) then    sqs[2] = getCell():getGridSquare(px+1, py-1, pz); sqs[3] = getCell():getGridSquare(px+1, py, pz);   sqs[4] = getCell():getGridSquare(px+1, py+1, pz);
            elseif (dir == IsoDirections.SE) then   sqs[2] = getCell():getGridSquare(px+1, py, pz);   sqs[3] = getCell():getGridSquare(px+1, py+1, pz); sqs[4] = getCell():getGridSquare(px, py+1, pz);
            elseif (dir == IsoDirections.S) then    sqs[2] = getCell():getGridSquare(px+1, py+1, pz); sqs[3] = getCell():getGridSquare(px, py+1, pz);   sqs[4] = getCell():getGridSquare(px-1, py+1, pz);
            elseif (dir == IsoDirections.SW) then   sqs[2] = getCell():getGridSquare(px, py+1, pz);   sqs[3] = getCell():getGridSquare(px-1, py+1, pz); sqs[4] = getCell():getGridSquare(px-1, py, pz);
            elseif (dir == IsoDirections.W) then    sqs[2] = getCell():getGridSquare(px-1, py+1, pz); sqs[3] = getCell():getGridSquare(px-1, py, pz);   sqs[4] = getCell():getGridSquare(px-1, py-1, pz);
            elseif (dir == IsoDirections.NW) then   sqs[2] = getCell():getGridSquare(px-1, py, pz);   sqs[3] = getCell():getGridSquare(px-1, py-1, pz); sqs[4] = getCell():getGridSquare(px, py-1, pz);
            end
            for _, sq in ipairs(sqs) do
                vehicle = sq:getVehicleContainer()
                if vehicle then
                    return func(playerObj, context, vehicle, test)
                end
            end
            return
        end
        
        vehicle = IsoObjectPicker.Instance:PickVehicle(getMouseXScaled(), getMouseYScaled())
        if vehicle then
            return func(playerObj, context, vehicle, test)
        end
    end
end