-- pre-U22
function ExperienceManager:current_rank()
	return self._global.rank and Application:digest_value(self._global.rank, false) or 0
end
