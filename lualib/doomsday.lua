-- doomsday module. Requires the programmable day-night cycle (pdnc) module to work. 
-- made by Zr4g0n
-- this module currently has issues with the event module and 'on nth tick'. 
require "lualib/pdnc" --is this the best way to do this?
global.doomsday_enabled = true
global.doomsday = global.doomsday or {} -- used to check if this exists. 
global.doomsday_start = 30.75 -- in ingame days. Use n.75 to make sure doomsday is at midnight. 
global.doomsday_pollution = 20000 -- amount to be applied per tick
global.doomsday_surfance = 1
global.doomsday_enable_players_online_compensator = true
global.doomsday_current_fuzzy_playercount = 1.5 -- start assuming 1.5 players! :V

function doomsday_status()
	game.print("Doomsday loaded!")
	game.print("global.doomsday_start: " .. global.doomsday_start)
	game.print("global.doomsday_pollution: " .. global.doomsday_pollution)
	game.print("global.doomsday_surfance: " .. global.doomsday_surfance)
	game.print("global.doomsday_enabled: " .. pdnc_bool_to_string(global.doomsday_enabled))
	game.print("global.doomsday_enable_players_online_compensator: " .. pdnc_bool_to_string(global.doomsday_enable_players_online_compensator))
	game.print("global.doomsday_current_fuzzy_playercount: " .. global.doomsday_current_fuzzy_playercount)
	--game.print(": " .. )
end

function doomsday_toggle()
	global.doomsday_enabled = not global.doomsday_enabled
	doomsday_status()
end

function doomsday_setup()
	doomsday_on_load()
end

function doomsday_on_load()
	commands.add_command("timeleft", "Gives you the time till doomsday!", doomsday_time_left)
	commands.add_command("doomsday", "Prints doomsday status", doomsday_status)
end

function doomsday_core()
	if(global.doomsday_enable_players_online_compensator)then
		doomsday_players_online_compensator()
	end

	local current_time = game.tick / game.surfaces[global.doomsday_surfance].ticks_per_day
	local x = current_time * 6.2831853 --2pi
	local returnvalue = 0
	local radius = 512 --make global
	local pollution = global.doomsday_pollution -- total pollution applied per tick
	local nodes = 16 -- the number of nodes to spread
	if (current_time < global.doomsday_start) then
		returnvalue = math.pow(pdnc_c_boxy(x), (1 + current_time / 4))
		-- days become darker over time towards n^6.125
	elseif (current_time < global.doomsday_start + 1) then
		--global.pdnc_enable_brightness_limit = false
		returnvalue = math.pow(((global.doomsday_start + 1) - current_time), 7)
		doomsday_pollute(radius,pollution,16)
	else
		global.pdnc_enable_brightness_limit = true
		returnvalue = math.pow(pdnc_c_boxy(x), 6.125)--*0.5
	end
	return pdnc_scaler(returnvalue)
end

function doomsday_normal_curve(x)
	return (1+ ((math.sin(x) + (0.111 * math.sin(3 * x))) * 1.124859392575928))/2
	-- magic numbers to make it scale to (-1, 1)
end

function doomsday_pollute(radius,pollution,nodes)
	local p = global.pdnc_stepsize * pollution -- needed to make it 'step size independant'
	p = p / nodes
	local position = {x = 0.0, y = 0.0}
	game.surfaces[global.doomsday_surfance].pollute(position, p) --circle + center point
	local step = (math.pi * 2) / (nodes - 1)
	for i=0, (nodes - 1) do 
		position = {x = math.sin(step*i)*radius, y = math.cos(step*i)*radius}		 
		game.surfaces[global.doomsday_surfance].pollute(position, p)
	end
end

function doomsday_time_left()
	if (global.doomsday_start > 0)then
		local ticks_until_doomsday = game.surfaces[global.doomsday_surfance].ticks_per_day * global.doomsday_start
		local ticks = ticks_until_doomsday - game.tick
		if (ticks >= 0) then 
			local seconds = math.floor(ticks/ 60)
			local minutes = math.floor(seconds / 60)
			local hours = math.floor(minutes / 60)
			local days = math.floor(hours / 24)
			game.print("time until doomsday: " .. string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60))
		else
			ticks = ticks * -1 
			local seconds = math.floor(ticks / 60)
			local minutes = math.floor(seconds / 60)
			local hours = math.floor(minutes / 60)
			local days = math.floor(hours / 24)
			game.print("Doomsday was: " .. string.format("%d:%02d:%02d", hours, minutes % 60, seconds % 60) .. " ago...")
		end
	else
		game.print("Nothing to see here, move along! No doomsday here, nope!")
	end
end

function doomsday_players_online_compensator()
	local target = #game.connected_players
	local current = global.doomsday_current_fuzzy_playercount
	local step_size = 0.02 -- (at 21 ticks per iteration, that's 17.5sec per player change.
	
	if(current < 0)then
		game.print("Error; 'current' number of players' is less than 0!")
	end
	if(target < 0)then
		game.print("Error; 'number of players' is less than 0!")
	end
	
	if(current == target) then
		-- do nothing, this should be most of the time
	elseif ( current < target) then
		current = current + step_size
	elseif ( current > target) then
		current = current - step_size
	else 
		-- do nothing?
	end
	local modifier = 20/(0.1 * current * current + 6) -- Nice, smooth curve that should hopefully give boost equal to the playercount!
	game.forces.player.character_running_speed_modifier = modifier * 0.7
	global.doomsday_current_fuzzy_playercount = current
end

--[[
function reduce_brightness(n)
	global.pdnc_max_brightness = 1 - ((global.pdnc_current_time / global.pdnc_doomsday_start)*n)
	if(global.pdnc_max_brightness < n) then
		global.pdnc_max_brightness = n
	end
end	
]]


--Event.register(-20, doomsday_pdnc_program) --intentionally using the PDNC stepsize so the functions sync
-- this can be skipped, since it's called from pdnc!
Event.register(Event.core_events.init, doomsday_setup)
Event.register(Event.core_events.load, doomsday_on_load)
