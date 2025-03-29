if not rawget(_G, "LoadoutProfiles") then
	rawset(_G, "LoadoutProfiles", {
		mod_path = _G["ModPath"],
		save_path = _G["SavePath"],
		settings = { max_profiles = 5 },
	})

	local json = _G["json"]
	function LoadoutProfiles:save()
		local file = io.open(self.save_path .. "lp_save.txt", "w+")
		if not file then
			return
		end

		file:write(json.encode(self.settings))
		file:close()
	end

	function LoadoutProfiles:load()
		local file = io.open(self.save_path .. "lp_save.txt", "r")
		if not file then
			return
		end

		for k, v in pairs(json.decode(file:read("*all")) or {}) do
			self.settings[k] = v
		end

		file:close()
	end

	LoadoutProfiles:load()
end