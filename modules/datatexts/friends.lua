local E, _, _, _, G = unpack(ElvUI)
local TUI = E:GetModule('TrenchyUI')
local DT = E:GetModule('DataTexts')

local format, sort, wipe, ipairs, next, gsub, strfind, strmatch, max = format, sort, wipe, ipairs, next, gsub, strfind, strmatch, math.max
local BNConnected = BNConnected
local BNGetNumFriends = BNGetNumFriends
local GetQuestDifficultyColor = GetQuestDifficultyColor
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local ToggleFriendsFrame = ToggleFriendsFrame

local GetFriendAccountInfo = C_BattleNet.GetFriendAccountInfo
local GetFriendGameAccountInfo = C_BattleNet.GetFriendGameAccountInfo
local GetFriendNumGameAccounts = C_BattleNet.GetFriendNumGameAccounts
local BNet_GetValidatedCharacterName = BNet_GetValidatedCharacterName
local C_FriendList_GetNumFriends = C_FriendList.GetNumFriends
local C_FriendList_GetNumOnlineFriends = C_FriendList.GetNumOnlineFriends
local C_FriendList_GetFriendInfoByIndex = C_FriendList.GetFriendInfoByIndex
local C_FriendList_ShowFriends = C_FriendList.ShowFriends
local C_PartyInfo_InviteUnit = C_PartyInfo.InviteUnit
local ChatFrame_SendBNetTell = (ChatFrameUtil and ChatFrameUtil.SendBNetTell) or ChatFrame_SendBNetTell
local BNInviteFriend = BNInviteFriend
local GetTitleIconTexture = C_Texture.GetTitleIconTexture
local ICON_VERSION = Enum.TitleIconVersion and Enum.TitleIconVersion.Small

local friendOnline, friendOffline = gsub(_G.ERR_FRIEND_ONLINE_SS, '|Hplayer:%%s|h%[%%s%]|h', ''), gsub(_G.ERR_FRIEND_OFFLINE_S, '%%s', '')
local FRIENDS = _G.FRIENDS
local WOW_PROJECT_ID = WOW_PROJECT_ID
local wowString = _G.BNET_CLIENT_WOW


local friendTable, bnTable = {}, {}
local clientGroups, clientOrder = {}, {}
local displayString = ''
local db

local clientTags = {
	WoW  = { index = 1,  tag = 'World of Warcraft' },
	WTCG = { index = 2,  tag = 'Hearthstone' },
	Hero = { index = 3,  tag = 'Heroes of the Storm' },
	Pro  = { index = 4,  tag = 'Overwatch' },
	OSI  = { index = 5,  tag = 'Diablo II' },
	D3   = { index = 6,  tag = 'Diablo III' },
	Fen  = { index = 7,  tag = 'Diablo IV' },
	ANBS = { index = 8,  tag = 'Diablo Immortal' },
	S1   = { index = 9,  tag = 'StarCraft' },
	S2   = { index = 10, tag = 'StarCraft II' },
	W3   = { index = 11, tag = 'Warcraft III' },
	RTRO = { index = 12, tag = 'Arcade Collection' },
	WLBY = { index = 13, tag = 'Crash Bandicoot 4' },
	VIPR = { index = 14, tag = 'Black Ops 4' },
	ODIN = { index = 15, tag = 'Warzone' },
	AUKS = { index = 16, tag = 'Warzone 2.0' },
	LAZR = { index = 17, tag = 'Modern Warfare II' },
	ZEUS = { index = 18, tag = 'Cold War' },
	FORE = { index = 19, tag = 'Vanguard' },
	GRY  = { index = 20, tag = 'Arclight Rumble' },
	App  = { index = 21, tag = 'Battle.net' },
	BSAp = { index = 22, tag = 'Mobile' },
}

local ROW_HEIGHT = 16
local ROW_PAD = 4
local SECTION_PAD = 10
local TOOLTIP_PAD = 8
local MAX_ROWS = 30

local statusText = {
	AFK = ' |cffFF9900AFK|r',
	DND = ' |cffFF3333DND|r',
}

local statusColor = {
	AFK = { r = 1, g = 0.6, b = 0 },
	DND = { r = 1, g = 0.2, b = 0.2 },
}

