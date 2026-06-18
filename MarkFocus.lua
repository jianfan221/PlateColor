local _, ns = ...

--设置焦点

local modKey = {[1]="shift", [2]="ctrl", [3]="alt"}
local function GetFocusMacroText()
	local advance = "~"
	local icon = PlateColorDB.setFocusIcon
	local markmacro = "\n/tm [@mouseover]"..advance..icon

	return modKey[PlateColorDB.setFocusMod], "/focus [@mouseover]"..markmacro
end

function ns.SetFocus()
	if InCombatLockdown() then return end
	
	if PlateColorDB.setFocusMod == 0 then
		if ShiftFocuserButton then
			ClearOverrideBindings(ShiftFocuserButton)
		end
		return
	end

	if not ShiftFocuserButton then
		ShiftFocuserButton = CreateFrame("CheckButton", "ShiftFocuserButton", UIParent, "SecureActionButtonTemplate")
		ShiftFocuserButton:RegisterForClicks("AnyDown", "AnyUp")
		ShiftFocuserButton:SetAttribute("type", "macro")
	end
	
	if ShiftFocuserButton then
		--先清除旧绑定
		ClearOverrideBindings(ShiftFocuserButton)
		
		local modifier, macrotext = GetFocusMacroText()
		ShiftFocuserButton:SetAttribute("macrotext1", macrotext)
		SetOverrideBindingClick(ShiftFocuserButton, true, modifier.."-BUTTON1", "ShiftFocuserButton")
	end
end

local function SetFocusHotkey(frame)
	if not frame then return end
	if not frame.SetAttribute then return end
	if InCombatLockdown() then return end
	if PlateColorDB.setFocusMod == 0 then
		if ShiftFocuserButton then
			ClearOverrideBindings(ShiftFocuserButton)
		end
		return
	end
	
	local modifier, macrotext = GetFocusMacroText()
	
	--清除旧的属性
	frame:SetAttribute("shift-type1", nil)
	frame:SetAttribute("shift-macrotext1", nil)
	frame:SetAttribute("ctrl-type1", nil)
	frame:SetAttribute("ctrl-macrotext1", nil)
	frame:SetAttribute("alt-type1", nil)
	frame:SetAttribute("alt-macrotext1", nil)
	
	frame:SetAttribute(modifier.."-type1", "macro")
	frame:SetAttribute(modifier.."-macrotext1", macrotext)
end

local duf = {
	PetFrame,
	PlayerFrame,
	PartyMemberFrame1,
	PartyMemberFrame2,
	PartyMemberFrame3,
	PartyMemberFrame4,
	PartyMemberFrame1PetFrame,
	PartyMemberFrame2PetFrame,
	PartyMemberFrame3PetFrame,
	PartyMemberFrame4PetFrame,
	PartyMemberFrame1TargetFrame,
	PartyMemberFrame2TargetFrame,
	PartyMemberFrame3TargetFrame,
	PartyMemberFrame4TargetFrame,
	TargetFrame,
	TargetFrameToT,
	TargetFrameToTTargetFrame,
	Boss1TargetFrame,
	Boss2TargetFrame,
	Boss3TargetFrame,
	Boss4TargetFrame,
	Boss5TargetFrame,
	ArenaEnemyFrame1,
	ArenaEnemyFrame2,
	ArenaEnemyFrame3,
	ArenaPrepFrame1,
	ArenaPrepFrame2,
	ArenaPrepFrame3,
	ArenaFrame1,
	ArenaFrame2,
	ArenaFrame3,
	EQOLUFPlayeerFrame,
	EQOLUFTargetFrame,
	EQOLUFToTFrame,
	EQOLUFFocusFrame,
	EQOLUFBoss1Frame,
	EQOLUFBoss2Frame,
	EQOLUFBoss3Frame,
	EQOLUFBoss4Frame,
	EQOLUFBoss5Frame,
}

ns.hook("CompactUnitFrame_UpdateName", function(frame)
	if InCombatLockdown() then return end
	if frame and frame.unit and string.match(frame.unit,"nameplate")  then
		SetFocusHotkey(frame)
	end
end)

function ns.PCSetFocus()
	ns.SetFocus()
	for i, frame in pairs(duf) do
		if frame then
			SetFocusHotkey(frame)
		end
	end
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		if namePlate.UnitFrame then
			SetFocusHotkey(namePlate.UnitFrame)
		end
	end
end

ns.event("PLAYER_ENTERING_WORLD", function(event)
	ns.PCSetFocus()
end)

ns.event("READY_CHECK", function(event)
	if C_Secrets.ShouldAurasBeSecret() then return end
	if not PlateColorDB.sendFocusIcon then return end
	if PlateColorDB.setFocusIcon == 0 then return end
	local inInstance, instanceType = IsInInstance()
	if inInstance and instanceType == "party" then
		C_ChatInfo.SendChatMessage(ns.L["我的焦点标记是"].." {rt"..PlateColorDB.setFocusIcon.."}", "PARTY")
	end
end)