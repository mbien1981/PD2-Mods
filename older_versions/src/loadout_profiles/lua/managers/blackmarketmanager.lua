local get = function(t, ...)
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

local in_state = function(state)
	if not game_state_machine then
		return false
	end

	return game_state_machine:current_state_name() == state
end

local is_pc = function()
	if SystemInfo.distribution then
		return SystemInfo:distribution() == Idstring("STEAM")
	end

	return SystemInfo:platform() == Idstring("WIN32")
end

local BlackMarketManager = _G["BlackMarketManager"]

function BlackMarketManager:forced_character()
	if managers.network and managers.network:session() then
		local level_data = tweak_data.levels[managers.job:current_level_id()]
		if level_data and level_data.force_equipment then
			local peer = managers.network:session():local_peer()
			if peer and peer:character() ~= level_data.force_equipment.character then
				peer:set_character(level_data.force_equipment.character)
			end

			return level_data.force_equipment.character
		end
	end
end

function BlackMarketManager:forced_primary()
	local level_data = tweak_data.levels[managers.job:current_level_id()]
	local items = level_data and level_data.force_equipment
	if items and items.primary then
		local blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(items.primary))
		if items.primary_mods then
			for _, mod in pairs(items.primary_mods) do
				table.insert(blueprint, mod)
			end
		end

		return {
			factory_id = items.primary,
			blueprint = blueprint,
			weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(items.primary),
			global_values = {},
			equipped = true,
		}
	end
end

function BlackMarketManager:forced_secondary()
	local level_data = tweak_data.levels[managers.job:current_level_id()]
	local items = level_data and level_data.force_equipment
	if items and items.secondary then
		local blueprint = deep_clone(managers.weapon_factory:get_default_blueprint_by_factory_id(items.secondary))
		if items.secondary_mods then
			for _, mod in pairs(items.secondary_mods) do
				table.insert(blueprint, mod)
			end
		end

		return {
			factory_id = items.secondary,
			blueprint = blueprint,
			weapon_id = managers.weapon_factory:get_weapon_id_by_factory_id(items.secondary),
			global_values = {},
			equipped = true,
		}
	end
end

function BlackMarketManager:forced_armor()
	local level_data = tweak_data.levels[managers.job:current_level_id()]
	return level_data and level_data.force_equipment and level_data.force_equipment.armor
end

function BlackMarketManager:forced_deployable()
	local level_data = tweak_data.levels[managers.job:current_level_id()]
	return level_data and level_data.force_equipment and level_data.force_equipment.deployable
end

function BlackMarketManager:forced_throwable()
	local level_data = tweak_data.levels[managers.job:current_level_id()]
	return level_data and level_data.force_equipment and level_data.force_equipment.throwable
end

function BlackMarketManager:weapon_unlocked_by_crafted(category, slot)
	local crafted = self._global.crafted_items[category][slot]
	if not crafted then
		return false
	end

	local weapon_id = crafted.weapon_id
	local cosmetics = crafted.cosmetics
	local cosmetic_blueprint = cosmetics
			and cosmetics.id
			and get(tweak_data, "blackmarket", "weapon_skins", cosmetics.id, "default_blueprint")
		or {}
	local unlocked = Global.blackmarket_manager.weapons[weapon_id].unlocked

	if unlocked then
		for part_id, dlc in pairs(crafted.global_values or {}) do
			if
				not table.contains(cosmetic_blueprint, part_id)
				and dlc ~= "normal"
				and dlc ~= "infamous"
				and not managers.dlc:is_dlc_unlocked(dlc)
			then
				return false, dlc
			end
		end
	end

	return unlocked
end

