local MenuCallbackHandler = _G["MenuCallbackHandler"]
local MenuHelper = _G["MenuHelper"]
local LP = rawget(_G, "LoadoutProfiles")

local menu_id_main = "LoadoutProfiles"
Hooks:Add("LocalizationManagerPostInit", "LP_setup_localization", function(self)
	if io.file_is_readable and io.file_is_readable(LP.mod_path .. "loc/english.txt") then
		self:load_localization_file(LP.mod_path .. "loc/english.txt", false)
	end

	if Idstring("english"):key() ~= SystemInfo:language():key() then
		for _, filename in pairs(file.GetFiles(LP.mod_path .. "loc/") or {}) do
			local str = filename:match("^(.*).txt$")
			if str and Idstring(str) and Idstring(str):key() == SystemInfo:language():key() then
				if io.file_is_readable(LP.mod_path .. "loc/" .. filename) then
					self:load_localization_file(LP.mod_path .. "loc/" .. filename)
				end

				break
			end
		end
	end
end)

Hooks:Add("MenuManagerSetupCustomMenus", "LP_setup_menu", function()
	MenuHelper:NewMenu(menu_id_main)
end)

Hooks:Add("MenuManagerPopulateCustomMenus", "LP_populate_menu", function()
	function MenuCallbackHandler:LP_set_toggle(item)
		local item_name = item:name()
		local value = item:value() == "on" and true or false

		LP.settings[item_name] = value
		LP:save()
	end

	function MenuCallbackHandler:LP_set_slider(item)
		local item_name = item:name()
		local value = item:value()

		LP.settings[item_name] = math.floor(value)
		LP:save()
	end

	MenuHelper:AddSlider({
		id = "max_profiles",
		title = "menu_lp_max_profiles",
		callback = "LP_set_slider",
		value = LP.settings.max_profiles,
		min = 5,
		max = 15,
		step = 1,
		menu_id = menu_id_main,
		show_value = true,
	})
end)

Hooks:Add("MenuManagerBuildCustomMenus", "LP_build_menu", function(self, nodes)
	nodes[menu_id_main] = MenuHelper:BuildMenu(menu_id_main)
	local parent_menu = nodes.lua_mod_options_menu or nodes.blt_options
	if not parent_menu then
		log("[LP:_build_menu] ERROR: Could not find parent menu, canceling menu initialization.")
		return
	end

	MenuHelper:AddMenuItem(parent_menu, menu_id_main, "menu_lp_title", "menu_lp_desc")
end)
