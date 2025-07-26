if Application:version() >= "1.23.0" then -- u49 onwards
	log("Skipped SkillTreeManager overrides")
	return
end

local u39_or_above = Application:version() >= "1.16.1"

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

SkillTreeManager = SkillTreeManager or class()
SkillTreeManager.VERSION = 6

-- backports for pre-u19
function SkillTreeManager:all_skilltree_ids()
	local t = {}
	for _, data in ipairs(tweak_data.skilltree.trees) do
		table.insert(t, data.skill)
	end

	return t
end

function SkillTreeManager:get_skill_points(skill, index)
	local points = table_get(tweak_data.skilltree, "skills", skill, index, "cost")
	points = Application:digest_value(tweak_data.skilltree.skills[skill][index].cost, false) or 0

	local total_points = points
	if points > 0 then
		for _, tree in ipairs(tweak_data.skilltree.trees) do
			if tree.skill == skill then
				local unlocked = self:trees_unlocked()
				if unlocked < #tweak_data.skilltree.unlock_tree_cost then
					total_points = points
						+ Application:digest_value(tweak_data.skilltree.unlock_tree_cost[unlocked + 1], false)
				end
				break
			end
		end
	end

	return total_points, points
end

function SkillTreeManager:tier_cost(tree, tier)
	local points = Application:digest_value(tweak_data.skilltree.tier_unlocks[tier], false)
	if managers.experience:current_rank() > 0 then
		local tree_name = tweak_data.skilltree.trees[tree].skill
		for infamy, item in pairs(tweak_data.infamy.items) do
			if managers.infamy:owned(infamy) and table_get(item, "upgrades", "skilltree", "tree") == tree_name then
				points = math.round(points * (item.upgrades.skilltree.multiplier or 1))
			end
		end
	end

	return points
end

function SkillTreeManager:unlock_tree(tree)
	if self._global.trees[tree].unlocked then
		return
	end

	local skill_id = tweak_data.skilltree.trees[tree].skill
	local to_unlock = managers.skilltree:next_skill_step(skill_id)
	local total_points, points = managers.skilltree:get_skill_points(skill_id, to_unlock)

	if total_points > self:points() then
		return
	end

	self._global.trees[tree].unlocked = true
	self:_spend_points(tree, nil, total_points, points)
end

-- Skill switches implementation
function SkillTreeManager:_setup(reset)
	if not Global.skilltree_manager or reset then
		Global.skilltree_manager = {}
		Global.skilltree_manager.VERSION = SkillTreeManager.VERSION
		Global.skilltree_manager.reset_message = false
		Global.skilltree_manager.times_respeced = 1
		self._global = Global.skilltree_manager
		self:_setup_skill_switches()
		self._global.selected_skill_switch = 1
		local data = self._global.skill_switches[self._global.selected_skill_switch]
		self._global.points = data.points
		self._global.trees = data.trees
		self._global.skills = data.skills
		self:_setup_specialization()
	end

	self._global = Global.skilltree_manager
end

function SkillTreeManager:_setup_skill_switches()
	self._global.skill_switches = {}
	local switch_data

	for i = 1, #tweak_data.skilltree.skill_switches do
		self._global.skill_switches[i] = {
			unlocked = true,
			name = nil,
			points = Application:digest_value(0, true),
			specialization = false,
		}

		switch_data = self._global.skill_switches[i]
		switch_data.trees = {}
		for tree, data in pairs(tweak_data.skilltree.trees) do
			switch_data.trees[tree] = {
				unlocked = false,
				points_spent = Application:digest_value(0, true),
			}
		end

		switch_data.skills = {}
		for skill_id, data in pairs(tweak_data.skilltree.skills) do
			switch_data.skills[skill_id] = {
				unlocked = 0,
				total = #data,
			}
		end
	end
end

