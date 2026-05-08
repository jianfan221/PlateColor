local _, ns = ...

local function SetCooldownText(self)
    local success, region = pcall(function() 
        return self.Cooldown:GetRegions()
    end)
    if success and region then
        if type(region.SetFont) == "function" then
            region:SetFont(STANDARD_TEXT_FONT, self:GetHeight()/1.5 * PlateColorDB.auraText1, "OUTLINE")
        end
    end
end
hooksecurefunc(NamePlateAuraItemMixin,"OnLoad",SetCooldownText)

--驱散颜色
local discolor = C_CurveUtil.CreateColorCurve()
discolor:SetType(Enum.LuaCurveType.Step)
discolor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
discolor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
discolor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
discolor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
discolor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
discolor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒
hooksecurefunc(NamePlateAuraItemMixin, "SetAura", function(self,aura)
    if self and not self:IsForbidden() then
        self:EnableMouse(not PlateColorDB.hideAuraTooltip)
    end

    if self and not self:IsForbidden() and self.unitToken then
        if not self.Stealable then
            self.Stealable = self:CreateTexture(nil, "OVERLAY")
            self.Stealable:SetPoint("TOPLEFT", self, "TOPLEFT", -5, 5)
            self.Stealable:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 5, -5)
            self.Stealable:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
            self.Stealable:SetBlendMode("ADD")
        end
        self.Stealable:Hide()
        local color = C_UnitAuras.GetAuraDispelTypeColor(self.unitToken, aura.auraInstanceID, discolor)
        if color and UnitCanAttack("player", self.unitToken) then
            self.Stealable:SetVertexColor(color:GetRGB())
            self.Stealable:SetAlphaFromBoolean(self.isBuff,255,0)
            self.Stealable:Show()
        end
    end
end)

function ns.CrowdControlListFrameScale(unitFrame)
    unitFrame.AurasFrame.DebuffListFrame:SetScale(PlateColorDB.auraTopScale)
    if unitFrame.AurasFrame.BuffListFrame then--左侧光环
        unitFrame.AurasFrame.BuffListFrame:SetScale(PlateColorDB.auraLScale)
        unitFrame.AurasFrame.BuffListFrame:ClearAllPoints()
        local anchor = unitFrame.healthBar
        if unitFrame.ArrowLeft then
            anchor = unitFrame.ArrowLeft
        end
        unitFrame.AurasFrame.BuffListFrame:SetPoint("RIGHT", anchor, "LEFT", -5, 0)
    end
    if unitFrame.AurasFrame.CrowdControlListFrame then--敌方NPC右侧控制光环
        unitFrame.AurasFrame.CrowdControlListFrame:SetScale(PlateColorDB.auraRScale)
        unitFrame.AurasFrame.CrowdControlListFrame:ClearAllPoints()
        unitFrame.AurasFrame.CrowdControlListFrame:SetPoint("LEFT", unitFrame.healthBar, "RIGHT", 12, 0)
    end
    if unitFrame.AurasFrame.LossOfControlFrame then--敌方玩家右侧控制光环
        unitFrame.AurasFrame.LossOfControlFrame:SetScale(PlateColorDB.auraRScale)
        unitFrame.AurasFrame.LossOfControlFrame:ClearAllPoints()
        unitFrame.AurasFrame.LossOfControlFrame:SetPoint("LEFT", unitFrame.healthBar, "RIGHT", 12, 0)
    end
end

ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	if not namePlate then return end
	local unitFrame = namePlate.UnitFrame
	ns.CrowdControlListFrameScale(unitFrame)
end)