local E = unpack(ElvUI)
local UFC = E:GetModule('TUI_UnitFrames')
local UF = E:GetModule('UnitFrames')

local PREVIEW_ICON = 136243
local previewFrames = {}

local function GetOrCreatePreview(parent, index)
	local key = parent:GetName() .. index
	if previewFrames[key] then return previewFrames[key] end

	local frame = CreateFrame('Frame', nil, parent)
	frame:CreateBackdrop(nil, nil, nil, nil, true)
	if frame.backdrop then
		frame.backdrop:SetBackdropBorderColor(0.75, 0.55, 0.02, 1)
	end

	local tex = frame:CreateTexture(nil, 'ARTWORK')
	tex:SetAllPoints()
	tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	tex:SetTexture(PREVIEW_ICON)
	frame.icon = tex

	previewFrames[key] = frame
	return frame
end

local function ShowPreviews(frame)
	local element = E.Retail and frame.PrivateAuras
	if not element then return end

	local db = frame.db and frame.db.privateAuras
	if not db or not db.enable then return end

	local iconSize = db.icon and db.icon.size or 32
	local amount = db.icon and db.icon.amount or 1
	local point = db.icon and db.icon.point or 'RIGHT'
	local offset = db.icon and db.icon.offset or 2
	local borderScale = db.borderScale or 1

	for i = 1, amount do
		local preview = GetOrCreatePreview(element, i)
		preview:Size(iconSize)

		if preview.backdrop then
			local edgeSize = E:Scale(borderScale)
			preview.backdrop:SetOutside(preview, edgeSize, edgeSize)
		end

		preview:ClearAllPoints()

		if i == 1 then
			preview:Point('CENTER', element, 'CENTER', 0, 0)
		else
			local offsetX, offsetY = 0, 0
			if point == 'RIGHT' then offsetX = offset
			elseif point == 'LEFT' then offsetX = -offset
			elseif point == 'TOP' then offsetY = offset
			else offsetY = -offset end
			preview:Point(E.InversePoints[point], previewFrames[element:GetName() .. (i - 1)], point, offsetX, offsetY)
		end

		preview:Show()
	end
end

local function HidePreviews(frame)
	local element = E.Retail and frame.PrivateAuras
	if not element then return end

	local name = element:GetName()
	for key, preview in pairs(previewFrames) do
		if key:find(name, 1, true) then
			preview:Hide()
		end
	end
end

function UFC:InitPrivateAuraPreview()
	hooksecurefunc(UF, 'ForceShow', function(_, frame)
		ShowPreviews(frame)
	end)

	hooksecurefunc(UF, 'UnforceShow', function(_, frame)
		HidePreviews(frame)
	end)
end
