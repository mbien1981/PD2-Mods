if Application:version() >= "v1.54.12" then
	log("Skipped SavefileManager overrides")
	return
end

local SavefileManager = _G["SavefileManager"]

local manager_list = {
	["player"] = true,
	["experience"] = true,
	["upgrades"] = true,
	["money"] = true,
	["statistics"] = true,
	["skilltree"] = true,
	["blackmarket"] = true,
	["mission"] = "save_job_values",
	["job"] = true,
	["dlc"] = true,
	["infamy"] = true,
	["features"] = true,
	["gage_assignment"] = true,
	["music"] = "save_profile",
	["challenge"] = true,
	["multi_profile"] = true,
	["ban_list"] = true,
	["crimenet"] = true,
	["custom_safehouse"] = true,
	["butler_mirroring"] = true,
	["mutators"] = true,
	["tango"] = true,
	["crime_spree"] = true,
}

Hooks:OverrideFunction(SavefileManager, "_save_cache", function(self, slot)
	local is_setting_slot = slot == self.SETTING_SLOT

	if is_setting_slot then
		self:_set_cache(slot, nil)
	else
		local old_slot = Global.savefile_manager.current_game_cache_slot
		if old_slot then
			self:_set_cache(old_slot, nil)
		end

		self:_set_current_game_cache_slot(slot)
	end

	local cache = {
		version = SavefileManager.VERSION,
		version_name = SavefileManager.VERSION_NAME,
	}

	if is_setting_slot then
		managers.user:save(cache)
		if managers.music and managers.music.save_settings then
			managers.music:save_settings(cache)
		end
	else
		for manager, save_clbk in ipairs(manager_list) do
			local instance = managers[manager]

			if instance then
				if type(save_clbk) == "string" and type(instance[save_clbk]) == "function" then
					instance[save_clbk](instance, cache)
				elseif type(instance.save) == "function" then
					instance:save(cache)
				end
			end
		end
	end

	if SystemInfo:platform() == Idstring("WIN32") then
		cache.user_id = self._USER_ID_OVERRRIDE or Steam:userid()
	end

	self:_set_cache(slot, cache)
	self:_set_synched_cache(slot, false)
end)

Hooks:PostHook(SavefileManager, "_load_cache", "LP:SavefileManager._load_cache", function(self, slot)
	if slot == self.SETTING_SLOT then
		return
	end

	local meta_data = self:_meta_data(slot)
	local cache = meta_data.cache

	if cache then
		local version = cache.version or 0
		managers.multi_profile:load(cache, version)
	end
end)
