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

	--先关闭自带的左侧增益光环,因为我们接下来自己创建
	EventUtil.ContinueOnPlayerLogin(function()
		ns.SetCVar("nameplateEnemyPlayerAuraDisplay", Enum.NamePlateEnemyPlayerAuraDisplay.Buffs, false)
		ns.SetCVar("nameplateEnemyNpcAuraDisplay", Enum.NamePlateEnemyNpcAuraDisplay.Buffs, false)
	end)

	-- 配置容器光环组（每个姓名板的容器首次创建时调用）
	local function SetupDispelContainer(container)
		container:AddAuraGroup("disBuff", "HELPFUL|DISPELLABLE", {
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
				cooldown:SetReverse(true)--反转冷却动画方向
				btn:SetDurationCooldown(cooldown)
				--独立叠层/边框容器: 层级在冷却之上(+2), 不随冷却隐藏
				local overlay = CreateFrame("Frame", nil, btn)
				overlay:SetAllPoints(btn)
				overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
				local count = overlay:CreateFontString(nil, "OVERLAY", "PC_FontOutline")
				count:SetPoint("BOTTOMRIGHT", btn, 0, 0)
				count:SetVertexColor(1, 1, 1)
				count:SetFontHeight(14)
				btn:SetApplicationCount(count, {})
				local border = overlay:CreateTexture(nil, "OVERLAY")
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
		container:AddAuraGroup("otherBuff", "HELPFUL|IMPORTANT|!DISPELLABLE", {
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
				--独立叠层容器: 层级在冷却之上(+2), 不随冷却隐藏
				local overlay = CreateFrame("Frame", nil, btn)
				overlay:SetAllPoints(btn)
				overlay:SetFrameLevel(btn:GetFrameLevel() + 2)
				local count = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				count:SetPoint("BOTTOMRIGHT", btn, 0, 0)
				count:SetVertexColor(1, 1, 1)
				count:SetFontHeight(14)
				btn:SetApplicationCount(count, {})
			end,
		})
	end

	ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
		local namePlate = C_NamePlate.GetNamePlateForUnit(unit, false)
		if not namePlate then return end
		local unitFrame = namePlate.UnitFrame
		if not unitFrame then return end

		if not UnitCanAttack("player", unit) then
			if unitFrame.PC_DispelAuras then
				unitFrame.PC_DispelAuras:Hide()
			end
			return
		end

		-- 左侧增益光环开关关闭时隐藏
		if not PlateColorDB.auraLEnable then
			if unitFrame.PC_DispelAuras then
				unitFrame.PC_DispelAuras:Hide()
			end
			return
		end

		-- 容器不存在则创建（作为 healthBar 子级，随血条显示/隐藏、继承框架层级）
		if not unitFrame.PC_DispelAuras then
			unitFrame.PC_DispelAuras = CreateFrame("AuraContainer", nil, unitFrame.healthBar, "CustomAuraContainerTemplate")
			SetupDispelContainer(unitFrame.PC_DispelAuras)
		end
		unitFrame.PC_DispelAuras:SetUnit(unit)
		unitFrame.PC_DispelAuras:Show()
		C_Timer.After(0, function()
			local anchor = unitFrame.abs or unitFrame.healthBar
			if not anchor or not anchor:IsShown() then return end
			unitFrame.PC_DispelAuras:ClearAllPoints()
			unitFrame.PC_DispelAuras:SetPoint("RIGHT", anchor, "LEFT", -2, 0)
		end)
	end)
end