function SkillTreeManager:_setup_specialization()
	if not u39_or_above then
		return
	end

	self._global.specializations = {
		points_present = self:digest_value(0, true),
		points = self:digest_value(0, true),
		total_points = self:digest_value(0, true),
		xp_present = self:digest_value(0, true),
		xp_leftover = self:digest_value(0, true),
		current_specialization = self:digest_value(1, true),
	}

	local max_specialization_points = 0
	for tree, data in ipairs(tweak_data.skilltree.specializations or {}) do
		self._global.specializations[tree] = {
			points_spent = self:digest_value(0, true),
			tiers = {
				current_tier = self:digest_value(0, true),
				max_tier = self:digest_value(#data, true),
				next_tier_data = {
					current_points = self:digest_value(0, true),
					points = self:digest_value(data[1].cost, true),
				},
			},
		}

		for _, tier in ipairs(data) do
			max_specialization_points = max_specialization_points + tier.cost
		end
	end

	self._global.specializations.max_points = self:digest_value(max_specialization_points, true)
end

function SkillTreeManager:points(switch_data)
	return Application:digest_value((switch_data or self._global).points, false)
end

function SkillTreeManager:_set_points(value)
	self._global.points = Application:digest_value(value, true)

	if self._global.skill_switches[self._global.selected_skill_switch] then
		self._global.skill_switches[self._global.selected_skill_switch].points = self._global.points
	end
end

function SkillTreeManager:points_spent(tree, switch_data)
	return Application:digest_value((switch_data or self._global).trees[tree].points_spent, false)
end

function SkillTreeManager:skill_completed(skill_id, switch_data)
	return (switch_data or self._global).skills[skill_id].unlocked
		== (switch_data or self._global).skills[skill_id].total
end

function SkillTreeManager:next_skill_step(skill_id, switch_data)
	return (switch_data or self._global).skills[skill_id].unlocked + 1
end

function SkillTreeManager:skill_unlocked(tree, skill_id, switch_data)
	if not tree then
		for tree_id, _ in pairs(tweak_data.skilltree.trees) do
			if self:skill_unlocked(tree_id, skill_id, switch_data) then
				return true
			end
		end

		return false
	end

	for tier, data in pairs(tweak_data.skilltree.trees[tree].tiers) do
		for _, skill in ipairs(data) do
			if skill == skill_id then
				return self:tier_unlocked(tree, tier, switch_data)
			end
		end
	end
end

function SkillTreeManager:tier_unlocked(tree, tier, switch_data)
	if not self:tree_unlocked(tree, switch_data) then
		return false
	end

	return managers.skilltree:tier_cost(tree, tier) <= self:points_spent(tree, switch_data)
end

function SkillTreeManager:_aquire_points(points, selected_only)
	if selected_only then
		self._global.points = Application:digest_value(self:points() + points, true)

		if self._global.skill_switches[self._global.selected_skill_switch] then
			self._global.skill_switches[self._global.selected_skill_switch].points = self._global.points
		end

		return
	end

	for skill_switch, data in ipairs(self._global.skill_switches) do
		data.points = Application:digest_value(self:points(data) + points, true)
	end

	if self._global.skill_switches[self._global.selected_skill_switch] then
		self._global.points = self._global.skill_switches[self._global.selected_skill_switch].points
	end
end

function SkillTreeManager:tier_unlocked(tree, tier, switch_data)
	if not self:tree_unlocked(tree, switch_data) then
		return false
	end

	local required_points = managers.skilltree:tier_cost(tree, tier)

	return required_points <= self:points_spent(tree, switch_data)
end

function SkillTreeManager:tree_unlocked(tree, switch_data)
	return (switch_data or self._global).trees[tree].unlocked
end

function SkillTreeManager:trees_unlocked(switch_trees)
	local amount = 0
	for _, tree in pairs(switch_trees or self._global.trees) do
		if tree.unlocked then
			amount = amount + 1
		end
	end

	return amount
end

function SkillTreeManager:on_respec_tree(tree, forced_respec_multiplier)
	if SkillTreeManager.VERSION < 5 then
		self:_respec_tree_version4(tree, forced_respec_multiplier)
	elseif SkillTreeManager.VERSION == 5 then
		self:_respec_tree_version5(tree, forced_respec_multiplier)
	else
		self:_respec_tree_version6(tree, forced_respec_multiplier)
	end

	MenuCallbackHandler:_update_outfit_information()
	if SystemInfo:platform() == Idstring("WIN32") and managers.statistics.publish_skills_to_steam then
		managers.statistics:publish_skills_to_steam()
	end
end

function SkillTreeManager:_respec_tree_version6(tree, forced_respec_multiplier)
	local points_spent = self:points_spent(tree)

	self:_reset_skilltree(tree, forced_respec_multiplier)
	self:_aquire_points(points_spent, true)
end

function SkillTreeManager:_respec_tree_version5(tree, forced_respec_multiplier)
	local points_spent = self:points_spent(tree)
	local unlocked = self:trees_unlocked()
	if 0 < unlocked then
		points_spent = points_spent + Application:digest_value(tweak_data.skilltree.unlock_tree_cost[unlocked], false)
	end

	self:_reset_skilltree(tree, forced_respec_multiplier)
	self:_aquire_points(points_spent, true)
end

function SkillTreeManager:_respec_tree_version4(tree, forced_respec_multiplier)
	local points_spent = self:points_spent(tree)
	self:_reset_skilltree(tree, forced_respec_multiplier)
	self:_aquire_points(points_spent, true)
end

function SkillTreeManager:_reset_skilltree(tree, forced_respec_multiplier)
	self:_set_points_spent(tree, 0)
	self._global.trees[tree].unlocked = false
	managers.money:on_respec_skilltree(tree, forced_respec_multiplier)
	local tree_data = tweak_data.skilltree.trees[tree]
	for i = #tree_data.tiers, 1, -1 do
		local tier = tree_data.tiers[i]
		for _, skill in ipairs(tier) do
			self:_unaquire_skill(skill)
		end
	end

	self:_unaquire_skill(tree_data.skill)
end

function SkillTreeManager:can_unlock_skill_switch(selected_skill_switch)
	if not self._global.skill_switches[selected_skill_switch] then
		return false, { "error" }
	end

	if self._global.skill_switches[selected_skill_switch].unlocked then
		return false, { "unlocked" }
	end

	local skill_switch_data = tweak_data.skilltree.skill_switches[selected_skill_switch]
	if not skill_switch_data then
		return false, { "error" }
	end

	local locks = skill_switch_data.locks
	if locks then
		local player_level = managers.experience:current_level()

		local fail_reasons = {}
		if not managers.money:can_afford_unlock_skill_switch(selected_skill_switch) then
			table.insert(fail_reasons, "money")
		end

		if locks.level and player_level < locks.level then
			table.insert(fail_reasons, "level")
		end

		if locks.achievement and not (managers.achievment:get_info(locks.achievement) or {}).awarded then
			table.insert(fail_reasons, "achievement")
		end

		if #fail_reasons ~= 0 then
			return false, fail_reasons
		end
	end

	return true, { "success" }
end

function SkillTreeManager:on_skill_switch_unlocked(selected_skill_switch)
	local can_unlock, reason = self:can_unlock_skill_switch(selected_skill_switch)
	if not can_unlock then
		return
	end

	managers.money:on_unlock_skill_switch(selected_skill_switch)

	self._global.skill_switches[selected_skill_switch].unlocked = true

	if self._global.specializations then
		self._global.skill_switches[selected_skill_switch].specialization =
			self._global.specializations.current_specialization
	end
end

function SkillTreeManager:get_selected_skill_switch()
	return self._global.selected_skill_switch
end

function SkillTreeManager:has_skill_switch_name(skill_switch)
	local data = self._global.skill_switches[skill_switch]
	return data and data.name and true or false
end

function SkillTreeManager:get_skill_switch_name(skill_switch, add_quotation)
	local data = self._global.skill_switches[skill_switch]
	local name = data and data.name
	if name and name ~= "" then
		if add_quotation then
			return '"' .. name .. '"'
		end

		return name
	end

	return self:get_default_skill_switch_name(skill_switch)
end

function SkillTreeManager:get_default_skill_switch_name(skill_switch)
	return managers.localization:text("menu_st_skill_switch") .. tostring(skill_switch)
end

function SkillTreeManager:set_skill_switch_name(skill_switch, name)
	if not self._global.skill_switches[skill_switch] then
		return
	end

	self._global.skill_switches[skill_switch].name = ((name and name ~= "") and name)
end

function SkillTreeManager:switch_skills(selected_skill_switch)
	if selected_skill_switch == self._global.selected_skill_switch then
		return
	end

	if not self._global.skill_switches[selected_skill_switch] then
		return
	end

	local function unaquire_skill(skill_id)
		local progress_data = self._global.skills[skill_id]
		local skill_data = tweak_data.skilltree.skills[skill_id]
		for i = progress_data.unlocked, 1, -1 do
			local step_data = skill_data[i]
			local upgrades = step_data.upgrades
			if upgrades then
				for i = #upgrades, 1, -1 do
					local upgrade = upgrades[i]
					local identifier = UpgradesManager.AQUIRE_STRINGS
						and (UpgradesManager.AQUIRE_STRINGS[2] .. "_" .. tostring(skill_id))
					managers.upgrades:unaquire(upgrade, identifier)
				end
			end
		end
	end

	for tree, data in pairs(tweak_data.skilltree.trees) do
		local tree_data = tweak_data.skilltree.trees[tree]
		for i = #tree_data.tiers, 1, -1 do
			local tier = tree_data.tiers[i]
			for _, skill in ipairs(tier) do
				unaquire_skill(skill)
			end
		end

		unaquire_skill(tree_data.skill)
	end

	self._global.selected_skill_switch = selected_skill_switch

	local data = self._global.skill_switches[self._global.selected_skill_switch]
	self._global.points = data.points
	self._global.trees = data.trees
	self._global.skills = data.skills

	for tree_id, tree_data in pairs(self._global.trees) do
		if tree_data.unlocked and not tweak_data.skilltree.trees[tree_id].dlc then
			local skill_id = tweak_data.skilltree.trees[tree_id].skill
			local skill = tweak_data.skilltree.skills[skill_id]
			local skill_data = self._global.skills[skill_id]
			for i = 1, skill_data.unlocked do
				self:_aquire_skill(skill[i], skill_id, true)
			end

			for tier, skills in pairs(tweak_data.skilltree.trees[tree_id].tiers) do
				for _, skill_id in ipairs(skills) do
					local skill = tweak_data.skilltree.skills[skill_id]
					local skill_data = self._global.skills[skill_id]
					for i = 1, skill_data.unlocked do
						self:_aquire_skill(skill[i], skill_id, true)
					end
				end
			end
		end
	end

	if self._global.specializations then
		self:set_current_specialization(self:digest_value(data.specialization, false))
	end

	-- MenuCallbackHandler:_update_outfit_information()
end

function SkillTreeManager:reset_skilltrees()
	if self._global.VERSION < 5 then
		for tree_id, tree_data in pairs(self._global.trees) do
			self:_respec_tree_version4(tree_id, 1)
		end
	else
		for tree_id, tree_data in pairs(self._global.trees) do
			self:_respec_tree_version5(tree_id, 1)
		end
	end

	self:_setup_skill_switches()
	self._global.selected_skill_switch = 1
	local data = self._global.skill_switches[self._global.selected_skill_switch]
	self._global.points = data.points
	self._global.trees = data.trees
	self._global.skills = data.skills
	-- MenuCallbackHandler:_update_outfit_information()
end

if type(SkillTreeManager.infamy_reset) == "function" then
	local orig_infamy_reset = SkillTreeManager.infamy_reset
	function SkillTreeManager:infamy_reset()
		local skill_switches_unlocks
		if self._global.skill_switches then
			skill_switches_unlocks = {}
			for i, data in ipairs(self._global.skill_switches) do
				skill_switches_unlocks[i] = data.unlocked
			end
		end

		orig_infamy_reset(self)

		if skill_switches_unlocks then
			for i = 1, #self._global.skill_switches do
				self._global.skill_switches[i].unlocked = skill_switches_unlocks[i]
			end
		end
	end
end

function SkillTreeManager:get_tree_progress(tree, switch_data)
	if type(tree) ~= "number" then
		local string_to_number = {
			mastermind = 1,
			enforcer = 2,
			technician = 3,
			ghost = 4,
			hoxton = 5,
		}
		tree = string_to_number[tree]
	end

	local td = tweak_data.skilltree.trees[tree]
	local skill_id = td.skill
	local step = managers.skilltree:next_skill_step(skill_id, switch_data)
	-- local unlocked = managers.skilltree:skill_unlocked(nil, skill_id, switch_data)
	local completed = managers.skilltree:skill_completed(skill_id, switch_data)
	local progress = 1 < step and 1 or 0
	local num_skills = 1
	if 0 < progress then
		for _, tier in ipairs(td.tiers) do
			for _, skill_id in ipairs(tier) do
				step = managers.skilltree:next_skill_step(skill_id, switch_data)
				-- unlocked = managers.skilltree:skill_unlocked(nil, skill_id, switch_data)
				completed = managers.skilltree:skill_completed(skill_id, switch_data)
				num_skills = num_skills + 2
				progress = progress + (1 < step and 1 or 0) + (completed and 1 or 0)
			end
		end
	end

	return progress, num_skills
end

function SkillTreeManager:reset_skilltrees_and_specialization(points_aquired_during_load)
	self:reset_skilltrees()

	self:reset_specializations()

	local level_points = managers.experience:current_level()
	local assumed_points = level_points + points_aquired_during_load
	self:_set_points(assumed_points)
	self._global.VERSION = SkillTreeManager.VERSION
	self._global.reset_message = true
	self._global.times_respeced = 1

	if SystemInfo:platform() == Idstring("WIN32") and managers.statistics.publish_skills_to_steam then
		managers.statistics:publish_skills_to_steam()
	end
end

function SkillTreeManager:reset_specializations()
	if not u39_or_above then
		return
	end

	local current_specialization = self:digest_value(self._global.specializations.current_specialization, false)
	local tree_data = self._global.specializations[current_specialization]
	if tree_data then
		local tier_data = tree_data.tiers
		if tier_data then
			local current_tier = self:digest_value(tier_data.current_tier, false)
			local specialization_tweak = tweak_data.skilltree.specializations[current_specialization]
			for i = 1, current_tier do
				for _, upgrade in ipairs(specialization_tweak[i].upgrades) do
					local identifier = UpgradesManager.AQUIRE_STRINGS
						and (UpgradesManager.AQUIRE_STRINGS[3] .. tostring(current_specialization))
					managers.upgrades:unaquire(upgrade, identifier)
				end
			end
		end
	end

	local max_points = self:digest_value(self._global.specializations.max_points, false)
	local total_points = self:digest_value(self._global.specializations.total_points, false)
	local points_to_retain = math.min(max_points, total_points)
	self:_setup_specialization()
	self._global.specializations.total_points = self:digest_value(points_to_retain, true)
	self._global.specializations.points = self:digest_value(points_to_retain, true)
end

function SkillTreeManager:save(data)
	local state = {
		points = self._global.points,
		trees = self._global.trees,
		skills = self._global.skills,
		skill_switches = self._global.skill_switches,
		selected_skill_switch = self._global.selected_skill_switch,
		specializations = self._global.specializations,
		VERSION = self._global.VERSION or 0,
		reset_message = self._global.reset_message,
		times_respeced = self._global.times_respeced or 1,
	}
	data.SkillTreeManager = state
end

function SkillTreeManager:load(data, version)
	local state = data.SkillTreeManager
	local points_aquired_during_load = self:points()
	if state then
		if state.specializations and self._global.specializations then
			self._global.specializations.total_points = state.specializations.total_points
				or self._global.specializations.total_points
			self._global.specializations.points = state.specializations.points or self._global.specializations.points
			self._global.specializations.points_present = state.specializations.points_present
				or self._global.specializations.points_present
			self._global.specializations.xp_present = state.specializations.xp_present
				or self._global.specializations.xp_present
			self._global.specializations.xp_leftover = state.specializations.xp_leftover
				or self._global.specializations.xp_leftover
			self._global.specializations.current_specialization = state.specializations.current_specialization
				or self._global.specializations.current_specialization
			for tree, data in ipairs(state.specializations) do
				if self._global.specializations[tree] then
					self._global.specializations[tree].points_spent = data.points_spent
						or self._global.specializations[tree].points_spent
				end
			end
		end

		if state.skill_switches then
			self._global.selected_skill_switch = state.selected_skill_switch or 1
			for i, data in pairs(state.skill_switches) do
				if self._global.skill_switches[i] then
					self._global.skill_switches[i].unlocked = data.unlocked
					self._global.skill_switches[i].name = data.name or self._global.skill_switches[i].name
					self._global.skill_switches[i].points = data.points or self._global.skill_switches[i].points
					for tree_id, tree_data in pairs(data.trees) do
						self._global.skill_switches[i].trees[tree_id] = tree_data
					end
					for skill_id, skill_data in pairs(data.skills) do
						if self._global.skill_switches[i].skills[skill_id] then
							self._global.skill_switches[i].skills[skill_id].unlocked = skill_data.unlocked
						end
					end
				end
			end
		else
			self._global.selected_skill_switch = 1
			self._global.skill_switches[1].points = state.points
			if self._global.specializations then
				self._global.skill_switches[1].specialization = data.unlocked
						and self._global.specializations.current_specialization
					or false
			end

			for tree_id, tree_data in pairs(state.trees) do
				self._global.skill_switches[1].trees[tree_id] = tree_data
			end

			for skill_id, skill_data in pairs(state.skills) do
				if self._global.skill_switches[1].skills[skill_id] then
					self._global.skill_switches[1].skills[skill_id].unlocked = skill_data.unlocked
				end
			end
		end

		self:_verify_loaded_data(points_aquired_during_load)
		self._global.VERSION = state.VERSION
		self._global.reset_message = state.reset_message
		self._global.times_respeced = state.times_respeced
		if not self._global.VERSION or self._global.VERSION ~= SkillTreeManager.VERSION then
			managers.savefile:add_load_done_callback(
				callback(self, self, "reset_skilltrees_and_specialization", points_aquired_during_load)
			)
		end
	end
end

function SkillTreeManager:_verify_loaded_data(points_aquired_during_load)
	local level_points = managers.experience:current_level()
	local assumed_points = level_points + points_aquired_during_load

	for i, switch_data in ipairs(self._global.skill_switches) do
		local points = assumed_points

		for skill_id, data in pairs(clone(switch_data.skills)) do
			if not tweak_data.skilltree.skills[skill_id] then
				switch_data.skills[skill_id] = nil
			end
		end

		for tree_id, data in pairs(clone(switch_data.trees)) do
			if not tweak_data.skilltree.trees[tree_id] then
				switch_data.trees[tree_id] = nil
			end
		end

		for tree_id, data in pairs(clone(switch_data.trees)) do
			local points_spent = math.max(Application:digest_value(data.points_spent, false), 0)
			data.points_spent = Application:digest_value(points_spent, true)
			points = points - points_spent
		end

		local unlocked = self:trees_unlocked(switch_data.trees)

		while unlocked > 0 do
			unlocked = unlocked - 1
		end

		switch_data.points = Application:digest_value(points, true)
	end

	for i = 1, #self._global.skill_switches do
		if
			self._global.skill_switches[i]
			and Application:digest_value(self._global.skill_switches[i].points or 0, false) < 0
		then
			local switch_data = self._global.skill_switches[i]

			if
				self._global.skill_switches[self._global.selected_skill_switch]
				and self._global.skill_switches[self._global.selected_skill_switch] == switch_data
			then
				self._global.selected_skill_switch = 1
			end

			switch_data.points = Application:digest_value(0, true)
		end
	end

	if not self._global.skill_switches[self._global.selected_skill_switch] then
		self._global.selected_skill_switch = 1
	end

	local data = self._global.skill_switches[self._global.selected_skill_switch]
	self._global.points = data.points
	self._global.trees = data.trees
	self._global.skills = data.skills

	-- for tree_id, tree_data in pairs(self._global.trees) do
	-- 	if tree_data.unlocked and not tweak_data.skilltree.trees[tree_id].dlc then
	-- 		for tier, skills in pairs(tweak_data.skilltree.trees[tree_id].tiers) do
	-- 			for _, skill_id in ipairs(skills) do
	-- 				local skill = tweak_data.skilltree.skills[skill_id]
	-- 				local skill_data = self._global.skills[skill_id]

	-- 				for i = 1, skill_data.unlocked do
	-- 					self:_aquire_skill(skill[i], skill_id, true)
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- end

	for tree_id, tree_data in pairs(self._global.trees) do
		if tree_data.unlocked and not tweak_data.skilltree.trees[tree_id].dlc then
			local skill_id = tweak_data.skilltree.trees[tree_id].skill
			local skill = tweak_data.skilltree.skills[skill_id]
			local skill_data = self._global.skills[skill_id]
			for i = 1, skill_data.unlocked do
				self:_aquire_skill(skill[i], skill_id, true)
			end
			for tier, skills in pairs(tweak_data.skilltree.trees[tree_id].tiers) do
				for _, skill_id in ipairs(skills) do
					local skill = tweak_data.skilltree.skills[skill_id]
					local skill_data = self._global.skills[skill_id]
					for i = 1, skill_data.unlocked do
						self:_aquire_skill(skill[i], skill_id, true)
					end
				end
			end
		end
	end
end

function SkillTreeManager:open_quick_select()
	local button_list = {}

	for skill_switch, data in pairs(self._global.skill_switches) do
		local text_id = managers.skilltree:get_skill_switch_name(skill_switch, true)
			or managers.localization:to_upper_text("menu_st_locked_skill_switch")

		table.insert(button_list, {
			text = text_id,
			callback = function()
				self:switch_skills(skill_switch)

				local mcm = managers.menu_component
				if mcm._skilltree_gui then
					local node = mcm._skilltree_gui._node
					mcm:close_skilltree_gui()
					mcm:create_skilltree_gui(node)
				end
			end,
		})
	end

	table.insert(button_list, { text = "" })

	table.insert(button_list, {
		text = managers.localization:text("dialog_cancel"),
		cancel_button = true,
		is_focused_button = true,
	})

	_G["QuickMenu"]:new("", "", button_list, true)
end
