----------------------------------------------------
-- Interrupt Bar by Kollektiv
----------------------------------------------------

InterruptBarByScDB = InterruptBarByScDB or { scale = 1, hidden = false, lock = false, itemPerLine = 4}
local abilities = {}
local order
local band = bit.band
local fontSize = 22

local spellids = {[6552] = 10, [2139] = 24, [19647] = 24, [1766] = 10, [47528] = 10, [47476] = 120, [80965] = 10, [96231] = 10, [15487] = 45, [64044] = 120, [57994] = 5, [34490] = 20, [60192] = 30, [19503] = 30}
for spellid,time in pairs(spellids) do
	local name,_,spellicon = GetSpellInfo(spellid)	
	abilities[name] = { icon = spellicon, duration = time }
end

-----------------------------------------------------
-- Edit this table to change the order
-----------------------------------------------------
-- 6552  Pummel
-- 2139  Counterspell
-- 19647 Spell Lock
-- 1766  Kick
-- 47528 Mind Freeze
-- 96231 Rebuke
-- 80965 Skull Bash (cat)
-- 80964 Skull Bash (bear)

-- new --
-- 47476 Strangulate
-- 15487 Silence
-- 57994 Wind Shear
-- 64044 horror
-- 34490 Silencing Shot
-- 60192 Freezing Trap
-- 19503 Scatter Shot
-----------------------------------------------------

local order = {6552, 1766 ,80965, 96231, 47528, 57994, 47476, 2139, 19647,15487 ,64044, 34490, 60192, 19503 }

-----------------------------------------------------
-----------------------------------------------------

for k,v in ipairs(order) do order[k] = GetSpellInfo(v) end

local frame
local bar

local GetTime = GetTime
local ipairs = ipairs
local pairs = pairs
local select = select
local floor = floor
local band = bit.band
local GetSpellInfo = GetSpellInfo

local GROUP_UNITS = bit.bor(0x00000010, 0x00000400)

local activetimers = {}

local size = 0
local function getsize()
	size = 0
	for k in pairs(activetimers) do
		size = size + 1
	end
end

local function InterruptBar_AddIcons()
	local x = -45
	local lineCounter = 0
	
	for index,ability in ipairs(order) do
		if lineCounter+1 > InterruptBarByScDB.itemPerLine then
		lineCounter = 0
		x = -45
		end
		
		local level = floor( (index-1) / InterruptBarByScDB.itemPerLine)
		
		local btn = CreateFrame("Frame",nil,bar)
		btn:SetWidth(30)
		btn:SetHeight(30)
		
		btn:SetPoint("CENTER",bar,"CENTER",x,level*-30)
		btn:SetFrameStrata("LOW")
		
		local cd = CreateFrame("Cooldown",nil,btn)
		cd.noomnicc = true
		cd.noCooldownCount = true
		cd:SetAllPoints(true)
		cd:SetFrameStrata("MEDIUM")
		cd:Hide()
		
		local texture = btn:CreateTexture(nil,"BACKGROUND")
		texture:SetAllPoints(true)
		texture:SetTexture(abilities[ability].icon)
		texture:SetTexCoord(0.07,0.9,0.07,0.90)
	
		local text = cd:CreateFontString(nil,"ARTWORK")
		text:SetFont(STANDARD_TEXT_FONT,fontSize,"OUTLINE")
		text:SetTextColor(1,1,0,1)
		text:SetPoint("LEFT",btn,"LEFT",0,0)
		
		btn.texture = texture
		btn.text = text
		btn.duration = abilities[ability].duration
		btn.cd = cd
		
		bar[ability] = btn
		
		x = x + 30
		lineCounter = lineCounter + 1
	end
end

local function InterruptBar_SavePosition()
	local point, _, relativePoint, xOfs, yOfs = bar:GetPoint()
	if not InterruptBarByScDB.Position then 
		InterruptBarByScDB.Position = {}
	end
	InterruptBarByScDB.Position.point = point
	InterruptBarByScDB.Position.relativePoint = relativePoint
	InterruptBarByScDB.Position.xOfs = xOfs
	InterruptBarByScDB.Position.yOfs = yOfs
end

local function InterruptBar_LoadPosition()
	if InterruptBarByScDB.Position then
		bar:SetPoint(InterruptBarByScDB.Position.point,UIParent,InterruptBarByScDB.Position.relativePoint,InterruptBarByScDB.Position.xOfs,InterruptBarByScDB.Position.yOfs)
	else
		bar:SetPoint("CENTER", UIParent, "CENTER")
	end
