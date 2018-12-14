local storage = minetest.get_mod_storage()
citylimits = minetest.deserialize(storage:get_string("citylimits")) or {}
cityspawns = minetest.deserialize(storage:get_string("cityspawns")) or {}

if minetest.get_modpath("wiki") then 
	dofile(minetest.get_modpath("citylimits").."/wiki.lua")
end

minetest.register_privilege("passport", {
  "Allows player to leave city limits", give_to_singleplayer = true
})


-- Functions
function load_file(fname, tname)
	local file, err = io.open(fname, "r")
	if not err then
		local tbl = minetest.deserialize(file:read())
		return tbl
	else minetest.log("ERROR [Citylimits] "..err)
	end
end

function write_file(fname, entry)
	local entry = minetest.serialize(entry)
	local file, err = io.open(fname, "w")
	if not err then
		file:write(entry); file:flush(); file:close()
	else minetest.log("ERROR [Citylimits] "..err)
	end
end

function store_table(key, tbl)
	storage:set_string(key, minetest.serialize(tbl))
end

function is_city(cname)
	if citylimits[cname] then
		return cname
	else return false
	end
end

function area_to_city(pname, areaID)
	local cname = ""
	local msg = "City saved!"
	local area = {}
	local areaID = tonumber(areaID)
	if areas.areas[areaID] ~= nil then
		area = areas.areas[areaID]
	else return minetest.chat_send_player(pname, "Invalid area ID number!")
	end
	cname = area["name"]
	if is_city(cname) then
		return minetest.chat_send_player(pname, "City by this name already exists. /remove_city or choose another rename area first.")
	end
	citylimits[cname] = {}
	citylimits[cname]["founder"] = area["owner"]
	citylimits[cname]["pos1"] = area["pos1"]
	citylimits[cname]["pos2"] = area["pos2"]
	
	minetest.chat_send_player(pname, msg)
	store_table("citylimits", citylimits)
	minetest.log("[Citylimits]: ".. area.owner .. " saved city, " .. cname)
	if minetest.get_modpath("wiki") then
		create_wiki_page(pname, cname)
	end
end

function set_city(pname, cname)
	local msg = "City saved!"
	local pos1, pos2 = areas.pos1[pname], areas.pos2[pname]
	if cname == "" then
		return minetest.chat_send_player(pname, "You must name the city")
	end
	if pos1 == nil or pos2 == nil then
		return minetest.chat_send_player(pname, "You must define citylimits with /area_pos commands.")
	end
	if is_city(cname) then
		return minetest.chat_send_player(pname, "A city by this name already exists. /remove_city or choose another name.")
	end
	citylimits[cname] = {}
	citylimits[cname]["founder"] = pname
	citylimits[cname]["pos1"] = pos1
	citylimits[cname]["pos2"] = pos2
		
	minetest.chat_send_player(pname, msg)
	store_table("citylimits", citylimits)
	minetest.log("[Citylimits]: ".. pname .. " saved city, " .. cname)
	if minetest.get_modpath("wiki") then
		create_wiki_page(pname, cname)
	end
end

function to_nearest_spawn(pname)
	local spawn = minetest.deserialize(minetest.setting_get("static_spawn")) or {x=0, y=20, z=0}
	local player = minetest.get_player_by_name(pname)
	local pos = player:get_pos()
	local dist = {}
	local cspawnname = ""
	
	if cityspawns ~= {} then
		for k, v in pairs(cityspawns) do
			local cspawn = v
			local d = math.sqrt((pos.x-cspawn.x)^2+(pos.y-cspawn.y)^2+(pos.z-cspawn.z)^2)
			minetest.log(k)
			local entry = {d, k}
			table.insert(dist, entry)
		end
		while #dist > 1 do
			if dist[1][1] <= dist[2][1] then
				table.remove(dist, 2)
			else table.remove(dist, 1)
			end
		end
		if #dist == 1 then
			cspawnname = dist[1][2]
			player:setpos(cityspawns[cspawnname])
			return minetest.chat_send_player(pname, "You are outside city limits. Travelling to "..cspawnname..".")
		end
	end
	player:setpos(spawn)
	return minetest.chat_send_player(pname, "You are outside city limits. Travelling to spawn.")
end

function is_in_city(pos)
	if citylimits ~= {} then
		for k, v in pairs(citylimits) do
			local cityname = k
			local pos1, pos2 = v.pos1, v.pos2
			local x1, x2, y1, y2, z1, z2
			if pos1.x <= pos2.x then
					x1, x2 = pos1.x, pos2.x
			else x1,x2 = pos2.x, pos1.x
			end
			if pos1.y <= pos2.y then
				y1, y2 = pos1.y, pos2.y 
			else y1, y2 = pos2.y, pos1.y
			end
			if pos1.z <= pos2.z then
				z1, z2 = pos1.z, pos2.z
			else z1, z2 = pos2.z, pos1.z
			end	
			
			if pos.x>= x1 and pos.x <= x2
			and pos.y >= y1 and pos.y <= y2
			and pos.z >= z1 and pos.z <= z2 then 
				return cityname
			end
		end
	end
	return false
