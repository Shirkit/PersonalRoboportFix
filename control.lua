-- Configuration

TICKS = 20 -- Every X ticks the mod will run an update. The higher X is, the less CPU it consumes, but the slower the mod gets. Default: 20

-- Do not edit from here below

require "defines"
require "util"

script.on_init(function(event)

	initContent()
end)

script.on_event(defines.events.on_player_created, function(event)
	
	initContent()
end)

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

--[[

global.roboports[string]
- modules[] = name of the module

]]--

script.on_event(defines.events.on_tick, function(event)

	if event.tick %TICKS == 0 then
	
		for i,player in ipairs(game.players) do
			
			if player.controller_type == defines.controllers.character then
			
				local playerNetwork = nil
				local playerCell = nil
				for k,network in ipairs(player.force.logistic_networks[player.surface.name]) do
					local cell = network.find_cell_closest_to(player.position)
					if cell ~= nil and cell.mobile and cell.owner == player.character then
						playerNetwork = network
						playerCell = cell
					end
				end
				
				if playerNetwork ~= nil then
					-- This passes even if all equipments are disabled
										
					local roboport = getPersonalRoboport(player)
					local grid = getArmorGrid(player)
					local inRange = isInRoboportRange(player)
					
					while roboport[i] ~= nil do
						if roboport[i].name == "personal-roboport-equipment-off" then
							-- roboport is turned off
							if not inRange then
								local prevEnergy = roboport[i].energy
								local pos = roboport[i].position
								-- Swap items and properties
								grid.take( {position = pos} )
								local put = grid.put({name = global.roboports[player.name].modules[i], position = pos})
								put.energy = prevEnergy
							end
						else
							-- roboport is turned on
							if playerCell.stationed_construction_robot_count == playerNetwork.all_construction_robots then
								if inRange then
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
					end -- end while
				end
			end
		end -- end for
	end
	
end)

--[[
 Returns a list of equipments or nil if not found
 ]]--
function getPersonalRoboport(player)
	local grid = getArmorGrid(player)
	local i = 1
	local arr = { }
	
	if grid ~= nil then
		local equips = grid.equipment
		for v,k in ipairs(equips) do
			if (k.type == "roboport-equipment") then
				arr[i] = k
				i = i + 1
			end
		end
	end
	
	if i == 1 then
		return nil
	else
		return arr
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
function isInRoboportRange(player)
	--Find Roboports
	
	for k,network in ipairs(player.force.logistic_networks[player.surface.name]) do
		local mainCell = network.find_cell_closest_to(player.position)
		if not mainCell.mobile then
			-- We just ignore the personal roboport
			return mainCell.is_in_construction_range(player.position)
		end
	end
	
	return false
end

function debugLog(id,message)
	for i,player in ipairs(game.players) do
		if true then -- set for debug
			if (message ~= nil and type(message) ~= "table") then
				player.print(game.tick .. ": " .. id .. "-"  .. tostring(message))
			elseif (message == nil and type(id) ~= "table") then
				player.print(game.tick .. ": " .. tostring(id))
			end
		end
	end
end