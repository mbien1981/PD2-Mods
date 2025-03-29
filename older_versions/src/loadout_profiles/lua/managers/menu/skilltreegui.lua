Hooks:PostHook(SkillTreeGui, "_setup", "SP_insert_profile_switch_gui", function(self)
	self._multi_profile_item = MultiProfileItemGui:new(self._ws, self._panel)
	self._multi_profile_item:panel():set_bottom(self._panel:h())
	self._multi_profile_item:panel():set_center_x(self._panel:center_x())
end)

local orig_mouse_moved = SkillTreeGui.mouse_moved
function SkillTreeGui:mouse_moved(o, x, y)
	if self._renaming_skill_switch then
		return true, "link"
	end

	if not self._enabled then
		return
	end

	local used, pointer = orig_mouse_moved(self, o, x, y)
	if self._multi_profile_item then
		local u, p = self._multi_profile_item:mouse_moved(x, y)
		used = u or used
		pointer = p or pointer
	end

	return used, pointer
end

local orig_mouse_pressed = SkillTreeGui.mouse_pressed
function SkillTreeGui:mouse_pressed(button, x, y)
	if self._renaming_skill_switch then
		self:_stop_rename_skill_switch()
		return
	end

	if not self._enabled then
		return
	end

	local result = orig_mouse_pressed(self, button, x, y)
	if result then
		return result
	end

	if button == Idstring("0") and self._multi_profile_item then
		self._multi_profile_item:mouse_pressed(button, x, y)
	end
end

if Application:version() >= "1.23.0" then
	log("[SkillTreeGui] Skipped skillset button insertion")
	return
end

local NOT_WIN_32 = SystemInfo:platform() ~= Idstring("WIN32")
local WIDTH_MULTIPLIER = NOT_WIN_32 and 0.6 or 0.6

Hooks:PostHook(SkillTreeGui, "_setup", "SP_insert_skill_switch_butttons", function(self)
	self._enabled = true

	local prefix = not managers.menu:is_pc_controller() and managers.localization:get_default_macro("BTN_Y") or ""

	local panel = self._skill_tree_panel or self._panel
	if panel:child("skill_set_bg") then
		return
	end

	local skill_set_bg = panel:rect({
		name = "skill_set_bg",
		color = tweak_data.screen_colors.button_stage_3,
		alpha = 0,
		blend_mode = "add",
	})

	local skill_set_text = panel:text({
		name = "skill_set_text",
		text = managers.skilltree:get_skill_switch_name(managers.skilltree:get_selected_skill_switch(), true),
		layer = 1,
		font = tweak_data.menu.pd2_medium_font,
		font_size = tweak_data.menu.pd2_medium_font_size,
		color = tweak_data.screen_colors.text,
		align = "left",
		vertical = "top",
		blend_mode = "add",
		visible = skill_set_bg:visible(),
	})
	self:make_fine_text(skill_set_text)

	panel:text({
		name = "switch_skills_button",
		text = prefix .. managers.localization:to_upper_text("menu_st_skill_switch_title"),
		align = "left",
		vertical = "top",
		font_size = tweak_data.menu.pd2_medium_font_size,
		font = tweak_data.menu.pd2_medium_font,
		color = Color.black,
		blend_mode = "add",
		layer = 0,
	})
	self:make_fine_text(panel:child("switch_skills_button"))

	local points_text = panel:child("points_text")
	local switch_skills_button = panel:child("switch_skills_button")
	if alive(switch_skills_button) then
		skill_set_text:set_top(points_text:top())
		skill_set_bg:set_shape(
			skill_set_text:left(),
			skill_set_text:top(),
			panel:w() * WIDTH_MULTIPLIER * 1 / 3 - 10,
			skill_set_text:h()
		)

		if skill_set_bg:visible() then
			switch_skills_button:set_top(points_text:bottom())
		else
			switch_skills_button:set_top(points_text:top())
		end
	end

	self._skill_switch_highlight = true
	self:check_skill_switch_button()
end)

