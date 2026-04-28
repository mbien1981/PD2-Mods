if LoadoutProfiles:version_compare("1.54.12") then
	log("Skipped SavefileManager overrides")
	return
end

local SavefileManager = _G["SavefileManager"]
Hooks:PostHook(SavefileManager, "_save_cache", "MultiProfile_SaveData", function(self, slot)
	if slot == self.SETTING_SLOT then
		return
	end

	local meta_data = self:_meta_data(slot)
	local cache = meta_data.cache

	if cache then
		managers.multi_profile:save(cache)
	end
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