end

function spawnlist(name)
	local list = "Spawn List: "
	for k in pairs(cityspawns) do
		local sname = k 
		list = list .. sname .." "
	end
	minetest.chat_send_player(name, list)
end

-- Chat commands
minetest.register_chatcommand("areatocity", {
	params = "<Areas ID>",
	privs = {passport=true},
	description = "Adds/modifies protected area's citylimits record",
	func = function(name, param)
		area_to_city(name, param)
	end
})

minetest.register_chatcommand("setcity", {
	params = "<City name>",
	description = "Adds/modifies citylimits record",
	privs = {passport=true},
	func = function(name, param)
		set_city(name, param)	
	end
})

minetest.register_chatcommand("setcityspawn", {
	params = "<Spawn_Name>",
	description = "Sets a spawn location",
	privs = {passport=true},
	func = function(name, param)
		local spawnname = param
		local player = minetest.get_player_by_name(name)
		local pos = player:getpos()
		if spawnname == "" or nil then
			return minetest.chat_send_player(name, "You must include the spawn name when setting the spawn")
		elseif cityspawns[spawnname] then
			return minetest.chat_send_player(name, "A spawn by this name already exists. /remove_spawn or choose another name.")
		end
				
		cityspawns[spawnname] = pos
		if minetest.get_modpath("wiki") then
			wiki_record_spawn(spawnname, pos)
		end	
		store_table("cityspawns", cityspawns)	
		return minetest.chat_send_player(name, "Spawn saved!")	
	end
})

minetest.register_chatcommand("spawnlist", {
	params = "",
	description = "Lists of available spawns",
	func = function(name, param)
		spawnlist(name)
	end
})


minetest.register_chatcommand("goto", {
	params = "<Spawn_Name>",
	description = "Spawns player in specified spawn",
	func = function(name, param)
		if cityspawns[param] then
			minetest.get_player_by_name(name):setpos(cityspawns[param])
			minetest.chat_send_player(name, "Traveling to ".. param)
			if minetest.get_modpath("wiki") then
				local page = is_in_city(cityspawns[param])
				if page ~= false then
					show_wiki(name, page)
				end
			end
		elseif param == "" then
		 minetest.chat_send_player(name, "Please specify the destination you want to go to. See: /spawnlist to see all available spawn points.")
		else minetest.chat_send_player(name, "Not a valid spawn spawn name. See /spawnlist")
		end
	end
}) 

minetest.register_chatcommand("whereis", {
	params = "<Player_Name>",
	description = "Returns name of city and coordinates where player is located",
	func = function(name, param)
		local pname
		if param == "" then
			pname = name
		else pname = param
			if not minetest.get_player_by_name(pname):is_player_connected(pname) then
				return minetest.chat_send_player(name, "Not a valid player name or player is not connected.")
			end
		end
		ppos = minetest.get_player_by_name(pname):getpos()
		local x,y,z = math.floor(ppos.x), math.floor(ppos.y), math.floor(ppos.z)
		local city = is_in_city(ppos)
		if city ~= false then
			minetest.chat_send_player(name, pname.." is located at "..x..", "..y..", "..z..", in "..city..".")
		end
	end
})

minetest.register_chatcommand("removecity", {
	params = "<City Name>",
	description = "Removes City from city limits",
	privs = {passport = true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, "Select a city to remove")
		elseif not citylimits[param] then
			minetest.chat_send_player(name, "Invalid city name")
		else
			citylimits[param] = nil
			store_table("citylimits", citylimits)
			minetest.chat_send_player(name, param .. " removed from city limits")
		end
	end
})

minetest.register_chatcommand("removespawn", {
	params = "<Spawn Name>",
	description = "Removes spawnpoint from spawn list",
	privs = {passport = true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, "Select a spawnpoint to remove")
		elseif not cityspawns[param] then
			minetest.chat_send_player(name, "Invalid spawn name!")
		else
			cityspawns[param] = nil
			store_table("cityspawns", cityspawns)
			minetest.chat_send_player(name, param.." removed from spawn list")
		end
	end
})
-- Enforce City Limits

local timer = 0

minetest.register_globalstep(function(dtime)
	timer = timer + dtime
	-- Every 3 seconds
	if timer < 3 then return
	else	
		for _, player in ipairs(minetest.get_connected_players()) do
			local name, pos = player:get_player_name(), player:get_pos()
			if not minetest.get_player_privs(player:get_player_name()).passport then -- Do nothing
				if citylimits ~= {} then
					if is_in_city(pos) == false then	
						to_nearest_spawn(name)
						minetest.log("[Citylimits]: ".. player:get_player_name().." found outside of citylimits. Relocating to nearest spawn")
					end
				end	
			end
		end
		timer = 0
	end
end)

