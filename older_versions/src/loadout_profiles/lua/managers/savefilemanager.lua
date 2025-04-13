if Application:version() >= "v1.54.12" then
	log("Skipped SavefileManager overrides")
	return
end

local SavefileManager = _G["SavefileManager"]

local manager_list = {
	{ "player" },
	{ "experience" },
	{ "upgrades" },
	{ "money" },
	{ "statistics" },
	{ "skilltree" },
	{ "blackmarket" },
	{ "mission", "save_job_values" },
	{ "job" },
	{ "dlc" },
	{ "infamy" },
	{ "features" },
	{ "gage_assignment" },
	{ "music", "save_profile" },
	{ "challenge" },
	{ "multi_profile" },
	{ "ban_list" },
	{ "crimenet" },
	{ "custom_safehouse" },
	{ "butler_mirroring" },
	{ "mutators" },
	{ "tango" },
	{ "crime_spree" },
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
		for _, data in ipairs(manager_list) do
			local manager, save_clbk = data[1], data[2]
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
