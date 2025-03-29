function PlayerManager:equipment_slot(equipment)
	for i = 1, #self._global.kit.equipment_slots do
		if self._global.kit.equipment_slots[i] == equipment then
			return i
		end
	end

	return false
end
