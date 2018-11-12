-- doomsday module. Requires the programmable day-night cycle (pdnc) module to work. 
-- made by Zr4g0n
-- this module currently has issues with the event module and 'on nth tick'. 
require "lualib/pdnc" --is this the best way to do this?
global.doomsday_start_time = -30.75 -- in ingame days. 
global.doomsday_pollution_multiplier = 5000
--[[ available:
global.current_time
global.pdnc_surface

]]

function doomsday_on_load()
		commands.add_command("timeleft", "Gives you the time till doomsday!", pdnc_doomsday_time_left)
end

function doomsday_pdnc_program()
	local current_time = global.pdnc_current_time -- intentionally reading from pdnc
	local returnvalue = 0
	local radius = 512 --make global
	local pollution = 10000 -- total pollution applied per tick
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
	global.pdnc_alt_program = returnvalue * 0.85
end

function doomsday_normal_curve(x)
	return (1+ ((math.sin(x) + (0.111 * math.sin(3 * x))) * 1.124859392575928))/2
	-- magic numbers to make it scale to (-1, 1)
end

function doomsday_pollute(radius,pollution,nodes)
	local p = global.pdnc_stepsize * pollution
	p = p / nodes
	local position = {x = 0.0, y = 0.0}
	game.surfaces[global.pdnc_surface].pollute(position, p) --circle + center point
	local step = (math.pi * 2) / (nodes - 1)
	for i=0, (nodes - 1) do 
		position = {x = math.sin(step*i)*radius, y = math.cos(step*i)*radius}		 
		game.surfaces[global.pdnc_surface].pollute(position, p)
	end
	
end


function doomsday_time_left()
	local ticks_until_doomsday = game.surfaces[global.pdnc_surface].ticks_per_day * global.doomsday_start
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
end

--[[
function reduce_brightness(n)
	global.pdnc_max_brightness = 1 - ((global.pdnc_current_time / global.pdnc_doomsday_start)*n)
	if(global.pdnc_max_brightness < n) then
		global.pdnc_max_brightness = n
	end
end	
]]


Event.register(-20, doomsday_pdnc_program) --intentionally using the PDNC stepsize so the functions sync
Event.register(Event.core_events.load,doomsday_on_load)
