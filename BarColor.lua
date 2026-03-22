local _, ns = ...
local LinePointColor = C_CurveUtil.CreateColorCurve() -- 斩杀变色曲线
LinePointColor:SetType(Enum.LuaCurveType.Step)
local slayColorObj = CreateColor(0, 0, 0, 1)
local healthColorObj = CreateColor(0, 0, 0, 1)

-- 血条变色
function ns.UpdateHpbarColor(unitFrame)
    if unitFrame:IsForbidden() or not unitFrame.unit then return end
    if UnitIsPlayer(unitFrame.unit) then return end
    if not unitFrame.healthBar or not unitFrame.healthBar:IsShown() then return end

    if UnitIsTapDenied(unitFrame.unit) then
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(0.5, 0.5, 0.5);
        return
    end

    local DB = PlateColorDB
    local unit = unitFrame.unit
    local Threat = UnitThreatSituation("player", unit) or 0
    local IsTank = UnitGroupRolesAssigned("player") == "TANK" and (DB.TankthreatUse == 2 or DB.TankthreatUse == 3)
    local NoTank = UnitGroupRolesAssigned("player") ~= "TANK" and (DB.threatUse == 2 or DB.threatUse == 3)
    local InCombat = UnitAffectingCombat(unit)

    local hr, hg, hb

    -- 【第一部分：紧急拦截】
    if Threat == 0 and InCombat and IsTank then
        hr, hg, hb = DB.TANKnoThreatColor.r, DB.TANKnoThreatColor.g, DB.TANKnoThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return
    elseif Threat == 1 and IsTank then
        hr, hg, hb = DB.TANKhighThreatColor.r, DB.TANKhighThreatColor.g, DB.TANKhighThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return
    elseif Threat == 2 and IsTank then
        hr, hg, hb = DB.TANKlowThreatColor.r, DB.TANKlowThreatColor.g, DB.TANKlowThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return
    elseif Threat == 1 and NoTank then
        hr, hg, hb = DB.highThreatColor.r, DB.highThreatColor.g, DB.highThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return
    elseif Threat == 2 and NoTank then
        hr, hg, hb = DB.lowThreatColor.r, DB.lowThreatColor.g, DB.lowThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return
    elseif Threat == 3 and NoTank then
        hr, hg, hb = DB.myThreatColor.r, DB.myThreatColor.g, DB.myThreatColor.b
        unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return

    -- 【第二部分：常规底色确定】
    elseif unitFrame.isTarget and DB.myTarget then
        hr, hg, hb = DB.myTargetColor.r, DB.myTargetColor.g, DB.myTargetColor.b
    elseif UnitIsUnit(unit, "focus") and DB.myFocus then
        hr, hg, hb = DB.myFocusColor.r, DB.myFocusColor.g, DB.myFocusColor.b
    else
        local npcColor = (DB.UseNpc == 2 or DB.UseNpc == 3) and ns.NpcLevelColor(unitFrame)
        if npcColor then
            hr, hg, hb = npcColor.r, npcColor.g, npcColor.b
            unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb); return--这里拿到的是秘密值直接染色返回,后面用秘密值做曲线会报错
        else
            local Reaction = not ns.MM(UnitReaction(unit, "player")) and UnitReaction(unit, "player")
            if Reaction and Reaction >= 5 then
                hr, hg, hb = 0, 1, 0
            elseif Threat == 3 and IsTank then
                hr, hg, hb = DB.TANKmyhreatColor.r, DB.TANKmyhreatColor.g, DB.TANKmyhreatColor.b
            elseif Threat == 0 and InCombat and NoTank then
                hr, hg, hb = DB.noThreatColor.r, DB.noThreatColor.g, DB.noThreatColor.b
            elseif Reaction and Reaction == 4 then
                hr, hg, hb = 1, 1, 0
            end
        end
    end

    -- 最终兜底
    if not hr then
        hr, hg, hb = DB.allColor.r, DB.allColor.g, DB.allColor.b
    end
    
    -- 【第三部分：斩杀修正】
    if DB.SlayHp and ns.LinePoint > 0 and ns.SlaylineSpellID and C_SpellBook.IsSpellKnown(ns.SlaylineSpellID) then
        slayColorObj:SetRGBA(DB.SlayHpColor.r, DB.SlayHpColor.g, DB.SlayHpColor.b, 1)
        healthColorObj:SetRGBA(hr, hg, hb, 1)
        LinePointColor:ClearPoints()
        LinePointColor:AddPoint(0, slayColorObj)
        LinePointColor:AddPoint(ns.LinePoint / 100, healthColorObj)
        local color = UnitHealthPercent(unit, true, LinePointColor);
        if color and color:GetRGB() then
            hr, hg, hb = color:GetRGB()
        end
    end

    unitFrame.healthBar:GetStatusBarTexture():SetVertexColor(hr, hg, hb);
end

hooksecurefunc("CompactUnitFrame_UpdateSelectionHighlight", function(frame)
	if not frame.unit then return end
	if string.match(frame.unit,"nameplate") then
		ns.UpdateHpbarColor(frame)
	end
end)
hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
--UNIT_NAME_UPDATE
--UNIT_THREAT_LIST_UPDATE
--UNIT_CONNECTION
	if not frame.unit then return end
	if string.match(frame.unit,"nameplate") then
		ns.UpdateHpbarColor(frame)
	end
end)
hooksecurefunc(NamePlateHealthBarMixin,"UpdateTextStringWithValues", function(self)
	if not PlateColorDB["Slayline"]  then return end
	if ns.LinePoint == 0 then return end
	if self:IsForbidden() then return end
	if not self:GetParent():GetParent().unit then return end
	ns.UpdateHpbarColor(self:GetParent():GetParent())
end)

local function NoFrameUpdateHpBar()
	for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		ns.UpdateHpbarColor(namePlate.UnitFrame)
	end
end
ns.event("PLAYER_FOCUS_CHANGED", function()
	if not PlateColorDB.myFocus then return end
	NoFrameUpdateHpBar()
end)

ns.event("PLAYER_DEAD", NoFrameUpdateHpBar)
ns.event("PLAYER_ALIVE", NoFrameUpdateHpBar)

