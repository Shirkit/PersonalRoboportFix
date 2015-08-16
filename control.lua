-- Configuration

TICKS = 20 -- Every X ticks the mod will run an update. The higher X is, the less CPU it consumes, but the slower the mod gets. Default: 20

-- Do not edit from here below

require "defines"
require "util"

function initContent()
	if global.roboports == nil then
		global.roboports = { }
	end
	
	for i,player in ipairs(game.players) do
		if global.roboports[player.name] == nil or global.roboports[player.name] == false then
			global.roboports[player.name] = { modules = { } }
		end
	end
end

game.on_init(function(event)

	initContent()
end)

game.on_load(function(event)
	
	initContent()
end)

game.on_event(defines.events.on_player_created, function(event)
	
	initContent()
end)

--[[

global.roboports[string]
- modules[] = name of the module

]]--


game.on_event(defines.events.on_tick, function(event)

	if event.tick %TICKS == 0 then
	
		for i,player in ipairs(game.players) do
			
			local result = getPersonalRoboport(player)
			if result ~= nil then
				
				local surface = game.get_surface(1)
				local roboport = result.equips
				local grid = getArmorGrid(player)
				local i = 1
				
				while roboport[i] ~= nil do
					if roboport[i].name == "personal-roboport-equipment-off" then
						-- roboport is turned off
						if not isInRoboportRange(surface, player.position) then
							local prevEnergy = roboport[i].energy
							local pos = roboport[i].position
							-- Swap items and properties
							grid.take( {position = pos} )
							local put = grid.put({name = global.roboports[player.name].modules[i], position = pos})
							put.energy = prevEnergy
						end
					else
						-- roboport is turned on
						if (countRobots(player) >= result.bots) then
							if (isInRoboportRange(surface, player.position)) then
								local prevEnergy = roboport[i].energy
								local pos = roboport[i].position
								-- Swap items and properties
								global.roboports[player.name].modules[i] = grid.take( {position = pos} ).name
								local put = grid.put( {name = "personal-roboport-equipment-off", position = pos} )
								put.energy = prevEnergy
							end
						end
					end
					
					i = i + 1
				end
			end
		end
	end
	
end)

-- Returns the number of robots in the player's main inventory and quickbar
function countRobots(player)

	local quick = player.get_inventory(defines.inventory.player_quickbar)
	local main = player.get_inventory(defines.inventory.player_main)
	local count = 0
	
	for i=1,#quick do
		if quick[i] ~= nil and quick[i].valid_for_read then
			if quick[i].name == "construction-robot" then
				count = count + quick[i].count
			end
		end
	end
	
	for i=1,#main do
		if main[i] ~= nil and main[i].valid_for_read then
			if main[i].name == "construction-robot" then
				count = count + main[i].count
			end
		end
	end
	
	return count
end


--[[
 Returns a struct or nil if not found
{
	count = number of roboports
	equips[] = array of Lua/Equipment
	bots = maximum number of bots
 }
 ]]--
function getPersonalRoboport(player)
	local grid = getArmorGrid(player)
	local i = 1
	local bot = 0
	local arr = { }
	
	if grid ~= nil then
		local equips = grid.equipment
		for v,k in ipairs(equips) do
			if (k.type == "roboport-equipment") then
				arr[i] = k
				bot = bot + 10
				i = i + 1
			end
		end
	end
	
	if i == 1 then
		return nil
	else
		return { count = i - 1, bots = bot, equips = arr }
	end
end

-- Returns a Lua/EquipmentGrid of the current's player armor
function getArmorGrid(player)
	local armor = player.get_inventory(defines.inventory.player_armor)
	if armor ~= nil and armor[1].valid_for_read and armor[1].has_grid then
		return armor[1].grid
	end
	return nil
end

-- Checks if player is inside a construction network
function isInRoboportRange(surface,position)
	--Find Roboports
	local entities = surface.find_entities_filtered{area = {{position.x - 51, position.y - 51}, {position.x + 51, position.y + 51}}, type = "roboport"}
	for i, entity in ipairs(entities) do
		if entity ~= nil and entity.valid then
			return true
		end
	end
	return false
end

-- Just here for debug
function debugLog(message)
	for i,player in ipairs(game.players) do
		if true then -- set for debug
			if type(message) ~= "table" then
				player.print(game.tick .. ": " .. tostring(message))
			end
		end
	end
end