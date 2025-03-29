local HUDMissionBriefing = _G["HUDMissionBriefing"]
function HUDMissionBriefing:inside_slot(peer_id, child, x, y)
	local slot = self._ready_slot_panel:child("slot_" .. tostring(peer_id))

	if not slot or not alive(slot) then
		return nil
	end

	local object = slot:child(child)

	if not object or not alive(object) then
		return nil
	end

	if not slot:child("status") or not alive(slot:child("status")) or not slot:child("status"):visible() then
		return
	end

	return object:inside(x, y)
end
