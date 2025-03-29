function MenuManager:is_steam_controller()
	return self:active_menu()
			and self:active_menu().input
			and self:active_menu().input._controller
			and self:active_menu().input._controller.TYPE == "steam"
		or managers.controller:get_default_wrapper_type() == "steam"
end

if Application:version() >= "1.23.0" then
	log("[MenuManager] Skipped SkillSwitchInitiator definition")
	return
end

SkillSwitchInitiator = SkillSwitchInitiator or class()

function SkillSwitchInitiator:modify_node(node, data)
	node:clean_items()
	local hightlight_color, row_item_color, callback
	self:create_divider(node, "title", "menu_st_skill_switch_title_name", nil, tweak_data.screen_colors.text)
	for skill_switch, data in ipairs(Global.skilltree_manager.skill_switches) do
		hightlight_color = nil
		row_item_color = nil
		callback = nil
		local unlocked = data.unlocked
		local can_unlock = managers.skilltree:can_unlock_skill_switch(skill_switch)
		if unlocked then
			if managers.skilltree:get_selected_skill_switch() == skill_switch then
				hightlight_color = tweak_data.screen_colors.text
				row_item_color = tweak_data.screen_colors.text
				callback = "menu_back"
			else
				hightlight_color = tweak_data.screen_colors.button_stage_2
				row_item_color = tweak_data.screen_colors.button_stage_3
				callback = "set_active_skill_switch"
			end
		elseif can_unlock then
			hightlight_color = tweak_data.screen_colors.button_stage_2
			row_item_color = tweak_data.screen_colors.button_stage_3
			callback = "unlock_skill_switch"
		else
			hightlight_color = tweak_data.screen_colors.important_1
			row_item_color = tweak_data.screen_colors.important_2
		end
		self:create_item(node, {
			name = skill_switch,
			text_id = data.unlocked and managers.skilltree:get_skill_switch_name(skill_switch, true)
				or managers.localization:to_upper_text("menu_st_locked_skill_switch"),
			enabled = unlocked or can_unlock,
			disabled_color = row_item_color,
			localize = false,
			callback = callback,
			hightlight_color = hightlight_color,
			row_item_color = row_item_color,
		})
	end
	self:create_divider(node, "back_div")
	self:add_back_button(node)
	node:set_default_item_name(1)
	return node
end

function SkillSwitchInitiator:refresh_node(node, data)
	local selected_item = node:selected_item() and node:selected_item():name()
	node = self:modify_node(node, data)
	if selected_item then
		node:select_item(selected_item)
	end
	return node
end

function SkillSwitchInitiator:create_item(node, params)
	local data_node = {}
	local new_item = node:create_item(data_node, params)
	new_item:set_enabled(params.enabled)
	node:add_item(new_item)
end

function SkillSwitchInitiator:create_divider(node, id, text_id, size, color)
	local params = {
		name = "divider_" .. id,
		no_text = not text_id,
		text_id = text_id,
		size = size or 8,
		color = color,
	}
	local data_node = {
		type = "MenuItemDivider",
	}
	local new_item = node:create_item(data_node, params)
	node:add_item(new_item)
end

function SkillSwitchInitiator:add_back_button(node)
	node:delete_item("back")
	local params = {
		name = "back",
		text_id = "menu_back",
		visible_callback = "is_pc_controller",
		align = "right",
		previous_node = true,
	}
	local new_item = node:create_item(nil, params)
	node:add_item(new_item)
end

-- ToDo: find a way to implement skill_switch from u49 without using BLT's QuickMenu
Hooks:Add("MenuManagerBuildCustomMenus", "LP_add_skill_switch", function(self, nodes)
	-- MenuHelper:NewMenu("skill_switch")
	-- nodes["skill_switch"] = {
	-- 	gui_class = "MenuNodeSkillSwitchGui",
	-- 	help_id = "menu_skill_switch_help",
	-- 	menu_components = "skilltree_new, inventory_chats",
	-- 	modifier = "SkillSwitchInitiator",
	-- 	name = "skill_switch",
	-- 	no_item_parent = "false",
	-- 	no_menu_wrapper = "true",
	-- 	refresh = "SkillSwitchInitiator",
	-- 	scene_state = "lobby",
	-- 	sync_state = "skilltree",
	-- 	topic_id = "menu_skill_switch",
	-- }

	-- nodes["skill_switch"] = {
	-- 	name = "skill_switch",
	-- 	["_parameters"] = {
	-- 		["gui_class"] = "MenuNodeSkillSwitchGui",
	-- 	},
	-- }
end)
