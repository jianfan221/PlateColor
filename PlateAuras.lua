local _, ns = ...

local function SetCooldownText(self)
    local success, region = pcall(function() 
        return self.Cooldown:GetRegions()
    end)
    if success and region then
        if type(region.SetFont) == "function" then
            region:SetFontObject("PC_FontOutline")
            region:SetFontHeight(self:GetHeight()/1.5 * PlateColorDB.auraText1)
        end
    end
end
ns.hook(NamePlateAuraItemMixin,"OnLoad",SetCooldownText)

--驱散颜色
local dispelColor = C_CurveUtil.CreateColorCurve()
dispelColor:SetType(Enum.LuaCurveType.Step)
dispelColor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
dispelColor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
dispelColor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
dispelColor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
dispelColor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
dispelColor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒
ns.hook(NamePlateAuraItemMixin, "SetAura", function(self,aura)
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
        local color = C_UnitAuras.GetAuraDispelTypeColor(self.unitToken, aura.auraInstanceID, dispelColor)
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