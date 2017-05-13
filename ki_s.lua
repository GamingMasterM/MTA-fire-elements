addEvent("fireElementKI:getUpdatedFires", true)
local tblFireRoots = {}
local setting_coords_per_fire = 2 -- how many coordinates a single fire occupies


--//
--||  useful functions
--\\

function math.round(number, decimals, method)
    decimals = decimals or 0
    local factor = 10 ^ decimals
    if (method == "ceil" or method == "floor") then return math[method](number * factor) / factor
    else return tonumber(("%."..decimals.."f"):format(number)) end
end

function table.copy(tab, recursive)
    local ret = {}
    for key, value in pairs(tab) do
        if (type(value) == "table") and recursive then ret[key] = table.copy(value)
        else ret[key] = value end
    end
    return ret
end

--//
--||  createFireRoot
--\\

function createFireRoot(iX, iY, iW, iH)
    iW = math.min(math.round(iW), 15*setting_coords_per_fire)
    iH = math.min(math.round(iH), 15*setting_coords_per_fire)
    local uSyncedElement = createRadarArea(iX, iY, iW, iH)
        setRadarAreaFlashing(uSyncedElement, true)
    tblFireRoots[uSyncedElement] = {
        iX = iX,
        iY = iY,
        iW = iW,
        iH = iH,
        max_i = iW / setting_coords_per_fire,
        max_v = iH / setting_coords_per_fire,
        iStartTime = getTickCount(),
        uUpdateTimer = setTimer(updateFireRoot, 10000, 0, uSyncedElement),
        tblFireElements = {},
        tblFireSizes = {},
    }

    for index = 1, math.sqrt(iW*iH)/setting_coords_per_fire do
        local i, v = math.random(0, iW/setting_coords_per_fire), math.random(0, iH/setting_coords_per_fire)
        updateFireInRoot(uSyncedElement, i, v, 1)
    end
    return uSyncedElement
end


--//
--||  updateFireRoot
--\\

function updateFireRoot(uRoot)
    if tblFireRoots[uRoot] then
        local tblFires_old = table.copy(tblFireRoots[uRoot].tblFireSizes)
        for i = 0, tblFireRoots[uRoot].max_i do
            for v = 0, tblFireRoots[uRoot].max_v do
                local tr = getFireSizeInRoot(uRoot, i+1, v+1, tblFires_old) or 0
                local t = getFireSizeInRoot(uRoot, i, v+1, tblFires_old) or 0
                local tl = getFireSizeInRoot(uRoot, i-1, v+1, tblFires_old) or 0
                local br = getFireSizeInRoot(uRoot, i+1, v-1, tblFires_old) or 0
                local b = getFireSizeInRoot(uRoot, i, v-1, tblFires_old) or 0
                local bl = getFireSizeInRoot(uRoot, i-1, v-1, tblFires_old) or 0
                local r = getFireSizeInRoot(uRoot, i+1, v, tblFires_old) or 0
                local l = getFireSizeInRoot(uRoot, i-1, v, tblFires_old) or 0

                local sum = tr+t+tl+br+b+bl+r+l  -- min = 0, max = 9*3=
                local max_size = math.max(tr, t, tl, br, b, bl, r, l)
                local cur_size = getFireSizeInRoot(uRoot, i, v, tblFires_old) or 0
                local unique_fires = math.ceil(sum/3)

                local new_size = 0 --TODO: clean up code
    
                if cur_size == 1 and unique_fires > 0 then 
                    new_size = 2
                end
                if cur_size >= 2 and unique_fires > 3 then 
                    new_size = 3
                end
                if cur_size == 0 and unique_fires > 0 and unique_fires < 3 and max_size > 1 then 
                    new_size = 1
                end
                if cur_size == 3 and sum > 9 then 
                    new_size = 2 
                end

                new_size = math.min(3, math.max(0, new_size))
                updateFireInRoot(uRoot, i, v, new_size)
            end
        end
    end
    --[[if tblFireRoots[uRoot] then
        if getElementSyncer(uRoot) then
            local uSyncer = getElementSyncer(uRoot)
            triggerClientEvent(uSyncer, "fireElementKI:calculateFireUpdates", uSyncer, tblFireRoots[uRoot].tblFires, tblFireRoots[uRoot].iNotSynced + 1)
            tblFireRoots[uRoot].iNotSynced = 0
        else
            tblFireRoots[uRoot].iNotSynced = tblFireRoots[uRoot].iNotSynced + 1
        end
    end]]
end


function updateFireInRoot(uRoot, i, v, iNewSize, bDontDestroyElement)
    if tblFireRoots[uRoot] then
        if (i >= 0 and i <= tblFireRoots[uRoot].max_i) and (v >= 0 and v <= tblFireRoots[uRoot].max_v) then
            if iNewSize ~= tblFireRoots[uRoot].tblFireSizes[i..","..v] then
                if iNewSize == 0 then -- fire will be deleted
                    if isElement(tblFireRoots[uRoot].tblFireElements[i..","..v]) then
                        if not bDontDestroyElement then destroyFireElement(tblFireRoots[uRoot].tblFireElements[i..","..v]) end
                        tblFireRoots[uRoot].tblFireElements[i..","..v] = nil
                        tblFireRoots[uRoot].tblFireSizes[i..","..v] = nil
                    end
                else -- new fire or fire changes size
                    if not isElement(tblFireRoots[uRoot].tblFireElements[i..","..v]) then
                        tblFireRoots[uRoot].tblFireElements[i..","..v] = createFireElement(tblFireRoots[uRoot].iX + i*setting_coords_per_fire, tblFireRoots[uRoot].iY + v*setting_coords_per_fire, 4, iNewSize, false, uRoot, i, v)
                    else
                        setFireSize(tblFireRoots[uRoot].tblFireElements[i..","..v], iNewSize)
                    end
                    tblFireRoots[uRoot].tblFireSizes[i..","..v] = iNewSize
                end
            end
        end
    end
end


function getFireSizeInRoot(uRoot, i, v, tblCustomSizes)
    if tblFireRoots[uRoot] then
        if (i >= 0 and i <= tblFireRoots[uRoot].max_i) and (v >= 0 and v <= tblFireRoots[uRoot].max_v) then
            if tblCustomSizes then 
                return tblCustomSizes[i..","..v] or 0
            else
                return tblFireRoots[uRoot].tblFireSizes[i..","..v] or 0
            end
        end
    end
end


addEventHandler("fireElementKI:getUpdatedFires", resourceRoot, function(tblUpdatedFires)
    for _, uFire in pairs(tblUpdatedFires) do
        increaseFireSize(uFire)
    end
end)


--//
--||  test section
--\\

setTimer(function()
    local r = createFireRoot(0, 50, 30, 30)
end, 50, 1)


