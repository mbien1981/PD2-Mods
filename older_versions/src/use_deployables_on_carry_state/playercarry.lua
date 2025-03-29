PlayerCarry.throw_limit_t = 0.5

function PlayerCarry:_check_use_item(t, input)
	local new_action = nil
	local action_wanted = input.btn_use_item_release and self._throw_time and t and t < self._throw_time

	if input.btn_use_item_press then
		self._throw_down = true
		self._second_press = false
		self._throw_time = t + PlayerCarry.throw_limit_t
	end

	if action_wanted then
		local action_forbidden = self._use_item_expire_t
			or self:_changing_weapon()
			or self:_interacting()
			or self._ext_movement:has_carry_restriction()
			-- cross-version compatibility check
			or (self._is_throwing_projectile and self:_is_throwing_projectile() or self._is_throwing_grenade and self:_is_throwing_grenade())
			or self:_on_zipline()

		if not action_forbidden then
			managers.player:drop_carry()

			new_action = true
		end
	end

	if self._throw_down then
		if input.btn_use_item_release then
			self._throw_down = false
			self._second_press = false

			return PlayerCarry.super._check_use_item(self, t, input)
		elseif self._throw_time < t then
			if not self._second_press then
				input.btn_use_item_press = true
				self._second_press = true
			end

			return PlayerCarry.super._check_use_item(self, t, input)
		end
	end

	return new_action
end

Hooks:PostHook(PlayerCarry, "_update_check_actions", "QoLPack_PlayerCarry:update", function(self, t, dt)
	self:_update_use_item_timers(t, self:_get_input(t, dt))
end)
