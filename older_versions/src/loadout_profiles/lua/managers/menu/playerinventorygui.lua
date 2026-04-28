local PlayerInventoryGui = _G["PlayerInventoryGui"]

Hooks:PostHook(PlayerInventoryGui, "init", "LP:PlayerInventoryGui.init", function(self)
	self._multi_profile_item = MultiProfileItemGui:new(self._ws, self._panel)
end)

Hooks:PostHook(PlayerInventoryGui, "mouse_moved", "LP:PlayerInventoryGui.mouse_moved", function(self, o, x, y)
	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	if not self._panel:visible() then
		return false, "arrow"
	end

	local used, pointer = self._multi_profile_item:mouse_moved(x, y)
	return used or false, pointer or "arrow"
end)

Hooks:PostHook(PlayerInventoryGui, "mouse_pressed", "LP:PlayerInventoryGui.mouse_pressed", function(self, button, x, y)
	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	if not self._panel:visible() then
		return false, "arrow"
	end

	self._multi_profile_item:mouse_pressed(button, x, y)
end)
