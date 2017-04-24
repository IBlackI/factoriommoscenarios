--A anti-griefing module build by I_IBlackI_I for FactorioMMO
--This module makes a rocket silo unable to be destroyed by regular players
-- and gives admins a tool to make it destroyable again.
-- the rocket auto-launches when there is a satellite in it.


--Function for when a rocket is launched
function rocket_launched(event)
	if event.rocket.get_item_count("satellite") == 0 then
		if (#game.players <= 1) then
			game.show_message_dialog{text = "Know what? You should put a satellite in it next time."}
		else
			for index, player in pairs(game.forces.player.players) do
				player.print("Know what? You should put a satellite in it next time.")
			end
		end
	return
	end
	if not global.satellite_sent then
		global.satellite_sent = {}
	end
	if global.satellite_sent[game.forces.player.name] then
		global.satellite_sent[game.forces.player.name] = global.satellite_sent[game.forces.player.name] + 1   
	else
		game.set_game_state{game_finished=true, player_won=true, can_continue=true}
		global.satellite_sent[game.forces.player.name] = 1
	end
	for index, player in pairs(game.forces.player.players) do
		player.gui.left.rocket_score.destroy()
		if player.gui.top.rocket_stats.caption == "Close Stats" then
			local frame = player.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
			frame.add{name="rocket_count_label", type = "label", caption="Rockets sent: "}
			frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[game.forces.player.name])}
		end
	end
end

--Function to make silo's turn to the admin force and not be able to take damage. 
Event.register(defines.events.on_built_entity, function(event)
local entity = event.created_entity
	if entity.name == "rocket-silo" then
		entity.force = game.forces.Admins
		entity.minable = false
		entity.destructible = false
		--entity.operable = false
	end
end)

--Function for when an admin uses the dummy-selection-tool to make a silo destructable again.
Event.register(defines.events.on_player_selected_area, function(event)
	local index = event.player_index
	local player = game.players[index]
	for i, entity in pairs(event.entities) do
	    if entity.name == "rocket-silo" and player.admin then
			if entity.minable == false then
				entity.destructible = true
				entity.operable = true
				entity.minable = true
				return
			else
				entity.destructible = false
				entity.operable = false
				entity.minable = false
			end
	   end
	end
	
end)

--Debug function to instantly end the game. 
Event.register(defines.events.on_player_alt_selected_area, function(event)
	local index = event.player_index
	local player = game.players[index]
	for i, entity in pairs(event.entities) do
	    if entity.name == "rocket-silo" and player.admin and player.name == "I_IBlackI_I" then
			game.set_game_state{game_finished=true, player_won=true, can_continue=true}
			global.satellite_sent[game.forces.player.name] = 1
	   end
	end
	
end)

-- Functions for adding the silo to the table, or remove them. 
local function rocket_on_creation(event)
	local ent = event.created_entity
	if ent.type == "rocket-silo" then
		table.insert(global.silos, ent)
	end
end
local function rocket_on_destruction(event)
	local ent = event.entity

	if ent.type == "rocket-silo" then
		del_list(global.silos, ent)
	end
end


Event.register(defines.events.on_tick, function(event)
	if (game.tick % 180 == 0) then
		for k, silo in pairs(global.silos) do
			if silo.valid then
				game.surfaces[1].create_entity({name="flying-text", position=silo.position,text=silo.rocket_parts ,color={r=0.5,g=1,b=1}})
				invent = silo.get_inventory(defines.inventory.rocket_silo_rocket)
				if invent ~= nil and not invent.is_empty() then
					if silo.get_item_count("satellite") > 0 then
						silo.launch_rocket()
					end
				end
			else
				table.remove(global.silos, k)
			end
		end
	end
end)

Event.register(-1, function(event)
	global.silos = global.silos or {}
end)

function rocket_player_joined(event)
	local player = game.players[event.player_index]
	rocket_create_button(player.name)
end

function rocket_create_button(player_name)
	local player = game.players[player_name]
	if player.admin then
		if not player.gui.top.rocket then
			player.gui.top.add { name = "rocket", type = "button", caption = "Rocket Tool" }
		end
	end
	if not player.gui.top.rocket_stats then
		player.gui.top.add { name = "rocket_stats", type = "button", caption = "Open Stats" }
	end
end

function rocket_on_gui_click(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	
	if e ~= nil then
		if (e.name == "rocket") then
			p.insert { name = "dummy-selection-tool", count = 1 }
		elseif e.name == "rocket_stats" and e.caption == "Open Stats" then
			e.caption = "Close Stats"
			if p.gui.left.rocket_score then
				p.gui.left.rocket_score.rocket_count.caption = tostring(global.satellite_sent[game.forces.player.name])
			else
				local frame = p.gui.left.add{name = "rocket_score", type = "frame", direction = "horizontal", caption="Score"}
				frame.add{name="rocket_count_label", type = "label", caption="Rockets sent: "}
				frame.add{name="rocket_count", type = "label", caption=tostring(global.satellite_sent[game.forces.player.name])}
			end
		elseif e.name == "rocket_stats" and e.caption == "Close Stats" then
			e.caption = "Open Stats"
			p.gui.left.rocket_score.destroy()
		end
	end
end


Event.register(defines.events.on_entity_died, rocket_on_destruction)
Event.register(defines.events.on_robot_pre_mined, rocket_on_destruction)
Event.register(defines.events.on_preplayer_mined_item, rocket_on_destruction)
Event.register(defines.events.on_built_entity, rocket_on_creation)
Event.register(defines.events.on_robot_built_entity, rocket_on_creation)
Event.register(defines.events.on_rocket_launched, rocket_launched)
Event.register(defines.events.on_gui_click, rocket_on_gui_click)
Event.register(defines.events.on_player_joined_game, rocket_player_joined)