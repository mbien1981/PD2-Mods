function MenuManager:set_mouse_sensitivity(zoomed)
	if self:is_console() then
		return
	end

	-- self._look_multiplier = Vector3(0.15, 0.15, 0)

	local sens = zoomed and managers.user:get_setting("enable_camera_zoom_sensitivity") and managers.user:get_setting("camera_zoom_sensitivity") or managers.user:get_setting("camera_sensitivity")
	self._controller:get_setup():get_connection("look"):set_multiplier(sens * Vector3(0.05, 0.05, 0))
	managers.controller:rebind_connections()
end
