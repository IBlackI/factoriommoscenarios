-- TOOLS: Recommend all be turned on

-- This is specifically and deliberately a global in the sense of existing in _ENV
-- but not in Factorio's global table, for compatibility with the existing code
-- _G == _ENV._G == _ENV, since Factorio is Lua 5.2
-- This is due to a fundamental change in the style of stdlib and Event to comply with newer module standards in Lua, namely that they don't pollute _G
-- Changing this to a local requires patching every file that uses events to have `local Event = require "lualib/event"`
_ENV.Event = require "lualib/event"

require "mod-gui" --required for all other modules

require "lualib/topgui" --utility module to be able to order the buttons in the top left
require "lualib/char_mod"	--utility module to prevent multiple modules conflicting when modifying player bonus
require "lualib/bot"	--3ra stuff
require "announcements"	--Module to announce stuff ingame / give the players a welcome message
require "lualib/modular_tag/modular_tag" --Module to let players set a tag behind their names to improve teamwork, also allows other modules to get (and use) its canvas.
require "lualib/modular_admin/modular_admin" --New admin tools
require "lualib/modular_information/modular_information" --New player information system
require "lualib/antigrief"
require "equipment"

require "lualib/pdnc" --Zr's fancy day-night cycle stuff

-- doomsday is ready for use! Defaults to about 5h until doomsday. 
require "lualib/doomsday" -- enables the doomsday module. Default to start doomsday after 3h

-- MAP GENERATORS
-- require "maps/grid"
-- require "maps/wg_jungle" --Jungle World Generator, generates a world full of trees!

require "debug"


