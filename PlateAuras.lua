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

-- Hook SetAura to remove tooltip from aura icons
hooksecurefunc(NamePlateAuraItemMixin, "SetAura", function(self)
    if self and not self:IsForbidden() then
        self:EnableMouse(not PlateColorDB.hideAuraTooltip)
    end
end)

function ns.CrowdControlListFrameScale(unitFrame)
    unitFrame.AurasFrame.DebuffListFrame:SetScale(PlateColorDB.auraTopScale)
    if unitFrame.AurasFrame.BuffListFrame then--左侧光环
        unitFrame.AurasFrame.BuffListFrame:SetScale(PlateColorDB.auraLScale)
        unitFrame.AurasFrame.BuffListFrame:ClearAllPoints()
        unitFrame.AurasFrame.BuffListFrame:SetPoint("RIGHT", unitFrame.healthBar, "LEFT", -12, 0)
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