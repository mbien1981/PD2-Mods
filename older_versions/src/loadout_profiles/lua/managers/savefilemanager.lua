if Application:version() >= "v1.54.12" then
	log("Skipped SavefileManager overrides")
	return
end

local SavefileManager = _G["SavefileManager"]

local orig__load_cache = SavefileManager._load_cache
function SavefileManager:_load_cache(slot)
	orig__load_cache(self, slot)

	if slot == self.SETTING_SLOT then
		return
	end

	local meta_data = self:_meta_data(slot)
	local cache = meta_data.cache

	if cache then
		local version = cache.version or 0
		managers.multi_profile:load(cache, version)
	end
end

local manager_list = {
	"player",
	"experience",
	"upgrades",
	"money",
	"statistics",
	"skilltree",
	"blackmarket",
	"mission",
	"job",
	"dlc",
	"infamy",
	"features",
	"gage_assignment",
	"music",
	"challenge",
	"multi_profile",
}

function SavefileManager:_save_cache(slot)
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
		for _, manager in ipairs(manager_list) do
			local instance = managers[manager]
			if instance and instance.save then
				instance:save(cache)
			end
		end
	end

	if SystemInfo:platform() == Idstring("WIN32") then
		cache.user_id = self._USER_ID_OVERRRIDE or Steam:userid()
	end

	self:_set_cache(slot, cache)
	self:_set_synched_cache(slot, false)
end
