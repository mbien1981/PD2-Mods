local MissionBriefingGui = _G["MissionBriefingGui"]

Hooks:PostHook(MissionBriefingGui, "init", "LP:MissionBriefingGui.init", function(self)
	self._multi_profile_item = MultiProfileItemGui:new(self._safe_workspace, self._panel)
	self._multi_profile_item:panel():set_bottom(self._panel:h())
	self._multi_profile_item:panel():set_left(0)
	self._multi_profile_item:set_name_editing_enabled(false)
end)

Hooks:PostHook(MissionBriefingGui, "mouse_pressed", "LP:MissionBriefingGui.mouse_pressed", function(self, button, x, y)
	if not alive(self._panel) or not alive(self._fullscreen_panel) then
		return
	end

	if type(self._enabled) ~= "nil" and not self._enabled then
		return
	end

	local current_state = game_state_machine:current_state()
	if current_state.blackscreen_started and current_state:blackscreen_started() then
		return
	end

	if not self._displaying_asset and not self._ready then
		self._multi_profile_item:mouse_pressed(button, x, y)
	end

	return self._selected_item
end)

Hooks:PostHook(MissionBriefingGui, "mouse_moved", "LP:MissionBriefingGui.mouse_moved", function(self, x, y)
	if not alive(self._panel) or not alive(self._fullscreen_panel) then
		return false, "arrow"
	end

	if type(self._enabled) ~= "nil" and not self._enabled then
		return false, "arrow"
	end

	local used, pointer = self._multi_profile_item:mouse_moved(x, y)
	return used or false, pointer or "arrow"
end)
