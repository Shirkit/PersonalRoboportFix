require "defines"
require "util"

function initContent()
	if global.roboports == nil then
		global.roboports = { }
	end
	
	for i,player in ipairs(game.players) do
		if global.roboports[player.name] == nil then
			global.roboports[player.name] = false
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


game.on_event(defines.events.on_tick, function(event)

	if event.tick %15 == 7 then
	
		local surface = game.get_surface(1)
		for i,player in ipairs(game.players) do
			
			local roboport = getPersonalRoboport(player)
			if roboport ~= nil then
				local grid = getArmorGrid(player)
				
				if roboport.name == "personal-roboport-equipment-off" then
					-- roboport is turned off
					if not isInRoboportRange(surface, player.position) then
						local prevEnergy = roboport.energy
						grid.take(roboport)
						local put = grid.put({name = global.roboports[player.name]})
						put.energy = prevEnergy
						-- turn it on
					end
				else
					-- we have a roboport turned on
					if (countRobots(player) >= 10) then
						if (isInRoboportRange(surface, player.position)) then
							local prevEnergy = roboport.energy
							global.roboports[player.name] = grid.take(roboport).name
							local put = grid.put({name = "personal-roboport-equipment-off"})
							put.energy = prevEnergy
							-- turn it off
						end
					end
				end
			end
		end
	end
	
end)

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


-- Returns a Lua/Equipment or nil if not found
function getPersonalRoboport(player)
	local grid = getArmorGrid(player)
	if grid ~= nil then
		local equips = grid.equipment
		for v,k in ipairs(equips) do
			if (k.type == "roboport-equipment") then
				return k
			end
		end
	end
	return nil
end

function getArmorGrid(player)
	local armor = player.get_inventory(defines.inventory.player_armor)
	if armor ~= nil and armor[1].has_grid then
		return armor[1].grid
	end
	return nil
end

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

function debugLog(message)
	for i,player in ipairs(game.players) do
		if true then -- set for debug
			if type(message) ~= "table" then
				player.print(game.tick .. ": " .. tostring(message))
			end
		end
	end
end