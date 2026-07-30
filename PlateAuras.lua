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

function ns.CrowdControlListFrameScale(unitFrame)
    unitFrame.AurasFrame.DebuffListFrame:SetScale(PlateColorDB.auraTopScale)
    if unitFrame.AurasFrame.BuffListFrame then--左侧光环
        unitFrame.AurasFrame.BuffListFrame:SetScale(PlateColorDB.auraLScale)
        unitFrame.AurasFrame.BuffListFrame:ClearAllPoints()
        local anchor = unitFrame.abs or unitFrame.healthBar
        unitFrame.AurasFrame.BuffListFrame:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
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
	if not unitFrame then return end
	ns.CrowdControlListFrameScale(unitFrame)
end)

--驱散颜色 (12.1 前使用旧版)
if not DoesTemplateExist("CustomAuraContainerTemplate") then
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
            local color = C_UnitAuras.GetAuraDispelTypeColor(self.unitToken, aura.auraInstanceID, ns.dispelColor)
            if color and UnitCanAttack("player", self.unitToken) then
                self.Stealable:SetVertexColor(color:GetRGB())
                self.Stealable:SetAlphaFromBoolean(self.isBuff,255,0)
                self.Stealable:Show()
            end
        end
    end)
end

--12.1 AuraContainer 血条左侧仅显示敌方可驱散光环
if DoesTemplateExist("CustomAuraContainerTemplate") then
	local dispelPool
	local dispelMap = {}
	EventUtil.ContinueOnPlayerLogin(function()
        --玩家登录后创建驱散光环容器,关闭自带的左侧增益光环
        ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Buffs, false)
        ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, false)
		dispelPool = CreateFramePool("Frame", UIParent, nil, nil, false, function(frame)
			frame.container = CreateFrame("AuraContainer", nil, frame, "CustomAuraContainerTemplate")
			frame.container:Hide()
			frame.container:AddAuraGroup("disBuff", "HELPFUL|DISPELLABLE", {
				maxFrameCount = 2,
				layout = { elementSpacingX = 2 },
				initializeFrame = function(btn)
					btn:SetSize(25*PlateColorDB.auraLScale, 25*PlateColorDB.auraLScale)--NamePlateConstants.AURA_ITEM_HEIGHT == 25
					btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
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
					local border = cooldown:CreateTexture(nil, "ARTWORK")
					border:SetPoint("TOPLEFT", btn, "TOPLEFT", -5, 5)
					border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 5, -5)
					border:SetTexture("Interface\\AddOns\\PlateColor\\texture\\Border\\soft-square2.png")
					btn:AddDispelTypeTexture(border, {
						showWhenHelpful = true,
						showWhenHarmful = false,
						style = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
						customDispelColorCurve = ns.dispelColor,
					})
				end,
			})
			frame.container:AddAuraGroup("otherBuff", "HELPFUL|IMPORTANT|!DISPELLABLE", {
				maxFrameCount = 2,
				layout = { elementSpacingX = 2 },
				initializeFrame = function(btn)
					btn:SetSize(25*PlateColorDB.auraLScale, 25*PlateColorDB.auraLScale)
					btn:SetTooltipAnchorPoint("ANCHOR_TOPRIGHT")
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
				end,
			})
		end, 40)
	end)

	ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if not unitFrame then return end

		-- 统一清理旧状态：dispelMap 重复注册 + 姓名板复用残留
		if dispelMap[unit] then
			dispelPool:Release(dispelMap[unit])
			dispelMap[unit] = nil
		end
		unitFrame.PC_DispelAuras = nil

		if not UnitCanAttack("player", unit) then
			return
		end

		local dispelFrame = dispelPool:Acquire()
		if not dispelFrame then return end

		dispelMap[unit] = dispelFrame
		unitFrame.PC_DispelAuras = dispelFrame.container
		unitFrame.PC_DispelAuras:SetParent(unitFrame.healthBar)
		unitFrame.PC_DispelAuras:Show()
		unitFrame.PC_DispelAuras:SetUnit(unit)
		C_Timer.After(0, function()
			local anchor = unitFrame.abs or unitFrame.healthBar

			unitFrame.PC_DispelAuras:ClearAllPoints()
			unitFrame.PC_DispelAuras:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
		end)

		if unitFrame.AurasFrame and unitFrame.AurasFrame.BuffListFrame then
			unitFrame.AurasFrame.BuffListFrame:Hide()
		end
	end)

	ns.event("NAME_PLATE_UNIT_REMOVED", function(event, unit)
		if dispelMap[unit] then
			dispelPool:Release(dispelMap[unit])
			dispelMap[unit] = nil
		end
	end)
end

