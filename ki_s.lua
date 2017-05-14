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

function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys 
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
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

    for index = 1, math.sqrt(iW*iH)/setting_coords_per_fire/3 do
        local i, v = math.random(0, iW/setting_coords_per_fire), math.random(0, iH/setting_coords_per_fire)
        updateFireInRoot(uSyncedElement, i, v, 3)
    end
    return uSyncedElement
end


--//
--||  updateFireRoot
--\\

function updateFireRoot(uRoot)
    if tblFireRoots[uRoot] then
        for sPos, iSize in spairs(tblFireRoots[uRoot].tblFireSizes, function(t,a,b) return t[b] < t[a] end) do
            local i,v = tonumber(split(sPos, ",")[1]), tonumber(split(sPos, ",")[2])
            local tblSurroundingFires = {
                [(i+1)..","..(v+1)] = (getFireSizeInRoot(uRoot, i+1, v+1)   or 0), --tr
                [(i)..","..(v+1)]   = (getFireSizeInRoot(uRoot, i,   v+1)   or 0), --t
                [(i-1)..","..(v+1)] = (getFireSizeInRoot(uRoot, i-1, v+1)   or 0), --tl
                [(i+1)..","..(v-1)] = (getFireSizeInRoot(uRoot, i+1, v-1)   or 0), --br
                [(i)..","..(v-1)]   = (getFireSizeInRoot(uRoot, i,   v-1)   or 0), --b
                [(i-1)..","..(v-1)] = (getFireSizeInRoot(uRoot, i-1, v-1)   or 0), --bl
                [(i+1)..","..(v)]   = (getFireSizeInRoot(uRoot, i+1, v)     or 0), --r
                [(i-1)..","..(v)]   = (getFireSizeInRoot(uRoot, i-1, v)     or 0), --l
            }

            if iSize == 3 then --spawn new fires around size 3 fires
                local iSizeSum = 0
                for sSurroundPos, iSurroundSize in pairs(tblSurroundingFires) do
                    
                    if iSurroundSize == 0 and math.random(1, 3) == 1 then -- spawn new fires
                        local ii, vv = tonumber(split(sSurroundPos, ",")[1]), tonumber(split(sSurroundPos, ",")[2]) 
                        updateFireInRoot(uRoot, ii, vv, 1)
                    else
                        iSizeSum = iSizeSum + iSurroundSize
                    end
                end
                if iSizeSum > 8 then -- let the big fire decay if there is every spot taken
                    if math.random(1,3) == 1 then 
                        updateFireInRoot(uRoot, i, v, 0)
                    else
                        updateFireInRoot(uRoot, i, v, 2)
                    end
                end
            elseif iSize == 2 then
                local iSizeSum = 0
                for sSurroundPos, iSurroundSize in pairs(tblSurroundingFires) do
                    iSizeSum = iSizeSum + iSurroundSize
                end
                if iSizeSum > 8 then -- let the big fire decay if there is every spot surrounding it taken
                    updateFireInRoot(uRoot, i, v, 1)
                elseif iSizeSum > 6 and math.random(1, 2) == 1 then -- increase the size if there are more size 2 fires in its surrounding
                    updateFireInRoot(uRoot, i, v, 3)
                end
            elseif iSize == 1 then
                for sSurroundPos, iSurroundSize in spairs(tblSurroundingFires, function(t,a,b) return t[b] > t[a] end) do -- merge two small fires into one medium fire
                    if iSurroundSize == 1 and math.random(1, 2) == 1 then
                        local ii, vv = tonumber(split(sSurroundPos, ",")[1]), tonumber(split(sSurroundPos, ",")[2]) 
                        updateFireInRoot(uRoot, i, v, 2)
                        updateFireInRoot(uRoot, ii, vv, 0)
                    end
                end
            end
        end
    end
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
                        local iX = tblFireRoots[uRoot].iX + i*setting_coords_per_fire + math.random(-0.7, 0.7)
                        local iY = tblFireRoots[uRoot].iY + v*setting_coords_per_fire + math.random(-0.7, 0.7)
                        local uFe = createFireElement(iX, iY, 4, iNewSize, false, uRoot, i, v)
                        addEventHandler("fireElements:onFireExtinguish", uFe, function(uDestroyer)
                            
                        end)

                        tblFireRoots[uRoot].tblFireElements[i..","..v] = uFe
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
    local r = createFireRoot(-33, 50, 30, 22)
end, 50, 1)


