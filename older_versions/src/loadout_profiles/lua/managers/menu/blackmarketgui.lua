Hooks:PostHook(BlackMarketGui, "_setup", "LP_BlackMarketGui:_setup", function(self)
	self._multi_profile_item = MultiProfileItemGui:new(self._ws, self._panel)
	self._multi_profile_item:panel():set_bottom(self._panel:h())
	self._multi_profile_item:panel():set_center_x(self._panel:center_x())
	-- self._multi_profile_item:set_name_editing_enabled(false)
end)

local orig_mouse_moved = BlackMarketGui.mouse_moved
function BlackMarketGui:mouse_moved(o, x, y)
	local used, pointer = orig_mouse_moved(self, o, x, y)

	if self._multi_profile_item then
		local u, p = self._multi_profile_item:mouse_moved(x, y)
		used = u or used
		pointer = p or pointer
	end

	return used, pointer
end

local orig_mouse_pressed = BlackMarketGui.mouse_pressed
function BlackMarketGui:mouse_pressed(button, x, y)
	local result = orig_mouse_pressed(self, button, x, y)

	if result then
		return false
	end

	if button == Idstring("0") then
		if self._multi_profile_item then
			self._multi_profile_item:mouse_pressed(button, x, y)
		end
	end
end