function BlackMarketManager:equipped_armor(chk_armor_kit, chk_player_state)
	if chk_player_state and managers.player:current_state() == "civilian" then
		return self._defaults.armor
	end

	if chk_armor_kit then
		if
			managers.player:equipment_slot("armor_kit")
			and (managers.player:get_equipment_amount("armor_kit") > 0 or in_state("ingame_waiting_for_players"))
		then
			return self._defaults.armor
		end
	end

	local armor
	for armor_id, _ in pairs(tweak_data.blackmarket.armors) do
		armor = Global.blackmarket_manager.armors[armor_id]
		if armor.equipped and armor.unlocked and armor.owned then
			local forced_armor = self:forced_armor()
			if forced_armor then
				return forced_armor
			end

			return armor_id
		end
	end

	return self._defaults.armor
end

function BlackMarketManager:equipped_secondary()
	local forced_secondary = self:forced_secondary()
	if forced_secondary then
		return forced_secondary
	end

	if not Global.blackmarket_manager.crafted_items.secondaries then
		self:aquire_default_weapons()
	end

	for _, data in pairs(Global.blackmarket_manager.crafted_items.secondaries) do
		if data.equipped then
			return data
		end
	end

	for _, data in pairs(Global.blackmarket_manager.crafted_items.secondaries) do -- safe check
		data.equipped = true
		return data
	end

	self:aquire_default_weapons()

	return Global.blackmarket_manager.crafted_items.secondaries[1]
end

function BlackMarketManager:equipped_primary()
	local forced_primary = self:forced_primary()
	if forced_primary then
		return forced_primary
	end

	if not Global.blackmarket_manager.crafted_items.primaries then
		self:aquire_default_weapons()
	end

	for _, data in pairs(Global.blackmarket_manager.crafted_items.primaries) do
		if data.equipped then
			return data
		end
	end

	for _, data in pairs(Global.blackmarket_manager.crafted_items.primaries) do -- safe check
		data.equipped = true
		return data
	end

	self:aquire_default_weapons()

	return Global.blackmarket_manager.crafted_items.primaries[1]
end

function BlackMarketManager:_check_achievements(category)
	local cat_ids = Idstring(category)
	if cat_ids == Idstring("primaries") then
		local equipped = self:equipped_primary()
		if equipped and equipped.weapon_id == tweak_data.achievement.steam_500k then
			managers.achievment:award("gage3_1")
		end
	elseif cat_ids == Idstring("secondaries") then
		local equipped = self:equipped_secondary()
		if equipped and equipped.weapon_id == tweak_data.achievement.unique_selling_point then
			managers.achievment:award("halloween_9")
		end

		if equipped and equipped.weapon_id == tweak_data.achievement.vote_for_change then
			managers.achievment:award("bob_1")
		end
	elseif cat_ids == Idstring("melee_weapons") then
		local equipped = managers.blackmarket:equipped_melee_weapon()
		if equipped == tweak_data.achievement.demise_knuckles then
			managers.achievment:award("death_31")
		end
	elseif cat_ids == Idstring("armors") then
		local equipped = managers.blackmarket:equipped_armor()
		if equipped ~= tweak_data.achievement.how_do_you_like_me_now then
			managers.achievment:award("how_do_you_like_me_now")
		end

		if equipped == tweak_data.achievement.iron_man then
			managers.achievment:award("iron_man")
		end
	elseif cat_ids == Idstring("masks") then
		local equipped = managers.blackmarket:equipped_mask()
		if equipped and equipped.mask_id == tweak_data.achievement.like_an_angry_bear then
			managers.achievment:award("like_an_angry_bear")
		end
		if equipped and equipped.mask_id == tweak_data.achievement.merry_christmas then
			managers.achievment:award("charliesierra_3")
		end
		if equipped and equipped.mask_id == tweak_data.achievement.heat_around_the_corner then
			managers.achievment:award("armored_11")
		end
	end

	if cat_ids == Idstring("primaries") or cat_ids == Idstring("secondaries") or cat_ids == Idstring("armors") then
		local equipped_primary = self:equipped_primary()
		local equipped_secondary = self:equipped_secondary()
		local equipped_armor = self:equipped_armor()
		local achievement = tweak_data.achievement.one_man_army
		if
			achievement
			and equipped_primary
			and equipped_secondary
			and equipped_primary.weapon_id == achievement.equipped.primary
			and equipped_secondary.weapon_id == achievement.equipped.secondary
			and equipped_armor == achievement.equipped.armor
		then
			managers.achievment:award(achievement.award)
		end
	end
