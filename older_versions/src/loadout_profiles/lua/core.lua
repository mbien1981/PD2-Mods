if not rawget(_G, "LoadoutProfiles") then
	rawset(_G, "LoadoutProfiles", {
		mod_path = _G["ModPath"],
		save_path = _G["SavePath"],
		settings = { max_profiles = 15 },
	})

	function LoadoutProfiles:version_compare(version)
		local function split(v)
			local t = {}
			for num in v:gmatch("%d+") do
				t[#t + 1] = tonumber(num)
			end
			return t
		end

		local va, vb = split(Application:version()), split(version)

		for i = 1, math.max(#va, #vb) do
			local x = va[i] or 0
			local y = vb[i] or 0
			if x ~= y then
				return x > y
			end
		end

		return true
	end

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