local activezone = { r = 0.3, g = 1.0, b = 0.3 }
local inactivezone = { r = 0.65, g = 0.65, b = 0.65 }

-- Tooltip frame and rows
local tooltip, headerText
local rows = {}
local hideTimer

local function CancelHide()
	if hideTimer then hideTimer:Cancel(); hideTimer = nil end
end

local function ScheduleHide()
	CancelHide()
	hideTimer = C_Timer.NewTimer(0.15, function()
		hideTimer = nil
		if tooltip then tooltip:Hide() end
	end)
end

local function InGroup(name, realmName)
	if realmName and realmName ~= '' and realmName ~= E.myrealm then
		name = name .. '-' .. realmName
	end
	return (UnitInParty(name) or UnitInRaid(name)) and ' |cffaaaaaa*|r' or ''
end



local function FriendSortFunc(a, b)
	return a.name < b.name
end

local function BuildFriendTable(total)
	if total <= 0 then wipe(friendTable); return end
	if not C_FriendList_GetFriendInfoByIndex(1) then return end
	wipe(friendTable)
	for i = 1, total do
		local info = C_FriendList_GetFriendInfoByIndex(i)
		if info and info.connected then
			local className = E:UnlocalizedClassName(info.className) or ''
			local statusKey = (info.afk and 'AFK') or (info.dnd and 'DND') or nil
			friendTable[#friendTable + 1] = {
				name = info.name,
				level = info.level,
				class = className,
				zone = info.area or '',
				status = statusKey and statusText[statusKey] or '',
				statusKey = statusKey,
			}
		end
	end
	sort(friendTable, FriendSortFunc)
end

local function ClientSortFunc(a, b)
	local A, B = clientTags[a], clientTags[b]
	if A and B then return A.index < B.index end
	return a < b
end

local function BNSortFunc(a, b)
	if a.isFavorite ~= b.isFavorite then return a.isFavorite end
	if a.client and b.client and a.client == b.client and a.client == wowString then
		if a.name and b.name then return a.name < b.name end
	end
	return (a.displayName or '') < (b.displayName or '')
end

