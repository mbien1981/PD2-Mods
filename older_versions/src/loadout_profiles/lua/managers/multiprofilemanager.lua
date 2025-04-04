local table_get = function(t, ...)
	if not t then
		return nil
	end
	local v, keys = t, { ... }
	for i = 1, #keys do
		v = v[keys[i]]
		if v == nil then
			break
		end
	end
	return v
end

MultiProfileManager = MultiProfileManager or class()
function MultiProfileManager:init()
	if not Global.multi_profile then
		Global.multi_profile = {}
	end

	self._global = self._global or Global.multi_profile
	self._global._profiles = self._global._profiles or {}
	self._global._current_profile = self._global._current_profile or 1
	self._max_profiles = table_get(LoadoutProfiles, "settings", "max_profiles") or 15

	self:_check_amount()
end

function MultiProfileManager:save_current()
	local profile = self:current_profile() or {}
	local blm = managers.blackmarket
	local skt = managers.skilltree._global
	profile.primary = blm:equipped_weapon_slot("primaries")
	profile.secondary = blm:equipped_weapon_slot("secondaries")
	profile.melee = blm.equipped_melee_weapon and blm:equipped_melee_weapon()
	profile.throwable = blm.equipped_grenade and blm:equipped_grenade()
	profile.deployable = blm:equipped_deployable()
	profile.deployable_secondary = blm:equipped_deployable(2)
	profile.armor = blm:equipped_armor()

	profile.skillset = skt.selected_skill_switch

	if skt.specializations then -- u39 onwards
		profile.perk_deck = Application:digest_value(skt.specializations.current_specialization, false)
	end

	profile.mask = blm:equipped_mask_slot()
	self._global._profiles[self._global._current_profile] = profile
end

function MultiProfileManager:load_current()
	local profile = self:current_profile()
	local blm = managers.blackmarket
	local skt = managers.skilltree

	if skt.switch_skills then
		skt:switch_skills(profile.skillset)
	end

	if skt.set_current_specialization then
		skt:set_current_specialization(profile.perk_deck)
	end

	blm:equip_weapon("primaries", profile.primary)
	blm:equip_weapon("secondaries", profile.secondary)

	if blm.equip_melee_weapon then
		blm:equip_melee_weapon(profile.melee)
	end

	if blm.equip_grenade then
		blm:equip_grenade(profile.throwable)
	end

	blm:equip_deployable(profile.deployable)
	blm:equip_armor(profile.armor)
	blm:equip_mask(profile.mask)

	local mcm = managers.menu_component
	if mcm._player_inventory_gui then
		local node = mcm._player_inventory_gui._node
		mcm:close_inventory_gui()
		mcm:create_inventory_gui(node)
	elseif mcm._skilltree_gui then
		local node = mcm._skilltree_gui._node
		mcm:close_skilltree_gui()
		mcm:create_skilltree_gui(node)
	elseif mcm._mission_briefing_gui then
		local node = mcm._mission_briefing_gui._node
		mcm:close_mission_briefing_gui()
		mcm:create_mission_briefing_gui(node)
	elseif mcm._blackmarket_gui._node then
		local node = mcm._blackmarket_gui._node
		mcm:close_blackmarket_gui()
		mcm:create_blackmarket_gui(node)
	end
end

function MultiProfileManager:current_profile_name()
	if not self:current_profile() then
		return "Error"
	end

	return self:current_profile().name or ("Profile " .. self._global._current_profile)
end

function MultiProfileManager:profile_count()
	return math.max(#self._global._profiles, 1)
end

function MultiProfileManager:set_current_profile(index)
	if index < 0 or index > self:profile_count() then
		return
	end
	if index == self._global._current_profile then
		return
	end

	self:save_current()
	self._global._current_profile = index
	self:load_current()
end

function MultiProfileManager:current_profile()
	return self:profile(self._global._current_profile)
end

function MultiProfileManager:profile(index)
	return self._global._profiles[index]
end

function MultiProfileManager:_add_profile(profile, index)
	index = index or #self._global._profiles + 1
	self._global._profiles[index] = profile
end

function MultiProfileManager:next_profile()
	self:set_current_profile(self._global._current_profile + 1)
end

function MultiProfileManager:previous_profile()
	self:set_current_profile(self._global._current_profile - 1)
end

function MultiProfileManager:has_next()
	return self._global._current_profile < self:profile_count()
end

function MultiProfileManager:has_previous()
	return self._global._current_profile > 1
end

function MultiProfileManager:open_quick_select()
	local button_list = {}

	for idx, profile in pairs(self._global._profiles) do
		local text = profile.name or ("Profile " .. idx)
		table.insert(button_list, {
			text = text,
			callback = function()
				self:set_current_profile(idx)
			end,
		})
	end

	table.insert(button_list, {
		text = "",
	})

	table.insert(button_list, {
		text = managers.localization:text("dialog_cancel"),
		cancel_button = true,
		is_focused_button = true,
	})

	-- does not support scrolling if the menu is too large, cannot be closed with escape
	_G["QuickMenu"]:new("", "", button_list, true)
end

function MultiProfileManager:save(data)
	local save_data = deep_clone(self._global._profiles)
	save_data.current_profile = self._global._current_profile
	data.multi_profile = save_data
end

function MultiProfileManager:load(data)
	if data.multi_profile then
		for i, profile in ipairs(data.multi_profile) do
			self:_add_profile(profile, i)
		end

		self._global._current_profile = data.multi_profile.current_profile
	end

	self:_check_amount()
end

local table_crop = function(t, size)
	while t[size + 1] do
		table.remove(t, size + 1)
	end
end

function MultiProfileManager:_check_amount()
	if not self:current_profile() then
		self:save_current()
	end

	if self._max_profiles < self:profile_count() then
		table_crop(self._global._profiles, self._max_profiles)
		self._global._current_profile = math.min(self._global._current_profile, self._max_profiles)
	elseif self._max_profiles > self:profile_count() then
		local prev_current = self._global._current_profile
		self._global._current_profile = self:profile_count()
		while self._max_profiles > self._global._current_profile do
			self._global._current_profile = self._global._current_profile + 1
			self:save_current()
		end
		self._global._current_profile = prev_current
	end
end
