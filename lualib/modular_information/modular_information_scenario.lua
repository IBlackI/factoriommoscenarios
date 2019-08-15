-- modular_information_scenario sub-module
-- Made by: I_IBlackI_I (Blackstone#4953 on discord) for FactorioMMO
-- This sub-module is a addon to the modular_information module, it shows players information about the scenario
--
--	VARIABLES
--

global.modular_information_scenario = global.modular_information_scenario or {} 
global.modular_information_scenario.text = global.modular_information_scenario.text or "Oh no the admins have not set this text! Please contact them saying the modular_information_scenario text is empty!"

--
--	FUNCTIONS
--
function modular_information_scenario_create_gui(p)
	local miip = modular_information_get_information_pane(p)
	miip.clear()
	modular_information_set_information_pane_caption(p, "About this scenario")
	local mist = miip.add {type="label", caption = global.modular_information_scenario.text}
	mist.style.maximal_width = 480
	mist.style.single_line = false
	if p.admin then
		local miss = miip.add {type="empty-widget", name = "modular_information_scenario_spacer"}
		miss.style.vertically_stretchable = true
		local miseb = miip.add {type="button", caption = "Edit this text", name = "modular_information_scenario_edit_button"}
		miseb.style = "partially_promised_crafting_queue_slot"
		miseb.style.left_margin = 186
		miseb.style.width = 108
		miseb.style.height = 28
	end
end
	
function modular_information_scenario_gui_clicked(event)
	if not (event and event.element and event.element.valid) then return end
	local i = event.player_index
	local p = game.players[i]
	local e = event.element
	if e ~= nil then		
		if e.name == "modular_information_scenario" then
			if modular_information_get_active_button(p) == "modular_information_scenario" then
				modular_information_set_active_button(p, "none")
			else
				modular_information_set_active_button(p, "modular_information_scenario")
				modular_information_scenario_create_gui(p)
			end
		elseif e.name == "modular_information_scenario_edit_button" then
			local miip = modular_information_get_information_pane(p)
			miip.clear()
			modular_information_set_information_pane_caption(p, "Editing scenario text")
			local miset = miip.add {type="text-box", name = "modular_information_scenario_edit_textbox"}
			miset.word_wrap = true
			miset.text = global.modular_information_scenario.text
			miset.style.maximal_width = 480
			miset.style.minimal_width = 480
			miset.style.minimal_height = 165
			local misbhf = miip.add {type = "flow", name = "modular_information_scenario_button_helper_flow", direction = "horizontal"}
			local mis = misbhf.add {type = "button", name = "modular_information_scenario_cancel_button", caption = "Cancel"}
			mis.style = "red_back_button"
			mis.style.height = 28
			mis.style.width = 150
			mis.style.horizontal_align = "left"
			local misecb = misbhf.add {type = "button", name = "modular_information_scenario_edit_clear_button", caption = "Clear text"}
			misecb.style = "dialog_button"
			misecb.style.height = 28
			misecb.style.width = 108
			misecb.style.horizontal_align = "center"
			misecb.style.left_margin = 3
			misecb.style.right_margin = 3
			local misesb = misbhf.add {type = "button", name = "modular_information_scenario_edit_save_button", caption = "Save"}
			misesb.style = "confirm_button"
			misesb.style.height = 28
			misesb.style.width = 210
		elseif e.name == "modular_information_scenario_edit_save_button" then
			global.modular_information_scenario.text = modular_information_get_information_pane(p).modular_information_scenario_edit_textbox.text
			modular_information_scenario_create_gui(p)
		elseif e.name == "modular_information_scenario_edit_clear_button" then
			modular_information_get_information_pane(p).modular_information_scenario_edit_textbox.text = " "
		elseif e.name == "modular_information_scenario_cancel_button" then
			modular_information_scenario_create_gui(p)
		end
	end
end
	
--
--	EVENTS
--

Event.register(defines.events.on_player_joined_game, function(event)
	local p = game.players[event.player_index]
	modular_information_add_button(p.name, {name="modular_information_scenario", order = 1, caption = "Scenario"})
end)

Event.register(Event.core_events.init, function(event)
	modular_information_enable_submodule("modular_information_scenario")
end)


Event.register(defines.events.on_gui_click, modular_information_scenario_gui_clicked)
