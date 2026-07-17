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

--鼠标提示开关（所有版本通用）
ns.hook(NamePlateAuraItemMixin, "SetAura", function(self, aura)
	if self and not self:IsForbidden() then
		self:EnableMouse(not PlateColorDB.hideAuraTooltip)
	end
end)

--驱散颜色 (12.1 前使用旧版)
local _, _, _, tocversion = GetBuildInfo()
if tocversion < 120100 then
    local dispelColor = C_CurveUtil.CreateColorCurve()
    dispelColor:SetType(Enum.LuaCurveType.Step)
    dispelColor:AddPoint(0, CreateColor(0,  0,  0,  0))--无
    dispelColor:AddPoint(1, CreateColor(1,  1,  1,  1))--魔法
    dispelColor:AddPoint(2, CreateColor(0.5,0,  1,  1))--诅咒
    dispelColor:AddPoint(3, CreateColor(1,0.5,  0,  1))--疾病
    dispelColor:AddPoint(4, CreateColor(0,  1,  0,  1))--中毒
    dispelColor:AddPoint(9, CreateColor(1,  0,  0,  1))--激怒
    ns.hook(NamePlateAuraItemMixin, "SetAura", function(self, aura)
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
end

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

--12.1 AuraContainer 血条左侧仅显示敌方可驱散光环
if tocversion >= 120100 then
	local auraPool
	local dispelMap = {}
	EventUtil.ContinueOnPlayerLogin(function()
        --玩家登录后创建驱散光环容器,关闭自带的左侧增益光环
        ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Buffs, false)
        ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, false)
		auraPool = CreateFramePool("Frame", UIParent, nil, nil, false, function(frame)
			frame.container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
			frame.container:Hide()
			frame.container:AddAuraGroup("magicEnrage", "HELPFUL|DISPELLABLE", {
				maxFrameCount = 3,
				layout = { elementSpacingX = 2 },
				initializeFrame = function(btn)
					btn:SetSize(20*PlateColorDB.auraLScale, 20*PlateColorDB.auraLScale)--20乘以缩放比例
					local icon = btn:CreateTexture(nil, "ARTWORK")
					icon:SetAllPoints(btn)
					icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
					btn:SetIcon(icon)
					local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
					cooldown:SetAllPoints(btn)
					cooldown:SetHideCountdownNumbers(false)
					btn:SetDurationCooldown(cooldown)
					local count = cooldown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
					count:SetPoint("BOTTOMRIGHT", btn, 0, 0)
                    count:SetVertexColor(1, 1, 1)
					count:SetFontHeight(13)
					btn:SetApplicationCount(count, {})
					local border = cooldown:CreateTexture(nil, "OVERLAY")
					border:SetPoint("TOPLEFT", btn, "TOPLEFT", -5, 5)
					border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -5)
					border:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Stealable")
					border:SetBlendMode("ADD")
					btn:SetAuraBorder(border, {showWhenHelpful = true, style = 1})
				end,
			})
		end, 40)
	end)

	ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
		if dispelMap[unit] then
			auraPool:Release(dispelMap[unit])
			dispelMap[unit] = nil
		end
		if not UnitCanAttack("player", unit) then return end

		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame

		local poolFrame = auraPool:Acquire()
		if not poolFrame then return end

		dispelMap[unit] = poolFrame
		unitFrame.PC_DispelAuras = poolFrame.container
		unitFrame.PC_DispelAuras:SetParent(unitFrame.healthBar)
		unitFrame.PC_DispelAuras:Show()
		unitFrame.PC_DispelAuras:SetUnit(unit)
		C_Timer.After(0, function()
			local anchor = unitFrame.healthBar
			if unitFrame.ArrowLeft then anchor = unitFrame.ArrowLeft end
			unitFrame.PC_DispelAuras:ClearAllPoints()
			unitFrame.PC_DispelAuras:SetPoint("RIGHT", anchor, "LEFT", -5, 0)
		end)

		if unitFrame.AurasFrame and unitFrame.AurasFrame.BuffListFrame then
			unitFrame.AurasFrame.BuffListFrame:Hide()
		end
	end)

	ns.event("NAME_PLATE_UNIT_REMOVED", function(event, unit)
		if dispelMap[unit] then
			auraPool:Release(dispelMap[unit])
			dispelMap[unit] = nil
		end
	end)
end

