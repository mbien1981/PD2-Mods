if RequiredScript == "lib/managers/hud/hudteammate" then
	local HUDTeammate = _G["HUDTeammate"]

	Hooks:PostHook(HUDTeammate, "init", "init_kill_counter", function(self, teammates_panel, is_player, width)
		self:init_kill_counter()
	end)

	function HUDTeammate:init_kill_counter()
		self._kill_counter = self._panel:text({
			text = " 0:0 - 0 | 0:0",
			font = tweak_data.hud_players.name_font,
			font_size = tweak_data.hud_players.name_size,
			vertical = "bottom",
			visible = self._main_player,
		})
		managers.hud:make_fine_text(self._kill_counter)
	end

	Hooks:PostHook(HUDTeammate, "set_name", "position_kill_counter", function(self, state)
		if alive(self._kill_counter) then
			local teammate_panel = self._panel
			local name_bg = teammate_panel:child("name_bg")

			self._kill_counter:set_x(name_bg:x() + name_bg:w() + 4)
			self._kill_counter:set_y(name_bg:y())
		end
	end)

	function HUDTeammate:update_kill_counter()
		local player = managers.player:player_unit()
		if not alive(player) then
			return
		end

		local kills = managers.statistics:session_total_killed()
		local weapon_id = player:inventory():equipped_unit():base():get_name_id()
		local weapon_kills = managers.statistics._global.session.killed_by_weapon[weapon_id]
			or { count = 0, headshots = 0 }

		self._kill_counter:set_text(
			string.format(
				" %d:%d - %d | %d:%d",
				kills.count,
				kills.head_shots,
				kills.melee,
				weapon_kills.count,
				weapon_kills.headshots
			)
		)
		managers.hud:make_fine_text(self._kill_counter)

		local teammate_panel = self._panel
		local name_bg = teammate_panel:child("name_bg")
		self._kill_counter:set_x(name_bg:x() + name_bg:w() + 4)
	end
end

if RequiredScript == "lib/managers/hudmanager" then
	Hooks:PostHook(HUDManager, "update", "update_kill_counter", function(self, t, dt)
		local player_panel = self._teammate_panels[HUDManager.PLAYER_PANEL]
		if player_panel then
			player_panel:update_kill_counter()
		end
	end)
end
