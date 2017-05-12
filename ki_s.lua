addEvent("fireElementKI:getUpdatedFires", true)
local tblFireRoots = {}

function createFireRoot(iX, iY, iZ)
    local uSyncedElement = createPed(7, iX, iY, iZ+4)
    setElementFrozen(uSyncedElement, true)
    tblFireRoots[uSyncedElement] = {
        iStartTime = getTickCount(),
        uUpdateTimer = setTimer(updateFireRoot, 10000, 0, uSyncedElement),
        tblFires = {
            createFireElement(iX, iY, iZ, 1)
        },
        iNotSynced = 0
    }

end


function updateFireRoot(uRoot)
    if tblFireRoots[uRoot] then
        if getElementSyncer(uRoot) then
            local uSyncer = getElementSyncer(uRoot)
            triggerClientEvent(uSyncer, "fireElementKI:calculateFireUpdates", uSyncer, tblFireRoots[uRoot].tblFires, tblFireRoots[uRoot].iNotSynced + 1)
            tblFireRoots[uRoot].iNotSynced = 0
        else
            tblFireRoots[uRoot].iNotSynced = tblFireRoots[uRoot].iNotSynced + 1
        end
    end
end


addEventHandler("fireElementKI:getUpdatedFires", resourceRoot, function(tblUpdatedFires)
    for _, uFire in pairs(tblUpdatedFires) do
        increaseFireSize(uFire)
    end
end)
createFireRoot(956.96625, 1746.76489, 8.64844)