wiki = minetest.get_worldpath().."/wiki/pages/"

-- Adds links to page title "city pages".

function create_wiki_page(name, place)
	
	local content = place .. "\nFounder: "..name.."\nFounded on ".. os.date("%d-%m-%Y")
		.."\nDescription:\nBuilding Guidlines:\nTo Do: \nSpawnpoints: "
	local file, err = io.open(wiki..string.lower(place), "w")
	if err then
		minetest.chat_send_player(name, err)
		return minetest.log("ERROR: [Citylimits] ".. err)
	end
	file:write(content);file:flush();file:close()
	minetest.log("[Citylimits] Wiki page for "..place.." created.")
	
	local link = "["..place.."]"
	for line in io.lines(wiki.."city_pages") do
		if string.match(line, place) then
			return minetest.log("[Citylimits]: Link already exists.")
		end
	end
	local mainpage, err = io.open(wiki.."city_pages", "a")
	if err then
		minetest.chat_send_player(name, err)
		return minetest.log("ERROR: [Citylimits] ".. err)
	end
	--[[if string.match(io.input(wiki.."city_pages"):read(), link) then
		return
	else]]-- 
	mainpage:write(link);mainpage:flush();mainpage:close()
	--end
end

function wiki_record_spawn(sname, pos)
	local page = ""
	if is_in_city(pos) ~= false then
		page = string.lower(is_in_city(pos))
	
		local i, tcontent, scontent = 1, {}, ""
		for lines in io.lines(wiki..page) do
			tcontent[i] = lines
			i=i+1
		end
		for i,v in ipairs(tcontent) do
			local str = v
			if string.match(str, "Spawnpoints:") then
				str = str.." "..sname
				minetest.log(str)
			end
			scontent = scontent..str.."\n"
		end
		local file, err = io.open(wiki..page, "w")
		if err then
			return minetest.log("ERROR: [Citylimits] ".. err)	
		end
		file:write(scontent);file:flush();file:close()
	end
end

function show_wiki(name, page)
	if wiki..page then
		wikilib.show_wiki_page(name, page)
	end
end
