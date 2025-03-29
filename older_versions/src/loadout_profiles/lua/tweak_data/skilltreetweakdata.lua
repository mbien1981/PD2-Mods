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

Hooks:PostHook(SkillTreeTweakData, "init", "LP_SkillTreeTweakData:init", function(self)
	local digest = function(value)
		return Application:digest_value(value, true)
	end

	if not self.unlock_tree_cost then
		self.unlock_tree_cost = {
			digest(0),
			digest(0),
			digest(0),
			digest(0),
		}
	end

	if not self.skill_switches then
		self.skill_switches = {
			{},
			{ locks = { level = 50 } },
			{ locks = { level = 75 } },
			{ locks = { level = 100 } },
		}
	end

	for _ = 1, (get(LoadoutProfiles, "settings", "max_profiles") or 5) - 5 do
		table.insert(self.skill_switches, { locks = { level = 100 } })
	end

	table.insert(self.skill_switches, { locks = { level = 100, achievement = "frog_1" } })
end)
