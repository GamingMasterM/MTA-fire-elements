--//
--||  PROJECT:  fireElements
--||  AUTHOR:   MasterM
--||  DATE:     October 2015
--\\


--//
--||  useful
--\\

local function destroyElementIfExists(uElement)
	if isElement(uElement) then
		destroyElement(uElement)
		return true
	end
	return false
end


--//
--||  settings
--\\

local setting_tickNoise = false -- tick sound at extinguishing
local setting_smoke = true -- smoke effect at extinguishing
local setting_smokeRenderDistance = 100 -- until which distance the smoke at extinguishing renders


--//
--||  script
--\\

local tblEffectFromFireSize = {
	[1] = "fire",
	[2] = "fire_med",
	[3] = "fire_large",
 
}

local tblFires = {}


--//
--||  destroyFireElement (local)
--||  	parameters:
--||  		uElement	= the fire element
--||  	returns: success of the function
--\\

local function destroyFireElement(uElement)
	if tblFires[uElement] then
		destroyElementIfExists(tblFires[uElement].uEffect)
		destroyElementIfExists(tblFires[uElement].uBurningCol)
		tblFires[uElement] = nil
		return true
	end
	return false
end


--//
--||  handleSmoke (local)
--||  	parameters:
--||  		uFire		= the fire element
--\\

local function handleSmoke(uFire)
	if setting_smoke then
		local iX, iY, iZ	= getElementPosition(localPlayer)
		local iFX, iFY, iFZ = getElementPosition(uFire)
		if getDistanceBetweenPoints3D(iX, iY, iZ, iFX, iFY, iFZ) < setting_smokeRenderDistance then
			if tblFires[uFire] and not tblFires[uFire].uSmokeEffect or getTickCount()-tblFires[uFire].uSmokeEffect > 1000 then
				local iX, iY, iZ = getElementPosition(uFire)
				local effect = createEffect("tank_fire", iX, iY, iZ)
					setEffectSpeed(effect, 0.5)
				tblFires[uFire].uSmokeEffect = getTickCount()
			end
		end
	end
end


--//
--||  handlePedDamage (local)
--||  	parameters:
--||  		uAttacker, iWeap	= event parameters
--\\

local function handlePedDamage(uAttacker, iWeap)
	if tblFires[source] then
		if iWeap == 42 then -- extinguisher
			if setting_tickNoise and uAttacker == localPlayer then playSoundFrontEnd(37) end
			handleSmoke(source)
			if getElementHealth(source) <= (100-10*tblFires[source].iSize) and uAttacker == localPlayer then
				triggerServerEvent("fireElements:requestFireDeletion", source)
			end
		else
			cancelEvent()
		end
	end
end

--//
--||  handlePedWaterCannon (local)
--||  	parameters:
--||  		uPed		= event parameter
--\\

local function handlePedWaterCannon(uPed)
cancelEvent()
	if tblFires[uPed] then
		if getElementModel(source) == 407 then -- fire truck
		handleSmoke(uPed)
			if setting_tickNoise and getVehicleController(source) == localPlayer then playSoundFrontEnd(37) end
			if math.random(1, tblFires[uPed].iSize*5) == 1 and getVehicleController(source) == localPlayer then
				triggerServerEvent("fireElements:requestFireDeletion", uPed)
			end
		end
	end
end
addEventHandler("onClientPedHitByWaterCannon", root, handlePedWaterCannon)


--//
--||  burnPlayer (local)
--||  	parameters:
--||  		uHitElement,bDim	= event parameter
--\\

local function burnPlayer(uHitElement, bDim)
	if not bDim then return end
	if getElementType(uHitElement) == "player" then
		setPedOnFire(uHitElement, true)
	end
end


--//
--||  decreaseFireSize (local)
--||  	parameters:
--||  		iSize			= the new size of the fire
--\\

local function decreaseFireSize(iSize)
	if tblFires[source] then
	tblFires[source].iSize = iSize
	destroyElementIfExists(tblFires[source].uEffect)
	destroyElementIfExists(tblFires[source].uBurningCol)
	local iX, iY, iZ = getElementPosition(source)
	tblFires[source].uEffect = createEffect(tblEffectFromFireSize[iSize], iX, iY, iZ,-90, 0, 0, 20*iSize)
	tblFires[source].uBurningCol = createColSphere(iX, iY, iZ, iSize/4)
	addEventHandler("onClientColShapeHit", tblFires[source].uBurningCol, burnPlayer)
	end
end


--//
--||  createFireElement (local)
--||  	parameters:
--||  		iSize			= the size of the fire
--||  		uPed			= the ped element synced by the server
--\\

local function createFireElement(iSize, uPed)
	if not uPed then uPed = source end
	local iX, iY, iZ = getElementPosition(uPed)
	tblFires[uPed] = {}
	tblFires[uPed].iSize = iSize
	tblFires[uPed].uEffect = createEffect(tblEffectFromFireSize[iSize], iX, iY, iZ,-90, 0, 0, 20*iSize)
	tblFires[uPed].uBurningCol = createColSphere(iX, iY, iZ, iSize/4)
	setElementCollidableWith (uPed, localPlayer, false)
	for index,vehicle in ipairs(getElementsByType("vehicle")) do 
		setElementCollidableWith(vehicle, uPed, false)
	end
	addEventHandler("onClientPedDamage", uPed, handlePedDamage)
	addEventHandler("onClientColShapeHit", tblFires[uPed].uBurningCol, burnPlayer)
end


--//
--||  events
--\\

addEvent("fireElements:onFireCreate", true)
addEventHandler("fireElements:onFireCreate", resourceRoot, createFireElement)
addEvent("fireElements:onFireDestroy", true)
addEventHandler("fireElements:onFireDestroy", resourceRoot, destroyFireElement)
addEvent("fireElements:onFireDecreaseSize", true)
addEventHandler("fireElements:onFireDecreaseSize", resourceRoot, decreaseFireSize)


--//
--||  sync
--\\

addEventHandler("onClientResourceStart", resourceRoot, function()
	addEvent("fireElements:onClientRecieveFires", true)
	addEventHandler("fireElements:onClientRecieveFires", resourceRoot, function(tblFires)
		for i,v in pairs(tblFires) do
			createFireElement(v.iSize, i)
		end
	end)
	triggerServerEvent("fireElements:onClientRequestsFires", root)
end)


setPedTargetingMarkerEnabled(false)
--setDevelopmentMode(true)