end

function BlackMarketManager:equip_weapon(category, slot)
	if not Global.blackmarket_manager.crafted_items[category] then
		return false
	end

	for s, data in pairs(Global.blackmarket_manager.crafted_items[category]) do
		if self:weapon_unlocked_by_crafted(category, slot) then
			data.equipped = s == slot
		end
	end

	self:_check_achievements(category)

	if managers.menu_scene and managers.menu_scene.set_character_equipped_weapon then
		local data = category == "primaries" and self:equipped_primary() or self:equipped_secondary()
		managers.menu_scene:set_character_equipped_weapon(
			nil,
			data.factory_id,
			data.blueprint,
			category == "primaries" and "primary" or "secondary",
			data.cosmetics
		)
	end

	MenuCallbackHandler:_update_outfit_information()

	if is_pc() and managers.statistics.publish_equipped_to_steam then
		managers.statistics:publish_equipped_to_steam()
	end

	if managers.hud then
		managers.hud:recreate_weapon_firemode(HUDManager.PLAYER_PANEL)
	end

	return true
end

function BlackMarketManager:equip_deployable(data, loading)
	local deployable_id = data
	local slot = 1
	if type(data) == "table" then
		deployable_id = data.name
		slot = data.target_slot
	end

	if not table.contains(managers.player:availible_equipment(1), deployable_id) then
		return
	end

	Global.player_manager.kit.equipment_slots[slot] = deployable_id

	if managers.menu_scene and managers.menu_scene.set_character_deployable then
		managers.menu_scene:set_character_deployable(deployable_id, false, 0)
	end

	if not loading then
		MenuCallbackHandler:_update_outfit_information()
	end

	if is_pc() and managers.statistics.publish_equipped_to_steam then
		managers.statistics:publish_equipped_to_steam()
	end
end

function BlackMarketManager:equipped_deployable(slot)
	slot = slot or 1

	return managers.player and managers.player:equipment_in_slot(slot)
end

function BlackMarketManager:equip_mask(slot)
	local category = "masks"
	if not Global.blackmarket_manager.crafted_items[category] then
		return nil
	end

	if not Global.blackmarket_manager.crafted_items[category][slot] then
		slot = 1
	end

	for s, data in pairs(Global.blackmarket_manager.crafted_items[category]) do
		data.equipped = s == slot
	end

	self:_check_achievements("masks")

	local new_mask_data = Global.blackmarket_manager.crafted_items[category][slot]
	if managers.menu_scene then
		managers.menu_scene:set_character_mask_by_id(new_mask_data.mask_id, new_mask_data.blueprint)
	end

	MenuCallbackHandler:_update_outfit_information()

	if is_pc() and managers.statistics.publish_equipped_to_steam then
		managers.statistics:publish_equipped_to_steam()
	end

	return true
end

function BlackMarketManager:on_unaquired_armor(upgrade, id)
	self._global.armors[upgrade.armor_id].unlocked = false
	self._global.armors[upgrade.armor_id].owned = false

	if self._global.armors[upgrade.armor_id].equipped then
		self._global.armors[upgrade.armor_id].equipped = false
		self._global.armors[self._defaults.armor].owned = true
		self._global.armors[self._defaults.armor].equipped = true
		self._global.armors[self._defaults.armor].unlocked = true

		if managers.menu_scene then
			managers.menu_scene:set_character_armor(self._defaults.armor)
		end

		MenuCallbackHandler:_update_outfit_information()
	end
end
