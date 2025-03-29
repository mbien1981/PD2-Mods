-- DAHM by DorentuZ` -- http://steamcommunity.com/id/dorentuz/
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at http://mozilla.org/MPL/2.0/.

-- patch the resolution selector to allow selecting the refresh rate
local MenuResolutionCreator = _G["MenuResolutionCreator"]
function MenuResolutionCreator:modify_node(node, res_string, modes)
	local new_node = deep_clone(node)
	if modes then
		local node_params = new_node:parameters()
		node_params.topic_id = res_string
		node_params.localize = false

		for _, res in ipairs(modes) do
			local mode_string = string.format("%d Hz", res.z)
			local params = {
				name = mode_string,
				text_id = mode_string,
				icon = "guis/textures/scrollarrow",
				icon_rotation = 90,
				icon_visible_callback = "is_current_refresh_rate",
				callback = "change_resolution",
				resolution = res,
				localize = "false",
			}

			local new_item = new_node:create_item(nil, params)
			new_node:add_item(new_item)
		end
	else
		local include_refresh_rates = RenderSettings.fullscreen
		local node_name = new_node:parameters().name

		-- collect different resolutions and determine what items to create
		local available_modes, items_to_create = {}, {}
		for _, res in ipairs(RenderSettings.modes) do
			local res_string = string.format("%d x %d", res.x, res.y)
			local mode = available_modes[res_string]
			if mode ~= nil and include_refresh_rates then
				table.insert(mode, res)
			elseif mode == nil then
				mode = { res }
				available_modes[res_string] = mode

				table.insert(items_to_create, {
					name = res_string,
					text_id = res_string,
					resolution = res,
					modes = mode,
					icon = "guis/textures/scrollarrow",
					icon_rotation = 90,
					icon_visible_callback = "is_current_resolution",
					localize = "false",
				})
			end
		end

		-- create items
		for _, params in ipairs(items_to_create) do
			if #params.modes > 1 then
				params.next_node = node_name
				params.next_node_parameters = { params.name, params.modes }
			else
				params.callback = "change_resolution"
			end

			new_node:add_item(new_node:create_item(nil, params))
		end
	end

	managers.menu:add_back_button(new_node)
	return new_node
end

function MenuOptionInitiator:modify_resolution(node)
	local item_name = string.format("%d Hz", RenderSettings.resolution.z)
	if not node:item(item_name) then
		item_name = string.format("%d x %d", RenderSettings.resolution.x, RenderSettings.resolution.y)
	end

	node:set_default_item_name(item_name)
	return node
end

function MenuCallbackHandler:is_current_refresh_rate(item)
	return item:name() == string.format("%d Hz", RenderSettings.resolution.z)
end
