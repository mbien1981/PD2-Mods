Hooks:PostHook(Setup, "init_managers", "LP:Setup.init_managers", function(self, managers)
	managers.multi_profile = MultiProfileManager:new()
end)
