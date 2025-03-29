local MissionBriefingGui = _G["MissionBriefingGui"]
local MenuCallbackHandler = _G["MenuCallbackHandler"]

local orig_init = MissionBriefingGui.init
function MissionBriefingGui:init(saferect_ws, fullrect_ws, node)
	orig_init(self, saferect_ws, fullrect_ws, node)

	self._multi_profile_item = MultiProfileItemGui:new(self._safe_workspace, self._panel)
	self._multi_profile_item:panel():set_bottom(self._panel:h())
	self._multi_profile_item:panel():set_left(0)
	self._multi_profile_item:set_name_editing_enabled(false)
end

local ids_m1 = Idstring("0")
local ids_mwheelup = Idstring("mouse wheel up")
local ids_mwheeldown = Idstring("mouse wheel down")

function MissionBriefingGui:mouse_pressed(button, x, y)
	if not alive(self._panel) or not alive(self._fullscreen_panel) or not self._enabled then
		return
	end

	local current_state = game_state_machine:current_state()
	if current_state.blackscreen_started and current_state:blackscreen_started() then
		return
	end

	if self._displaying_asset then
		if button == ids_mwheeldown then
			self:zoom_asset("out")
			return
		elseif button == ids_mwheelup then
			self:zoom_asset("in")
			return
		end

		self:close_asset()

		return
	end

	if button == ids_mwheeldown then
		self:next_tab(true)
		return
	elseif button == ids_mwheelup then
		self:prev_tab(true)
		return
	end

	if button ~= ids_m1 then
		return
	end

	if MenuCallbackHandler:is_overlay_enabled() then
		local fx, fy = managers.mouse_pointer:modified_fullscreen_16_9_mouse_pos()
		for peer_id = 1, CriminalsManager.MAX_NR_CRIMINALS do
			if managers.hud:is_inside_mission_briefing_slot(peer_id, "name", fx, fy) then
				local peer = managers.network:session() and managers.network:session():peer(peer_id)
				if peer then
					Steam:overlay_activate(
						"url",
						tweak_data.gui.fbi_files_webpage .. "/suspect/" .. peer:user_id() .. "/"
					)
					return
				end
			end
		end
	end

	for index, tab in ipairs(self._items) do
		local pressed, cost = tab:mouse_pressed(button, x, y)
		if pressed == true then
			self:set_tab(index)
		elseif type(pressed) == "number" then
			if cost then
				if type(cost) == "number" then
					self:open_asset_buy(pressed, tab:get_asset_id(pressed))
				end
			else
				self:open_asset(pressed)
			end
		end
	end

	if self._ready_button:inside(x, y) or self._ready_tick_box:inside(x, y) then
		self:on_ready_pressed()
	end

	if not self._ready then
		self._multi_profile_item:mouse_pressed(button, x, y)
	end

	return self._selected_item
end

function MissionBriefingGui:mouse_moved(x, y)
	if not alive(self._panel) or not alive(self._fullscreen_panel) or not self._enabled then
		return false, "arrow"
	end

	if self._displaying_asset then
		return false, "arrow"
	end

	local current_state = game_state_machine:current_state()
	if current_state.blackscreen_started and current_state:blackscreen_started() then
		return false, "arrow"
	end

	local mouse_over_tab = false
	for _, tab in ipairs(self._items) do
		local selected, highlighted = tab:mouse_moved(x, y)
		if highlighted and not selected then
			mouse_over_tab = true
		end
	end

	if mouse_over_tab then
		return true, "link"
	end

	local fx, fy = managers.mouse_pointer:modified_fullscreen_16_9_mouse_pos()
	for peer_id = 1, CriminalsManager.MAX_NR_CRIMINALS do
		if managers.hud:is_inside_mission_briefing_slot(peer_id, "name", fx, fy) then
			return true, "link"
		end
	end

	if self._ready_button:inside(x, y) or self._ready_tick_box:inside(x, y) then
		if not self._ready_highlighted then
			self._ready_highlighted = true
			self._ready_button:set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")
		end
		return true, "link"
	elseif self._ready_highlighted then
		self._ready_button:set_color(tweak_data.screen_colors.button_stage_3)
		self._ready_highlighted = false
	end

	if managers.hud._hud_mission_briefing and managers.hud._hud_mission_briefing._backdrop then
		managers.hud._hud_mission_briefing._backdrop:mouse_moved(x, y)
	end

	local u, p = self._multi_profile_item:mouse_moved(x, y)

	return u or false, p or "arrow"
end
