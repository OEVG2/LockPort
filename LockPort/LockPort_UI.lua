--[[
	LockPort UI - built from the stock 1.12 Blizzard art so it looks like part of the game:
	dialog border + header plate, gold GameFont text, class icons from the character
	creation sheet, UIPanelButtons, UICheckButtons and an InputBox.
]]

local LP = LockPort

local MAX_ROWS   = 10
local ROW_HEIGHT = 18
local FRAME_W    = 260
local INNER_W    = FRAME_W - 36

local CLASS_ICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
local CLASS_COORDS = {
	WARRIOR = { 0, 0.25, 0, 0.25 },          MAGE    = { 0.25, 0.49609375, 0, 0.25 },
	ROGUE   = { 0.49609375, 0.7421875, 0, 0.25 }, DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
	HUNTER  = { 0, 0.25, 0.25, 0.5 },        SHAMAN  = { 0.25, 0.49609375, 0.25, 0.5 },
	PRIEST  = { 0.49609375, 0.7421875, 0.25, 0.5 }, WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
	PALADIN = { 0, 0.25, 0.5, 0.75 },
}

local DIALOG_BACKDROP = {
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local function ClassColor(class)
	local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
	if c then return c.r, c.g, c.b end
	return 1, 0.82, 0
end

local function MakeDialog(name, width, height, title)
	local f = CreateFrame("Frame", name, UIParent)
	f:SetWidth(width)
	f:SetHeight(height)
	f:SetFrameStrata("MEDIUM")
	if f.SetToplevel then f:SetToplevel(true) end
	f:SetBackdrop(DIALOG_BACKDROP)
	f:SetMovable(true)
	f:EnableMouse(true)
	if f.SetClampedToScreen then f:SetClampedToScreen(true) end
	f:RegisterForDrag("LeftButton")
	f:Hide()

	local header = f:CreateTexture(name .. "Header", "ARTWORK")
	header:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
	header:SetWidth(width > 280 and 300 or 230)
	header:SetHeight(64)
	header:SetPoint("TOP", f, "TOP", 0, 12)

	local text = f:CreateFontString(name .. "Title", "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", header, "TOP", 0, -14)
	text:SetText(title)
	f.title = text

	local close = CreateFrame("Button", name .. "CloseButton", f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)
	return f
end

---------------------------------------------------------------------------
-- Request window
---------------------------------------------------------------------------
local function Row_OnEnter()
	local e = this.entry
	if not e then return end
	local info = e.info
	GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
	GameTooltip:AddLine(e.name, ClassColor(info.class))
	local line = info.classLocal or ""
	if info.zone and info.zone ~= "" then line = line .. "  -  " .. info.zone end
	if line ~= "" then GameTooltip:AddLine(line, 1, 1, 1) end
	local status, r, g, b = LP:RequestStatus(e)
	if status ~= "" then GameTooltip:AddLine(status, r, g, b) end
	local waited = math.floor((GetTime() - e.t) / 60)
	GameTooltip:AddLine("Waiting " .. (waited < 1 and "under a minute" or (waited .. " min")), 0.6, 0.6, 0.6)
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Left-click: summon", 0.2, 1, 0.2)
	GameTooltip:AddLine("Ctrl+click: target", 0.8, 0.8, 0.8)
	GameTooltip:AddLine("Right-click: remove", 1, 0.3, 0.3)
	GameTooltip:Show()
end

local function Row_OnClick()
	local e = this.entry
	if not e then return end
	if arg1 == "RightButton" then
		LP:RemoveRequest(e.name, true)
	elseif IsControlKeyDown() then
		TargetUnit(e.info.unit)
	else
		LP:Summon(e.name)
	end
	GameTooltip:Hide()
end

local function CreateRow(parent, i)
	local row = CreateFrame("Button", "LockPortRow" .. i, parent)
	row:SetWidth(INNER_W)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", parent, "TOPLEFT", 18, -46 - (i - 1) * ROW_HEIGHT)
	row:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	if math.mod(i, 2) == 0 then
		local stripe = row:CreateTexture(nil, "BACKGROUND")
		stripe:SetAllPoints(row)
		stripe:SetTexture(1, 1, 1, 0.05)
	end

	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	hl:SetBlendMode("ADD")
	hl:SetAllPoints(row)

	local icon = row:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(CLASS_ICONS)
	icon:SetWidth(14)
	icon:SetHeight(14)
	icon:SetPoint("LEFT", row, "LEFT", 3, 0)
	row.icon = icon

	local name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	name:SetPoint("LEFT", icon, "RIGHT", 5, 0)
	name:SetWidth(110)
	name:SetHeight(ROW_HEIGHT)
	name:SetJustifyH("LEFT")
	row.name = name

	local status = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	status:SetPoint("RIGHT", row, "RIGHT", -3, 0)
	status:SetWidth(INNER_W - 140)
	status:SetHeight(ROW_HEIGHT)
	status:SetJustifyH("RIGHT")
	row.status = status

	row:SetScript("OnClick", Row_OnClick)
	row:SetScript("OnEnter", Row_OnEnter)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row:Hide()
	return row
end

local function SavePosition(f)
	local point, _, relPoint, x, y = f:GetPoint()
	LockPortOptions.pos = { point = point, relPoint = relPoint, x = x, y = y }
end

local function RestorePosition(f)
	f:ClearAllPoints()
	local p = LockPortOptions.pos
	if p and p.point then
		f:SetPoint(p.point, UIParent, p.relPoint or p.point, p.x or 0, p.y or 0)
	else
		f:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
	end
end

local function CreateMainFrame()
	local f = MakeDialog("LockPortFrame", FRAME_W, 200, "LockPort")
	f:SetScript("OnDragStart", function() if not LockPortOptions.locked then this:StartMoving() end end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing(); SavePosition(this) end)
	f:SetScript("OnShow", function() PlaySound("igMainMenuOpen"); LP:RefreshList() end)
	f:SetScript("OnHide", function() PlaySound("igMainMenuClose") end)
	f:SetScript("OnUpdate", function()
		this.elapsed = (this.elapsed or 0) + arg1
		if this.elapsed > 0.5 then this.elapsed = 0; LP:RefreshList() end
	end)

	local sub = f:CreateFontString("LockPortFrameSubtitle", "OVERLAY", "GameFontNormalSmall")
	sub:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -28)
	sub:SetText("Summon requests")
	f.subtitle = sub

	local count = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	count:SetPoint("TOPRIGHT", f, "TOPRIGHT", -20, -28)
	f.count = count

	local div = f:CreateTexture(nil, "ARTWORK")
	div:SetTexture(1, 0.82, 0, 0.25)
	div:SetHeight(1)
	div:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -42)
	div:SetPoint("TOPRIGHT", f, "TOPRIGHT", -18, -42)

	f.rows = {}
	for i = 1, MAX_ROWS do f.rows[i] = CreateRow(f, i) end

	local empty = f:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	empty:SetPoint("TOP", f, "TOP", 0, -52)
	empty:SetText("No one needs a summon.")
	f.empty = empty

	local more = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	more:SetPoint("TOPRIGHT", f.rows[MAX_ROWS], "BOTTOMRIGHT", -3, -1)
	f.more = more

	-- footer: shards + helpers
	local footer = CreateFrame("Frame", nil, f)
	footer:SetWidth(INNER_W)
	footer:SetHeight(20)
	footer:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 42)
	f.footer = footer

	local fdiv = footer:CreateTexture(nil, "ARTWORK")
	fdiv:SetTexture(1, 0.82, 0, 0.25)
	fdiv:SetHeight(1)
	fdiv:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 2)
	fdiv:SetPoint("TOPRIGHT", footer, "TOPRIGHT", 0, 2)

	local shardIcon = footer:CreateTexture(nil, "ARTWORK")
	shardIcon:SetTexture("Interface\\Icons\\INV_Misc_Gem_Amethyst_02")
	shardIcon:SetWidth(16)
	shardIcon:SetHeight(16)
	shardIcon:SetPoint("LEFT", footer, "LEFT", 2, -3)

	local shards = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	shards:SetPoint("LEFT", shardIcon, "RIGHT", 4, 0)
	f.shards = shards

	local helpers = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	helpers:SetPoint("RIGHT", footer, "RIGHT", -2, -3)
	f.helpers = helpers

	-- buttons
	local summon = CreateFrame("Button", "LockPortSummonButton", f, "UIPanelButtonTemplate")
	summon:SetWidth(80)
	summon:SetHeight(22)
	summon:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 16, 16)
	summon:SetText("Summon")
	summon:SetScript("OnClick", function() LP:SummonNext() end)
	summon:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_TOP")
		GameTooltip:AddLine("Summon next in line")
		GameTooltip:AddLine("Skips anyone offline, dead or in combat.", 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	summon:SetScript("OnLeave", function() GameTooltip:Hide() end)
	f.summon = summon

	local add = CreateFrame("Button", "LockPortAddButton", f, "UIPanelButtonTemplate")
	add:SetWidth(76)
	add:SetHeight(22)
	add:SetPoint("LEFT", summon, "RIGHT", 2, 0)
	add:SetText("Add Target")
	add:SetScript("OnClick", function() LP:Slash("add") end)

	local opts = CreateFrame("Button", "LockPortOptionsButton", f, "UIPanelButtonTemplate")
	opts:SetWidth(70)
	opts:SetHeight(22)
	opts:SetPoint("LEFT", add, "RIGHT", 2, 0)
	opts:SetText("Options")
	opts:SetScript("OnClick", function() LP:ToggleOptions() end)

	RestorePosition(f)
	return f
end

function LP:RefreshList()
	local f = LockPortFrame
	if not f or not LockPortOptions then return end
	if not self:IsWarlock() then f:Hide(); return end
	if not f:IsVisible() then return end

	self:ScanRoster()
	local list = self:SortedRequests()
	local n = table.getn(list)
	local shown = n
	if shown > MAX_ROWS then shown = MAX_ROWS end

	for i = 1, MAX_ROWS do
		local row, e = f.rows[i], list[i]
		if e then
			row.entry = e
			local c = CLASS_COORDS[e.info.class or ""]
			if c then
				row.icon:SetTexCoord(c[1], c[2], c[3], c[4])
				row.icon:Show()
			else
				row.icon:Hide()
			end
			row.name:SetText(e.name)
			row.name:SetTextColor(ClassColor(e.info.class))
			local text, r, g, b = self:RequestStatus(e)
			row.status:SetText(text)
			row.status:SetTextColor(r, g, b)
			row:Show()
		else
			row.entry = nil
			row:Hide()
		end
	end

	if n == 0 then f.empty:Show() else f.empty:Hide() end
	if n > MAX_ROWS then f.more:SetText("+" .. (n - MAX_ROWS) .. " more") else f.more:SetText("") end
	f.count:SetText(n == 1 and "1 waiting" or (n .. " waiting"))

	local shardCount = self:CountShards()
	f.shards:SetText(shardCount .. (shardCount == 1 and " Soul Shard" or " Soul Shards"))
	if shardCount == 0 then f.shards:SetTextColor(1, 0.25, 0.25) else f.shards:SetTextColor(1, 1, 1) end

	local helpers = self:InGroup() and self:CountHelpers(nil) or 0
	f.helpers:SetText("Helpers nearby: " .. helpers)
	if helpers >= 2 then f.helpers:SetTextColor(0.25, 1, 0.25) else f.helpers:SetTextColor(1, 0.5, 0.1) end

	if self.pending and not self.pending.done then f.summon:Disable() else f.summon:Enable() end

	local rows = shown
	if rows < 1 then rows = 1 end
	local extra = (n > MAX_ROWS) and 12 or 0
	f:SetHeight(46 + rows * ROW_HEIGHT + extra + 72)
end

---------------------------------------------------------------------------
-- Options window
---------------------------------------------------------------------------
local checks = {}

local function MakeCheck(parent, key, label, tip, x, y)
	local name = "LockPortCheck_" .. key
	local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
	cb:SetWidth(24)
	cb:SetHeight(24)
	cb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	local text = getglobal(name .. "Text")
	if not text then
		text = cb:CreateFontString(name .. "Text", "OVERLAY")
		text:SetPoint("LEFT", cb, "RIGHT", 0, 1)
	end
	text:SetFontObject(GameFontHighlightSmall)
	text:SetText(label)
	cb.label = text
	cb.key = key
	cb.tip = tip
	cb:SetScript("OnClick", function()
		LockPortOptions[this.key] = this:GetChecked() and true or false
		PlaySound(this:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
		LP:RefreshList()
	end)
	cb:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:AddLine(this.label:GetText())
		GameTooltip:AddLine(this.tip, 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
	checks[key] = cb
	return cb
end

local function MakeSection(parent, text, y)
	local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	fs:SetPoint("TOPLEFT", parent, "TOPLEFT", 20, y)
	fs:SetText(text)
	return fs
end

local function MakeInput(parent, name, key, width, x, y)
	local eb = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
	eb:SetWidth(width)
	eb:SetHeight(20)
	eb:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
	eb:SetAutoFocus(false)
	eb:SetMaxLetters(255)
	eb.key = key
	eb:SetScript("OnEditFocusGained", function() this.focused = true end)
	eb:SetScript("OnEditFocusLost", function() this.focused = nil end)
	eb:SetScript("OnEnterPressed", function() this:ClearFocus() end)
	eb:SetScript("OnEscapePressed", function() this:ClearFocus() end)
	eb:SetScript("OnTextChanged", function()
		if LockPortOptions then LockPortOptions[this.key] = this:GetText() end
	end)
	return eb
end

local function CreateOptionsFrame()
	local f = MakeDialog("LockPortOptionsFrame", 340, 470, "LockPort Options")
	f:SetFrameStrata("DIALOG")
	f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	f:SetScript("OnDragStart", function() this:StartMoving() end)
	f:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
	f:SetScript("OnShow", function() PlaySound("igCharacterInfoOpen"); LP:RefreshOptionsUI() end)
	f:SetScript("OnHide", function() PlaySound("igCharacterInfoClose") end)
	table.insert(UISpecialFrames, "LockPortOptionsFrame")   -- Esc closes it

	local y = -32
	MakeSection(f, "When summoning", y)
	MakeCheck(f, "whisper", "Whisper the player you're summoning", "Sends \"Summoning you to <zone>\" to the target when the ritual starts.", 20, y - 16)
	MakeCheck(f, "zone", "Include zone in the /say message", "Adds the zone and subzone to the summon announcement.", 20, y - 38)
	MakeCheck(f, "shards", "Include Soul Shard count", "Adds \"[N shards left]\" to the summon announcement.", 20, y - 60)
	MakeCheck(f, "customMessage", "Use a custom /say message:", "Replaces the generated message. {name}, {zone} and {shards} are filled in for you.", 20, y - 82)
	local msg = MakeInput(f, "LockPortMessageBox", "message", 280, 30, y - 106)
	local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	hint:SetPoint("TOPLEFT", msg, "BOTTOMLEFT", -4, -2)
	hint:SetText("Tokens: {name}  {zone}  {shards}")

	y = -170
	MakeSection(f, "When a summon fails", y)
	MakeCheck(f, "announceFail", "Tell the party/raid why", "e.g. \"[LockPort] Can't summon Bob: Bob is in combat.\"", 20, y - 16)
	MakeCheck(f, "whisperFail", "Whisper the player the reason", "Lets them know they're still on the list and what to fix.", 20, y - 38)

	y = -240
	MakeSection(f, "Requests", y)
	MakeCheck(f, "sound", "Play a sound on new requests", "Plays a short sound when someone is added to the list.", 20, y - 16)
	local flash = MakeCheck(f, "flash", "Flash the taskbar when alt-tabbed", "Needs the UnitXP SP3 client mod.", 20, y - 38)
	MakeCheck(f, "autoShow", "Open this window on new requests", "Pops the LockPort window up when someone asks for a summon.", 20, y - 60)
	MakeCheck(f, "autoRemove", "Remove players once they arrive", "Takes people off everyone's list when they're already standing near you.", 20, y - 82)
	MakeCheck(f, "locked", "Lock window position", "Stops the summon window from being dragged.", 20, y - 104)

	local trigLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	trigLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, y - 136)
	trigLabel:SetText("Request words:")
	local trig = MakeInput(f, "LockPortTriggerBox", "triggers", 170, 124, y - 131)
	trig:SetScript("OnEnter", function()
		GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Request words")
		GameTooltip:AddLine("Comma separated. A group member starting a message with one of these is added to the list. Default: 123", 1, 1, 1, 1)
		GameTooltip:Show()
	end)
	trig:SetScript("OnLeave", function() GameTooltip:Hide() end)

	local modsHeader = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	modsHeader:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 22, 40)
	modsHeader:SetText("Client mods")
	local mods = f:CreateFontString("LockPortModsText", "OVERLAY", "GameFontHighlightSmall")
	mods:SetPoint("TOPLEFT", modsHeader, "BOTTOMLEFT", 0, -4)
	mods:SetWidth(300)
	mods:SetJustifyH("LEFT")
	f.mods = mods

	local okay = CreateFrame("Button", "LockPortOptionsOkay", f, "UIPanelButtonTemplate")
	okay:SetWidth(80)
	okay:SetHeight(22)
	okay:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -16, 14)
	okay:SetText(OKAY or "Okay")
	okay:SetScript("OnClick", function() LockPortOptionsFrame:Hide() end)

	f.flash = flash
	return f
end

function LP:RefreshOptionsUI()
	local O = LockPortOptions
	local f = LockPortOptionsFrame
	if not O or not f then return end
	for key, cb in pairs(checks) do cb:SetChecked(O[key] and 1 or nil) end
	if not LockPortMessageBox.focused then LockPortMessageBox:SetText(O.message or "") end
	if not LockPortTriggerBox.focused then LockPortTriggerBox:SetText(O.triggers or "123") end
	if self.mods.unitxp then
		f.flash:Enable()
		f.flash.label:SetTextColor(1, 1, 1)
	else
		f.flash:Disable()
		f.flash.label:SetTextColor(0.5, 0.5, 0.5)
	end
	f.mods:SetText(self:ModStatusText())
end

function LP:CreateUI()
	if LockPortFrame then return end
	CreateMainFrame()
	CreateOptionsFrame()
end