local function BuildBNTable(total)
	if total <= 0 then wipe(bnTable); wipe(clientGroups); wipe(clientOrder); return end
	if not GetFriendAccountInfo(1) then return end
	wipe(bnTable)
	wipe(clientGroups)
	wipe(clientOrder)

	for i = 1, total do
		local accountInfo = GetFriendAccountInfo(i)
		local gameInfo = accountInfo and accountInfo.gameAccountInfo
		if gameInfo and gameInfo.isOnline then
			local client = gameInfo.clientProgram
			local statusKey = (accountInfo.isAFK and 'AFK') or (accountInfo.isDND and 'DND') or nil
			local status = statusKey and statusText[statusKey] or ''
			local charName = BNet_GetValidatedCharacterName(gameInfo.characterName, accountInfo.battleTag, client) or ''
			local className = E:UnlocalizedClassName(gameInfo.className) or ''

			-- Check additional game accounts for a better WoW character
			local numAccounts = GetFriendNumGameAccounts(i)
			if numAccounts and numAccounts > 1 then
				for y = 1, numAccounts do
					local other = GetFriendGameAccountInfo(i, y)
					if other and other.clientProgram == wowString and other.wowProjectID == WOW_PROJECT_ID then
						client = wowString
						charName = BNet_GetValidatedCharacterName(other.characterName, accountInfo.battleTag, wowString) or ''
						className = E:UnlocalizedClassName(other.className) or ''
						gameInfo = other
						break
					end
				end
			end

			local isBTag = accountInfo.isBattleTagFriend
			local btagName = accountInfo.battleTag and strmatch(accountInfo.battleTag, '([^#]+)')
			local realName = accountInfo.accountName or ''
			local displayName
			if isBTag then
				displayName = btagName or realName
			else
				displayName = realName
			end
			-- Only show charName when it differs from the battletag name
			local showChar = charName ~= '' and charName ~= btagName

			local entry = {
				accountName = realName,
				battleTag = accountInfo.battleTag,
				displayName = displayName,
				name = charName,
				level = gameInfo.characterLevel or 0,
				class = className,
				zone = gameInfo.areaName or '',
				realmName = gameInfo.realmName or '',
				client = client,
				status = status,
				statusKey = statusKey,
				gameID = gameInfo.gameAccountID,
				isWoW = client == wowString,
				wowProjectID = gameInfo.wowProjectID,
				isFavorite = accountInfo.isFavorite or false,
				showChar = showChar,
			}

			bnTable[#bnTable + 1] = entry

			if not clientGroups[client] then
				clientGroups[client] = {}
				clientOrder[#clientOrder + 1] = client
			end
			clientGroups[client][#clientGroups[client] + 1] = entry
		end
	end

	sort(clientOrder, ClientSortFunc)
	for _, group in next, clientGroups do
		sort(group, BNSortFunc)
	end
end

local function GetDTFont()
	return TUI:GetDTFont(db)
end

local function CreateTooltip()
	if tooltip then return end

	tooltip = CreateFrame('Frame', 'TUIFriendsTooltip', E.UIParent, 'BackdropTemplate')
	tooltip:SetFrameStrata('TOOLTIP')
	tooltip:SetClampedToScreen(true)
	tooltip:SetClampRectInsets(-2, 2, 2, -2)
	tooltip:Hide()
	tooltip:SetTemplate('Transparent')

	tooltip:SetScript('OnEnter', CancelHide)
	tooltip:SetScript('OnLeave', ScheduleHide)

	local font, fontSize = GetDTFont()

	headerText = tooltip:CreateFontString(nil, 'OVERLAY')
	headerText:SetPoint('TOPLEFT', tooltip, 'TOPLEFT', TOOLTIP_PAD, -TOOLTIP_PAD)
	headerText:SetPoint('TOPRIGHT', tooltip, 'TOPRIGHT', -TOOLTIP_PAD, -TOOLTIP_PAD)
	headerText:FontTemplate(font, fontSize + 2, 'OUTLINE')
	headerText:SetJustifyH('LEFT')
end

local function GetOrCreateRow(index)
	if rows[index] then return rows[index] end

	CreateTooltip()

	local font, fontSize, fontOutline = GetDTFont()

	local row = CreateFrame('Button', nil, tooltip)
	row:SetHeight(ROW_HEIGHT)

	row.level = row:CreateFontString(nil, 'OVERLAY')
	row.level:SetPoint('LEFT', row, 'LEFT', 0, 0)
	row.level:SetWidth(24)
	row.level:FontTemplate(font, fontSize, fontOutline)
	row.level:SetJustifyH('RIGHT')

	row.name = row:CreateFontString(nil, 'OVERLAY')
	row.name:SetPoint('LEFT', row.level, 'RIGHT', 4, 0)
	row.name:SetPoint('RIGHT', row.zone, 'LEFT', -4, 0)
	row.name:FontTemplate(font, fontSize, fontOutline)
	row.name:SetJustifyH('LEFT')
	row.name:SetWordWrap(false)

	row.zone = row:CreateFontString(nil, 'OVERLAY')
	row.zone:SetPoint('RIGHT', row, 'RIGHT', 0, 0)
	row.zone:FontTemplate(font, fontSize, fontOutline)
	row.zone:SetJustifyH('RIGHT')

	row.highlight = row:CreateTexture(nil, 'HIGHLIGHT')
	row.highlight:SetAllPoints()
	row.highlight:SetColorTexture(1, 1, 1, 0.1)

	row:SetScript('OnEnter', function(self)
		CancelHide()
		if self.friendName or self.friendBNetName then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
			local classc = self.friendClass and E:ClassColor(self.friendClass)
			if self.friendBNetName then
				GameTooltip:AddLine(self.friendBNetName, 1, 1, 1)
				if self.friendName and self.friendName ~= '' then
					if classc then
						GameTooltip:AddLine(self.friendName, classc.r, classc.g, classc.b)
					else
						GameTooltip:AddLine(self.friendName, 0.7, 0.7, 0.7)
					end
				end
			elseif self.friendName then
				if classc then
					GameTooltip:AddLine(self.friendName, classc.r, classc.g, classc.b)
				else
					GameTooltip:AddLine(self.friendName, 1, 1, 1)
				end
			end
			GameTooltip:AddLine(' ')
			GameTooltip:AddLine('Left-click: Whisper', 0.7, 0.7, 0.7)
			if self.canInvite then
				GameTooltip:AddLine('Right-click: Invite', 0.7, 0.7, 0.7)
			end
			GameTooltip:Show()
		end
	end)
	row:SetScript('OnLeave', function()
		ScheduleHide()
		GameTooltip:Hide()
	end)
	row:SetScript('OnClick', function(self, button)
		if button == 'LeftButton' then
			if self.friendBNetName then
				ChatFrame_SendBNetTell(self.friendBNetName)
			elseif self.friendName then
				ChatFrame_OpenChat('/w ' .. self.friendName .. ' ')
			end
		elseif button == 'RightButton' and self.canInvite then
			if self.friendGameID then
				BNInviteFriend(self.friendGameID)
			elseif self.friendName then
				C_PartyInfo_InviteUnit(self.friendName)
			end
		end
	end)
	row:RegisterForClicks('LeftButtonUp', 'RightButtonUp')

	rows[index] = row
	return row
end

-- Apply current font settings to all tooltip elements
local function ApplyFonts()
	local font, fontSize, fontOutline = GetDTFont()
	if headerText then headerText:FontTemplate(font, fontSize + 2, 'OUTLINE') end
	for _, row in ipairs(rows) do
		local fs = row.isHeader and (fontSize + 2) or fontSize
		row.level:FontTemplate(font, fs, fontOutline)
		row.name:FontTemplate(font, fs, fontOutline)
		row.zone:FontTemplate(font, fs, fontOutline)
	end
end

local function GetOrCreateIcon(row)
	if row.clientIcon then return row.clientIcon end
	local icon = row:CreateTexture(nil, 'OVERLAY')
	icon:SetSize(16, 16)
	icon:SetPoint('LEFT', row, 'LEFT', 0, 0)
	row.clientIcon = icon
	return icon
end

local function SetupHeaderRow(row, text, prevRow, client)
	row.isHeader = true
	row.level:SetText('')
	row.zone:SetText('')
	row.friendName = nil
	row.friendBNetName = nil
	row.friendClass = nil
	row.canInvite = false
	row.friendGameID = nil

	local icon = GetOrCreateIcon(row)
	row.name:ClearAllPoints()
	if client and GetTitleIconTexture and ICON_VERSION then
		icon:SetTexture(nil)
		icon:Show()
		GetTitleIconTexture(client, ICON_VERSION, function(success, texture)
			if success and texture then icon:SetTexture(texture) end
		end)
		row.name:SetPoint('LEFT', icon, 'RIGHT', 4, 0)
	else
		icon:Hide()
		row.name:SetPoint('LEFT', row.level, 'RIGHT', 4, 0)
	end

	row.name:SetText(text)
	local cc = E:ClassColor(E.myclass)
	row.name:SetTextColor(cc.r, cc.g, cc.b)

	local pad = prevRow and -SECTION_PAD or -6
	local anchor = prevRow or headerText
	row:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, pad)
	row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
	row:Show()
end

local function ShowTooltip(panel)
	CreateTooltip()
	CancelHide()
	C_FriendList_ShowFriends()

	local numberOfFriends = C_FriendList_GetNumFriends() or 0
	local totalBNet = BNGetNumFriends() or 0

	BuildFriendTable(numberOfFriends)
	if BNConnected() then BuildBNTable(totalBNet) end

	local totalOnline = #friendTable + #bnTable
	if totalOnline == 0 then return end

	headerText:SetText(format('%s  |cff999999Online: %d|r', FRIENDS, totalOnline))

	local shown = 0

	-- Section: Character friends
	local hasCharHeader = false
	local headerCount = 0
	for _, info in ipairs(friendTable) do
		if shown >= MAX_ROWS then break end

		if not hasCharHeader then
			shown = shown + 1
			headerCount = headerCount + 1
			local row = GetOrCreateRow(shown)
			SetupHeaderRow(row, 'Character Friends', shown > 1 and rows[shown - 1] or nil)
			hasCharHeader = true
		end

		shown = shown + 1
		local row = GetOrCreateRow(shown)
		if row.clientIcon then row.clientIcon:Hide() end
		row.name:ClearAllPoints()
		row.name:SetPoint('LEFT', row.level, 'RIGHT', 4, 0)
		local levelc = GetQuestDifficultyColor(info.level)
		local classc = E:ClassColor(info.class) or levelc

		row.level:SetText(info.level)
		row.level:SetTextColor(levelc.r, levelc.g, levelc.b)

		local groupTag = InGroup(info.name)
		row.name:SetText(info.name .. groupTag .. info.status)
		local namec = info.statusKey and statusColor[info.statusKey] or classc
		row.name:SetTextColor(namec.r, namec.g, namec.b)

		local zonec = (E.MapInfo.zoneText and E.MapInfo.zoneText == info.zone) and activezone or inactivezone
		row.zone:SetText(info.zone)
		row.zone:SetTextColor(zonec.r, zonec.g, zonec.b)

		row.isHeader = nil
		row.friendName = info.name
		row.friendBNetName = nil
		row.friendClass = info.class
		row.canInvite = groupTag == ''
		row.friendGameID = nil

		row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
		row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
		row:Show()
	end

	-- Section: BNet friends grouped by client
	for _, client in ipairs(clientOrder) do
		local group = clientGroups[client]
		local skip = db and db.hideMobile and client == 'BSAp'
		if not skip and group and #group > 0 and shown < MAX_ROWS then
			-- Section header
			shown = shown + 1
			headerCount = headerCount + 1
			local hdr = GetOrCreateRow(shown)
			local tagInfo = clientTags[client]
			local tag = tagInfo and tagInfo.tag or client
			SetupHeaderRow(hdr, tag, shown > 1 and rows[shown - 1] or nil, client)

			for _, info in ipairs(group) do
				if shown >= MAX_ROWS then break end

				shown = shown + 1
				local row = GetOrCreateRow(shown)
				if row.clientIcon then row.clientIcon:Hide() end
				row.name:ClearAllPoints()
				row.name:SetPoint('LEFT', row.level, 'RIGHT', 4, 0)

				local groupTag = info.isWoW and InGroup(info.name or '', info.realmName) or ''

				if info.isWoW and info.level and info.level > 0 then
					local levelc = GetQuestDifficultyColor(info.level)
					local classc = E:ClassColor(info.class) or levelc
					row.level:SetText(info.level)
					row.level:SetTextColor(levelc.r, levelc.g, levelc.b)

					local nameStr = info.displayName
					if info.showChar then
						nameStr = nameStr .. ' - ' .. info.name
					end
					nameStr = nameStr .. groupTag .. info.status
					row.name:SetText(nameStr)
					local namec = info.statusKey and statusColor[info.statusKey] or classc
					row.name:SetTextColor(namec.r, namec.g, namec.b)

					local zonec = (E.MapInfo.zoneText and E.MapInfo.zoneText == info.zone) and activezone or inactivezone
					row.zone:SetText(info.zone)
					row.zone:SetTextColor(zonec.r, zonec.g, zonec.b)
				else
					row.level:SetText('')
					row.name:ClearAllPoints()
					row.name:SetPoint('LEFT', row, 'LEFT', 0, 0)
					local nameStr = info.displayName
					if info.showChar then
						nameStr = nameStr .. ' - ' .. info.name
					end
					nameStr = nameStr .. info.status
					row.name:SetText(nameStr)
					local namec = info.statusKey and statusColor[info.statusKey]
					if namec then
						row.name:SetTextColor(namec.r, namec.g, namec.b)
					else
						row.name:SetTextColor(0.9, 0.9, 0.9)
					end
					row.zone:SetText('')
					row.zone:SetTextColor(0.93, 0.93, 0.93)
				end

				row.isHeader = nil
				row.friendName = info.name ~= '' and info.name or nil
				row.friendBNetName = info.accountName
				row.friendClass = info.class ~= '' and info.class or nil
				row.canInvite = info.isWoW and info.wowProjectID == WOW_PROJECT_ID and groupTag == ''
				row.friendGameID = info.gameID

				row:SetPoint('TOPLEFT', rows[shown - 1], 'BOTTOMLEFT', 0, -ROW_PAD)
				row:SetPoint('RIGHT', tooltip, 'RIGHT', -TOOLTIP_PAD, 0)
				row:Show()
			end
		end
	end

	-- Hide unused rows
	for i = shown + 1, #rows do
		rows[i]:Hide()
	end

	ApplyFonts()

	-- Measure widths from actual text
	local maxName, maxZone, maxNonWoWName = 0, 0, 0
	for i = 1, shown do
		local row = rows[i]
		local nw = row.name:GetUnboundedStringWidth()
		local zw = row.zone:GetUnboundedStringWidth()
		if row.isHeader then
			-- header width includes icon; tracked separately via headerWidth
		elseif zw > 0 then
			if nw > maxName then maxName = nw end
		else
			if nw > maxNonWoWName then maxNonWoWName = nw end
		end
		if zw > maxZone then maxZone = zw end
	end

	local levelWidth = 30
	local iconWidth = 20
	local gap = 16
	local nameWidth = maxName + 12
	local zoneWidth = maxZone > 0 and (maxZone + gap) or 0
	local wowRowWidth = TOOLTIP_PAD * 2 + levelWidth + nameWidth + zoneWidth
	local nonWoWRowWidth = TOOLTIP_PAD * 2 + maxNonWoWName + 12
	local headerWidth = TOOLTIP_PAD * 2 + iconWidth + (headerText:GetUnboundedStringWidth() or 0)
	local tooltipWidth = max(wowRowWidth, nonWoWRowWidth, headerWidth)

	local sectionExtra = headerCount > 1 and ((headerCount - 1) * (SECTION_PAD - ROW_PAD)) or 0
	local contentH = TOOLTIP_PAD + headerText:GetStringHeight() + 6 + (shown * (ROW_HEIGHT + ROW_PAD)) + sectionExtra + TOOLTIP_PAD

	tooltip:SetSize(tooltipWidth, contentH)
	TUI:AnchorDTTooltip(tooltip, panel)
	tooltip:Show()
end

-- DT callbacks
local function OnEnter(panel)
	DT.tooltip:Hide()
	ShowTooltip(panel)
end

local function OnLeave()
	ScheduleHide()
end

local function OnEvent(panel, event, arg1)
	if event == 'PLAYER_ENTERING_WORLD' then
		C_FriendList_ShowFriends()
	end

	local onlineFriends = C_FriendList_GetNumOnlineFriends() or 0
	local _, numBNetOnline = BNGetNumFriends()
	numBNetOnline = numBNetOnline or 0

	if event == 'CHAT_MSG_SYSTEM' then
		if E:IsSecretValue(arg1) or (not strfind(arg1, friendOnline) and not strfind(arg1, friendOffline)) then return end
	end

	if db and db.NoLabel then
		panel.text:SetFormattedText(displayString, onlineFriends + numBNetOnline)
	else
		local label = db and db.Label ~= '' and db.Label or FRIENDS
		panel.text:SetFormattedText(displayString, label .. ': ', onlineFriends + numBNetOnline)
	end
end

local function OnClick(_, btn)
	if btn == 'LeftButton' and not E:AlertCombat() then
		ToggleFriendsFrame(not E.Retail and 1 or nil)
	end
end

local function ApplySettings(panel, hex)
	if not db then
		db = E.global.datatexts.settings[panel.name]
	end
	displayString = (db.NoLabel and '' or '%s') .. hex .. '%d|r'
end

DT:RegisterDatatext('TUI Friends', _G.SOCIAL_LABEL, { 'BN_FRIEND_ACCOUNT_ONLINE', 'BN_FRIEND_ACCOUNT_OFFLINE', 'BN_FRIEND_INFO_CHANGED', 'FRIENDLIST_UPDATE', 'CHAT_MSG_SYSTEM', 'PLAYER_ENTERING_WORLD' }, OnEvent, nil, OnClick, OnEnter, OnLeave, 'TUI Friends', nil, ApplySettings)

-- Seed global settings defaults and colorize dropdown entry
local defaults = G.datatexts.settings['TUI Friends']
defaults.Label = ''
defaults.NoLabel = false
defaults.hideMobile = false
defaults.tooltipFont = 'Expressway'
defaults.tooltipFontSize = 11
defaults.tooltipFontOutline = 'OUTLINE'
DT.DataTextList['TUI Friends'] = E:TextGradient('TUI Friends', 1.00,0.18,0.24, 0.80,0.10,0.20)
