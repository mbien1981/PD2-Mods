local orig_init_managers = Setup.init_managers
function Setup:init_managers(managers)
	orig_init_managers(self, managers)

	managers.multi_profile = MultiProfileManager:new()
end