end

local function InterruptBar_UpdateBar()
	bar:SetScale(InterruptBarByScDB.scale)
	if InterruptBarByScDB.hidden then
		for _,v in ipairs(order) do bar[v]:Hide() end
	else
		for _,v in ipairs(order) do bar[v]:Show() end
	end
	if InterruptBarByScDB.lock then
		bar:EnableMouse(false)
	else
		bar:EnableMouse(true)
	end
end

local function InterruptBar_UpdateItemsPerLine()
	InterruptBar_AddIcons()
	ChatFrame1:AddMessage("Interruptbar - remember to reload the UI after changing the number of items per line",255,0,0) 
end

local function InterruptBar_CreateBar()
	bar = CreateFrame("Frame", nil, UIParent)
	bar:SetMovable(true)
	bar:SetWidth(120)
	bar:SetHeight(30)
	bar:SetClampedToScreen(true) 
	bar:SetScript("OnMouseDown",function(self,button) if button == "LeftButton" then self:StartMoving() end end)
	bar:SetScript("OnMouseUp",function(self,button) if button == "LeftButton" then self:StopMovingOrSizing() InterruptBar_SavePosition() end end)
	bar:Show()
	
	InterruptBar_AddIcons()
	InterruptBar_UpdateBar()
	InterruptBar_LoadPosition()
end

local function InterruptBar_UpdateText(text,cooldown)
	if cooldown > 99 then
		text:SetTextColor(1,1,0,0.7) 
		text:SetFont(STANDARD_TEXT_FONT,fontSize-6,"OUTLINE")
		text:SetFormattedText(" %s", "ON")
	else
		text:SetFont(STANDARD_TEXT_FONT,fontSize,"OUTLINE")
		if cooldown < 10 then 
			if cooldown <= 0.5 then
				text:SetText("")
			else
				text:SetFormattedText(" %d",cooldown)
			end
		else
			text:SetFormattedText("%d",cooldown)
		end
	
		if cooldown < 6 then 
			text:SetTextColor(1,0,0,1)
		else 
			text:SetTextColor(1,1,0,1) 
		end
	end
	
end

local function InterruptBar_StopAbility(ref,ability)
	if InterruptBarByScDB.hidden then ref:Hide() end
	if activetimers[ability] then activetimers[ability] = nil end
	ref.text:SetText("")
	ref.cd:Hide()
end

local time = 0
local function InterruptBar_OnUpdate(self, elapsed)
	time = time + elapsed
	if time > 0.25 then
		getsize()
		for ability,ref in pairs(activetimers) do
			ref.cooldown = ref.start + ref.duration - GetTime()
			if ref.cooldown <= 0 then
				InterruptBar_StopAbility(ref,ability)
			else 
				InterruptBar_UpdateText(ref.text,floor(ref.cooldown+0.5))
			end
		end
		if size == 0 then frame:SetScript("OnUpdate",nil) end
		time = time - 0.25
	end
end

local function InterruptBar_StartTimer(ref,ability)
	if InterruptBarByScDB.hidden then
		ref:Show()
	end
	if not activetimers[ability] then
		local duration
		activetimers[ability] = ref
		ref.cd:Show()
		ref.cd:SetCooldown(GetTime()-0.40,ref.duration)
		ref.start = GetTime()
		InterruptBar_UpdateText(ref.text,ref.duration)
	end
	frame:SetScript("OnUpdate",InterruptBar_OnUpdate)
end

local function InterruptBar_COMBAT_LOG_EVENT_UNFILTERED(...)
	local spellID, ability, useSecondDuration
	return function(_, eventtype, _, _, srcName, srcFlags, _, _, dstName, dstFlags, _, id)
		if (band(srcFlags, 0x00000040) == 0x00000040 and eventtype == "SPELL_CAST_SUCCESS") then 
			spellID = id
		else
			return
		end
		useSecondDuration = false
		if spellID == 49376 then spellID = 16979; useSecondDuration = true end -- Feral Charge - Cat -> Feral Charge - Bear
		if spellID  == 1499 then spellID = 60192; end -- Freezing trap -> Freezing trap Launcher
		if spellID  == 13809 then spellID = 60192; end -- Ice trap -> Freezing trap Launcher
		if spellID  == 82941 then spellID = 60192; end -- Ice trap Launcher -> Freezing trap Launcher
		ability = GetSpellInfo(spellID)
		if abilities[ability] then			
			if useSecondDuration and spellID == 16979 then
				bar[ability].duration = 30
			elseif spellID == 16979 then
				bar[ability].duration = 15
			end
			InterruptBar_StartTimer(bar[ability],ability)
		end
	end
