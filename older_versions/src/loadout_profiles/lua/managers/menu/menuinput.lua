local MenuInput = _G["MenuInput"]

function MenuInput:set_back_enabled(enabled)
	self._back_disabled = not enabled
end

function MenuInput:back(...)
	self._slider_marker = nil

	if self._back_disabled then
		return
	end

	local node_gui = managers.menu:active_menu().renderer:active_node_gui()
	if node_gui and node_gui._listening_to_input then
		return
	end

	if managers.system_menu and managers.system_menu:is_active() and not managers.system_menu:is_closing() then
		return
	end

	MenuInput.super.back(self, ...)
end

function MenuInput:force_input()
	return self._force_input
end

function MenuInput:set_force_input(enabled)
	self._force_input = enabled
end

local orig_update = MenuInput.update
function MenuInput:update(t, dt)
	orig_update(self, t, dt)

	if not self._accept_input or not self:force_input() then
		return
	end

	if 0 < self._page_timer then
		return
	end

	if not self._controller then
		return
	end

	local button = "menu_switch_skillset"
	if
		self._accept_input
		and self._controller:get_input_pressed(button)
		and managers.menu:active_menu().renderer:special_btn_pressed(Idstring(button))
	then
		managers.menu:active_menu().renderer:disable_input(0.2)
	end
end
