local public = {}
local private = {}

local completed = {}

function public.completeStep(incidentId: string, step: string)
	completed[incidentId] = completed[incidentId] or {}
	completed[incidentId][step] = true
	print(step .. " step was completed for: " .. incidentId)
end

function public.isSecured(incident): boolean
	local steps = incident.config.securingSteps
	if #steps == 0 then
		return true
	end

	local done = completed[incident.id] or {}
	for _, step in steps do
		if not done[step] then
			return false
		end
	end
	return true
end

function public.clearIncident(incidentId: string)
	completed[incidentId] = nil
end

return public