end

InterruptBar_COMBAT_LOG_EVENT_UNFILTERED = InterruptBar_COMBAT_LOG_EVENT_UNFILTERED()

local function InterruptBar_ResetAllTimers()
	for _,ability in ipairs(order) do
		InterruptBar_StopAbility(bar[ability])
	end
	active = 0
end

local function InterruptBar_PLAYER_ENTERING_WORLD(self)
	InterruptBar_ResetAllTimers()
end

local function InterruptBar_Reset()
	InterruptBarByScDB = { scale = 1, hidden = false, lock = false, itemPerLine = 4}
	InterruptBar_UpdateBar()
	InterruptBar_LoadPosition()
end

local function InterruptBar_Test()
	for _,ability in ipairs(order) do
		InterruptBar_StartTimer(bar[ability],ability)
	end
end

local cmdfuncs = {
	scale = function(v) InterruptBarByScDB.scale = v; InterruptBar_UpdateBar() end,
	hidden = function() InterruptBarByScDB.hidden = not InterruptBarByScDB.hidden; InterruptBar_UpdateBar() end,
	itemPerLine = function(v)  InterruptBarByScDB.itemPerLine = v; InterruptBar_UpdateItemsPerLine() end,
	lock = function() InterruptBarByScDB.lock = not InterruptBarByScDB.lock; InterruptBar_UpdateBar() end,
	reset = function() InterruptBar_Reset() end,
	test = function() InterruptBar_Test() end,
}

local cmdtbl = {}
function InterruptBar_Command(cmd)
	for k in ipairs(cmdtbl) do
		cmdtbl[k] = nil
	end
	for v in gmatch(cmd, "[^ ]+") do
  	tinsert(cmdtbl, v)
  end
  local cb = cmdfuncs[cmdtbl[1]] 
  if cb then
  	local s = tonumber(cmdtbl[2])
  	cb(s)
  else
  	ChatFrame1:AddMessage("InterruptBar Options | /ibsc <option>",255,0,0) 
  	ChatFrame1:AddMessage("-- scale <number> | value: " .. InterruptBarByScDB.scale,255,255,255)
	ChatFrame1:AddMessage("-- itemPerLine <integer> | value: " .. InterruptBarByScDB.itemPerLine,255,255,255)
  	ChatFrame1:AddMessage("-- hidden (toggle) | value: " .. tostring(InterruptBarByScDB.hidden),255,255,255)
  	ChatFrame1:AddMessage("-- lock (toggle) | value: " .. tostring(InterruptBarByScDB.lock),255,255,255)
  	ChatFrame1:AddMessage("-- test (execute)",255,255,255)
  	ChatFrame1:AddMessage("-- reset (execute)",255,255,255)
  end
end

local function InterruptBar_OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	if not InterruptBarByScDB.scale then InterruptBarByScDB.scale = 1 end
	if not InterruptBarByScDB.hidden then InterruptBarByScDB.hidden = false end
	if not InterruptBarByScDB.lock then InterruptBarByScDB.lock = false end
	InterruptBar_CreateBar()
	
	SlashCmdList["InterruptBarBySc"] = InterruptBar_Command
	SLASH_InterruptBarBySc1 = "/ibsc"
	
	ChatFrame1:AddMessage("Interrupt Bar by Kollektiv modified By Satanic Crow. Type /ibsc for options.",255,0,0)
end

local eventhandler = {
	["VARIABLES_LOADED"] = function(self) InterruptBar_OnLoad(self) end,
	["PLAYER_ENTERING_WORLD"] = function(self) InterruptBar_PLAYER_ENTERING_WORLD(self) end,
	["COMBAT_LOG_EVENT_UNFILTERED"] = function(self,...) InterruptBar_COMBAT_LOG_EVENT_UNFILTERED(...) end,
}

local function InterruptBar_OnEvent(self,event,...)
	eventhandler[event](self,...)
end

frame = CreateFrame("Frame",nil,UIParent)
frame:SetScript("OnEvent",InterruptBar_OnEvent)
frame:RegisterEvent("VARIABLES_LOADED")
