
-- not set = does spread, but does not increase
-- 0 = does not spread
-- 1 does spread and increases
local tblMaterialTypes = {
    --[0] = 0, -- asphalt
    --[1] = 0, -- asphalt
    --[2] = 0, -- asphalt
    [9] = 1, -- grass
}


--//
--||  getGroundOfElement
--||  returns:
--||    iZ = the height of the ground
--||    iMaterial  = the material ID of the ground
--\\

function getGroundOfElement(uElement)
    if isElementStreamedIn(uElement) then
        local iX, iY, iZ = getElementPosition(uElement)
        local iNewZ = getGroundPosition(iX, iY, iZ + 100)
        local tblResult = {processLineOfSight ( iX, iY, iZ+1, iX, iY, iZ-1, true, false, false, true, false, true, false, false, nil, true, false)}
        return iNewZ, tblResult[9]
    end
    return false
end








addEvent("fireElementKI:calculateFireUpdates", true)
addEventHandler( "fireElementKI:calculateFireUpdates", root, function(tblFires, iIterations)
    outputDebugString("updating "..(#tblFires).." fires for "..iIterations.." times.")
    local tblFireUpdates = {}
    for i = 1, iIterations do
        for i, uFire in pairs(tblFires) do
            if isElementStreamedIn(uFire) then
                outputDebugString("updating ".. inspect(uFire))
                local iMaterialID = getFireMaterialID(uFire)
                local iX, iY, iZ = getElementPosition(uFire)
                local iSize = getFireSize(uFire)
                if iSize ~= 3 then 
                    table.insert(tblFireUpdates, uFire)
                end
                --[[if not tblMaterialTypes[iMaterialID] then -- does spread, but does not increase

                elseif tblMaterialTypes[iMaterialID] == 0 then -- does not spread

                elseif tblMaterialTypes[iMaterialID] == 1 then -- does spread and increases

                end]]
            end
        end
    end
    triggerServerEvent("fireElementKI:getUpdatedFires", resourceRoot, tblFireUpdates)
end)




addEventHandler("onClientRender", root, function()
    local iX, iY, iZ = getElementPosition(localPlayer)
    local tblResult = {processLineOfSight ( iX, iY, iZ, iX, iY, iZ-2, true, false, false, true, false, true, false, false, nil, true, false)}
    if tblResult[1] then 
        local iMaterial = tblResult[9]
        dxDrawText("material id: "..iMaterial,500, 500, 500, 500)
    else
        dxDrawText("material id: too high",500, 500, 500, 500)
    end

    for i, uArea in pairs(getElementsByType("radararea")) do
        local iX, iY = getElementPosition(uArea)
        local iW, iH = getRadarAreaSize(uArea)
        local iZ1 = getGroundPosition(iX, iY, 500) + 5
        local iZ2 = getGroundPosition(iX+iW, iY, 500) + 5
        local iZ3 = getGroundPosition(iX, iY+iH, 500) + 5
        local iZ4 = getGroundPosition(iX+iW, iY+iH, 500) + 5
        dxDrawLine3D(iX, iY, iZ1, iX+iW, iY, iZ2)
        dxDrawLine3D(iX, iY, iZ1, iX, iY+iH, iZ3)
        dxDrawLine3D(iX+iW, iY, iZ2, iX+iW, iY+iH, iZ4)
        dxDrawLine3D(iX, iY+iH, iZ3, iX+iW, iY+iH, iZ4)
    end
    
end)


--peds get streamed in at distance 246, streamd out at 298
--ground height available up to 300 units away