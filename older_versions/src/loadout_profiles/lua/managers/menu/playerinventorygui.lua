local PlayerInventoryGui = _G["PlayerInventoryGui"]

local orig_init = PlayerInventoryGui.init
function PlayerInventoryGui:init(ws, fullscreen_ws, node)
	orig_init(self, ws, fullscreen_ws, node)

	self._multi_profile_item = MultiProfileItemGui:new(self._ws, self._panel)
end

function PlayerInventoryGui:_animate_box(box, selected, instant)
	if not box then
		return
	end

	if box.children then
		for _, child_box in ipairs(box.children) do
			self:_animate_box(child_box, selected, instant)
		end
	end

	local panel = box.panel
	local anim = selected and box.select_anim or box.unselected_anim

	if alive(panel) and selected then
		box.panel:stop()
		box.panel:animate(selected, box, instant)
	end
end

function PlayerInventoryGui:_get_box_redirected(box_name)
	local box = self._boxes_by_name[box_name]

	if not box then
		return nil
	end

	if not box.redirect_box then
		return box, box_name
	end

	return self:_get_box_redirected(box.redirect_box)
end

function PlayerInventoryGui:_set_selected_box(box)
	local selected_box = self:_get_selected_box()

	if selected_box == box then
		return
	end

	if selected_box then
		selected_box.selected = false

		self:_update_box_status(selected_box, false)
		self:_animate_box(selected_box, selected_box.unselect_anim, false)
	end

	if box then
		box.selected = true
		self._data.selected_box = box.name

		self:_update_selected_box(false)
		managers.menu_component:post_event("highlight")
	end
end

function PlayerInventoryGui:_update_selected_box(instant)
	local box = self:_get_selected_box()
	if not box then
		return
	end

	self:_update_stats(box.name)
	self:_update_legends(box.name)
	self:_update_box_status(box, true)
	self:_animate_box(box, box.select_anim, instant)
end

function PlayerInventoryGui:mouse_moved(o, x, y)
	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	if not self._panel:visible() then
		return false, "arrow"
	end

	local used = false
	local pointer = "arrow"

	if self._panel:child("back_button"):inside(x, y) then
		used = true
		pointer = "link"

		if not self._back_button_highlighted then
			self._back_button_highlighted = true

			self._panel:child("back_button"):set_color(tweak_data.screen_colors.button_stage_2)
			managers.menu_component:post_event("highlight")

			return used, pointer
		end
	elseif self._back_button_highlighted then
		self._back_button_highlighted = false

		self._panel:child("back_button"):set_color(tweak_data.screen_colors.button_stage_3)
	end

	local mouse_over_box = nil

	for i, box in ipairs(self._boxes) do
		if
			alive(box.panel)
			and box.panel:tree_visible()
			and box.can_select
			and box.panel:inside(x, y)
			and (not mouse_over_box or mouse_over_box.layer < box.layer)
		then
			mouse_over_box = box
		end
	end

	if mouse_over_box then
		local new_box = self:_get_box_redirected(mouse_over_box.name)

		self:_set_selected_box(new_box)

		used = true
		pointer = "link"
	end

	for _, button in ipairs(self._text_buttons) do
		if alive(button.panel) and button.panel:visible() then
			if button.panel:inside(x, y) then
				if not button.highlighted then
					button.highlighted = true

					managers.menu_component:post_event("highlight")

					if alive(button.text) then
						button.text:set_color(tweak_data.screen_colors.button_stage_2)
					end
				end

				pointer = "link"
				used = true
			elseif button.highlighted then
				button.highlighted = false

				button.text:set_color(tweak_data.screen_colors.button_stage_3)
			end
		end
	end

	if self._change_alpha_table then
		for _, data in ipairs(self._change_alpha_table) do
			if alive(data.panel) and alive(data.button) then
				data.button:set_alpha(data.panel:inside(x, y) and 1 or 0.1)
			end
		end
	end

	local u, p = self._multi_profile_item:mouse_moved(x, y)
	used = u or used
	pointer = p or pointer
	self._input_focus = pointer == "arrow" and 2 or 1

	return used, pointer
end

local ids_m1 = Idstring("0")
local ids_m2 = Idstring("1")
local ids_mwheelup = Idstring("mouse wheel up")
local ids_mwheeldown = Idstring("mouse wheel down")
function PlayerInventoryGui:mouse_pressed(button, x, y)
	if managers.menu_scene and managers.menu_scene:input_focus() then
		return false
	end

	if not self._panel:visible() then
		return false
	end

	local left_clicked = button == ids_m1
	local right_clicked = button == ids_m2
	local scroll_up = button == ids_mwheelup
	local scroll_down = button == ids_mwheeldown

	if left_clicked and self._panel:child("back_button"):inside(x, y) then
		managers.menu:back(true)

		return false
	end

	if left_clicked then
		for _, button in ipairs(self._text_buttons) do
			if alive(button.panel) and button.panel:visible() and button.panel:inside(x, y) then
				if button.clbk then
					button:clbk()
				end

				managers.menu_component:post_event("menu_enter")

				return true
			end
		end
	end

	local box = self:_get_selected_box()

	if box and box.clbks and box.panel:tree_visible() and box.panel:inside(x, y) then
		if left_clicked and box.clbks.left then
			box.clbks.left(box)
		elseif right_clicked and box.clbks.right then
			box.clbks.right(box)
		elseif scroll_up and box.clbks.up then
			box.clbks.up(box)
		elseif scroll_down and box.clbks.down then
			box.clbks.down(box)
		end
	end

	self._multi_profile_item:mouse_pressed(button, x, y)
end
