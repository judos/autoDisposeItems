
require "libs.all"


--[[
 Data used:
	global.version = string(version of the control data, see constants.lua)
	global.players[name] = {
		setItems = { string(item1), string(item2), ... }
	}
]]--

---------------------------------------------------
-- Init
---------------------------------------------------

local function migration()
	local previousVersion = global.version
	if global.version ~= previousVersion then
		info("Previous version: "..previousVersion.." migrated to "..global.version)
	end
end

local function init()
	if not global.players then 
		global.players = { } 
	end
	if not global.version then global.version = modVersion end
	migration()
end

script.on_init(init)
script.on_configuration_changed(init)

---------------------------------------------------
-- Tick
---------------------------------------------------


script.on_event(defines.events.on_tick, function(event)
	
	local playerCount = math.max(120,#game.players)
	
	local player = game.players[game.tick % playerCount]
	if player ~= nil and player.connected and player.character ~= nil then
		updateTrashSlotsForPlayer(player)
	end
	
end)

function updateTrashSlotsForPlayer(player)
	info("updating "..player.name)
	if not global.players[player.name] then
		global.players[player.name] = { setItems = {} }
	end
	local playerData = global.players[player.name]
	
	local trashTable = player.auto_trash_filters
	local requestedItems = table.set{} -- set of currently requested item names
	for slot=1,player.character.request_slot_count do
		local requestedStack = player.character.get_request_slot(slot)
		if requestedStack ~= nil then
			info("found request: "..serpent.block(requestedStack))
			local itemName = requestedStack.name
			trashTable[itemName] = requestedStack.count
			playerData.setItems[itemName] = true
			requestedItems[itemName] = true
		end
	end
	
	-- remove trashed items, that were once requested but now no more
	for itemName,_ in pairs(playerData.setItems) do
		if not requestedItems[itemName] then
			trashTable[itemName] = nil
			playerData.setItems[itemName] = nil
			info("removing trash of "..itemName)
		end
	end
	
	player.auto_trash_filters = trashTable
end