function SkillTreeGui:check_skill_switch_button(x, y, force_text_update)
	local panel = self._skill_tree_panel or self._panel

	local inside = false
	if x and y and panel:child("switch_skills_button"):inside(x, y) then
		if not self._skill_switch_highlight then
			self._skill_switch_highlight = true
			panel:child("switch_skills_button"):set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		inside = true
	elseif self._skill_switch_highlight then
		self._skill_switch_highlight = false
		panel
			:child("switch_skills_button")
			:set_color(managers.menu:is_pc_controller() and tweak_data.screen_colors.button_stage_3 or Color.black)
	end

	-- not implemented
	-- if x and y and panel:child("skill_set_bg"):inside(x, y) then
	-- 	if not self._skill_set_highlight then
	-- 		self._skill_set_highlight = true
	-- 		panel:child("skill_set_text"):set_color(tweak_data.screen_colors.button_stage_2)
	-- 		panel:child("skill_set_bg"):set_alpha(0.35)
	-- 		managers.menu_component:post_event("highlight")
	-- 	end
	-- 	inside = true
	-- elseif self._skill_set_highlight then
	-- 	self._skill_set_highlight = false
	-- 	panel:child("skill_set_text"):set_color(tweak_data.screen_colors.text)
	-- 	panel:child("skill_set_bg"):set_alpha(0)
	-- end

	if not managers.menu:is_pc_controller() then
		local text_id = "st_menu_respec_tree"
		local prefix = managers.localization:get_default_macro("BTN_X")
		panel:child("switch_skills_button"):set_color(tweak_data.screen_colors.text)
		panel
			:child("switch_skills_button")
			:set_text(prefix .. managers.localization:to_upper_text("menu_st_skill_switch_title"))
	end

	return inside
end

function SkillTreeGui:mouse_moved(o, x, y)
	if self._renaming_skill_switch then
		return true, "link"
	end

	if not self._enabled then
		return
	end

	if self:check_skill_switch_button(x, y) then
		return true, "link"
	end

	local used, pointer = orig_mouse_moved(self, o, x, y)
	if self._multi_profile_item then
		local u, p = self._multi_profile_item:mouse_moved(x, y)
		used = u or used
		pointer = p or pointer
	end

	return used, pointer
end

local orig_mouse_released = SkillTreeGui.mouse_released
function SkillTreeGui:mouse_released(button, x, y)
	if not self._enabled then
		return
	end

	orig_mouse_released(self, button, x, y)
end

function SkillTreeGui:mouse_pressed(button, x, y)
	if self._renaming_skill_switch then
		self:_stop_rename_skill_switch()
		return
	end

	if not self._enabled then
		return
	end

	if button == Idstring("0") then
		local panel = self._skill_tree_panel or self._panel
		if panel:child("switch_skills_button"):inside(x, y) then
			managers.skilltree:open_quick_select()
			return
		end

		if panel:child("skill_set_bg"):inside(x, y) then
			-- -- not implemented
			-- self:_start_rename_skill_switch()
			return
		end
	end

	local result = orig_mouse_pressed(self, button, x, y)
	if result then
		return result
	end

	if button == Idstring("0") and self._multi_profile_item then
		self._multi_profile_item:mouse_pressed(button, x, y)
	end
end

function SkillTreeGui:confirm_pressed()
	if self._renaming_skill_switch then
		self:_stop_rename_skill_switch()
		return
	end

	if not self._enabled then
		return
	end

	if self._selected_item and self._selected_item._skill_panel then
		self:place_point(self._selected_item)
		return true
	end
	return false
end

function SkillTreeGui:is_enabled()
	return self._enabled
end

function SkillTreeGui:enable()
	self._enabled = true
	if alive(self._disabled_panel) then
		self._fullscreen_ws:panel():remove(self._disabled_panel)
		self._disabled_panel = nil
	end
end

function SkillTreeGui:disable()
	self._enabled = false
	if alive(self._disabled_panel) then
		self._fullscreen_ws:panel():remove(self._disabled_panel)
		self._disabled_panel = nil
	end
	self._disabled_panel = self._fullscreen_ws:panel():panel({ layer = 50 })
	self._disabled_panel:rect({
		name = "bg",
		color = Color.black,
		alpha = 0.4,
	})
	self._disabled_panel:bitmap({
		name = "blur",
		texture = "guis/textures/test_blur_df",
		render_template = "VertexColorTexturedBlur3D",
		layer = -1,
		w = self._disabled_panel:w(),
		h = self._disabled_panel:h(),
	})
end

function SkillTreeGui:close()
	managers.menu:active_menu().renderer.ws:show()
	WalletGuiObject.close_wallet(self._panel)
	self._ws:panel():remove(self._panel)
	self._fullscreen_ws:panel():remove(self._fullscreen_panel)
end

local orig_update = SkillTreeGui.update
function SkillTreeGui:update(t, dt)
	if not self._enabled then
		return
	end

	orig_update(self, t, dt)
end
