-- General functions and other 'nice to have' that don't need to be remade all the tiem
global.general_library = global.general_library or {}

function gl_bool_to_string(b)
	if(b)then
		return "true"
	else
		return "false"
	end
end

-- stolen from https://rosettacode.org/wiki/Find_the_intersection_of_two_lines#Lua
function gl_intersection (s1, e1, s2, e2)
  local d = (s1.x - e1.x) * (s2.y - e2.y) - (s1.y - e1.y) * (s2.x - e2.x)
  local a = s1.x * e1.y - s1.y * e1.x
  local b = s2.x * e2.y - s2.y * e2.x
  local x = (a * (s2.x - e2.x) - (s1.x - e1.x) * b) / d
  local y = (a * (s2.y - e2.y) - (s1.y - e1.y) * b) / d
  return x, y
end

function gl_min_to_ticks(t)
	return 60*60*t
end

function gl_sec_to_ticks(t)
	return 60*t
end

function gl_check_valid(n, s)
	if (n == nil) then
		pdnc_debug_message(s .. " set to nil! Set to 1.0 instead")
		return false
	elseif (n < 0) then
		pdnc_debug_message(s .. " cannot be " .. n .. " limited to 0.0 instead")
		return false
	elseif (n > 1) then
		pdnc_debug_message(s .. " cannot be " .. n .. " limited to 1.0 instead")
		return false
	elseif (n ~= n) then
		pdnc_debug_message(s .. " cannot be " .. n .. " since it's not a valid number!")
	else return true
	end
end

function gl_normalized_boxy_sine(x)
	--local x = global.pdnc_current_time * math.pi * 2
	return gl_boxy_sine_boxy(x)
end

function gl_boxy_sine_boxy(x)
	return gl_sine_normalize((math.sin(x) + (0.111 * math.sin(3 * x))) * 1.124859392575928)
	-- magic numbers to make it scale to (-1, 1)
end

function gl_sine_normalize(n)
	return (n + 1)/2
end