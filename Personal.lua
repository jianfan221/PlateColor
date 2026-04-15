local _, ns = ...
function ns.SetPersonalTexture()
	if not PlateColorDB.myHPSetup then return end
	if GetCVar("nameplateShowSelf") == "0" then  return end
	if not PersonalResourceDisplayFrame then return end

	PersonalResourceDisplayFrame:SetWidth(PlateColorDB.myHPwidth)
	PersonalResourceDisplayFrame.PowerBar:SetWidth(PlateColorDB.myHPwidth)
	PersonalResourceDisplayFrame.AlternatePowerBar:SetWidth(PlateColorDB.myHPwidth)
	PersonalResourceDisplayFrame.HealthBarsContainer:SetHeight(PlateColorDB.myHPheight)
	PersonalResourceDisplayFrame.PowerBar:SetHeight(PlateColorDB.myHPheight)
	PersonalResourceDisplayFrame.AlternatePowerBar:SetHeight(PlateColorDB.myHPheight)

	PersonalResourceDisplayFrame.HealthBarsContainer:SetFrameStrata("LOW")--不然会挡住资源的文本
	if ns.HpTextures[PlateColorDB.myHPTexture] then
		PersonalResourceDisplayFrame.HealthBarsContainer.healthBar:SetStatusBarTexture(ns.HpTextures[PlateColorDB.myHPTexture])
		PersonalResourceDisplayFrame.PowerBar:SetStatusBarTexture(ns.HpTextures[PlateColorDB.myHPTexture])
	end

	if not PlateColorDB.myHPValue then
		if PersonalResourceDisplayFrame.HealthBarsContainer.healthBar.Text then
			PersonalResourceDisplayFrame.HealthBarsContainer.healthBar.Text:Hide()
		end
		if PersonalResourceDisplayFrame.PowerBar.Text then
			PersonalResourceDisplayFrame.PowerBar.Text:Hide()
		end
		if PersonalResourceDisplayFrame.AlternatePowerBar.Text then
			PersonalResourceDisplayFrame.AlternatePowerBar.Text:Hide()
		end
		return
	end

	local HB = PersonalResourceDisplayFrame.HealthBarsContainer.healthBar
	if not HB.Text then
		HB.Text = HB:CreateFontString(nil, "OVERLAY")
		HB.Text:SetPoint("CENTER", HB, "CENTER", 0, -1)
		HB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.25, "OUTLINE")
		HB:HookScript("OnValueChanged", function(self)
			if not self:IsShown() then return end
			local HPPer = UnitHealthPercent("player", true, CurveConstants.ScaleTo100)
			self.Text:SetText(string.format("%d", HPPer))
		end)
	end
	HB.Text:SetShown(true)
	HB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.25, "OUTLINE")
	local HPPer = UnitHealthPercent("player", true, CurveConstants.ScaleTo100)
	HB.Text:SetText(string.format("%d", HPPer))

	local PB = PersonalResourceDisplayFrame.PowerBar
	if not PB.Text then
		PB.Text = PB:CreateFontString(nil, "OVERLAY")
		PB.Text:SetPoint("CENTER", PB, "CENTER", 0, -1)
		PB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.25, "OUTLINE")
		PB:HookScript("OnValueChanged", function(self)
			if not self:IsShown() then return end
			if UnitPowerType("player") ~= 0 then
				self.Text:SetText(ns.value(self:GetValue()))
			else
				local powerPer = UnitPowerPercent("player", 0, true, CurveConstants.ScaleTo100)
				self.Text:SetText(string.format("%d", powerPer))
			end
		end)
	end
	PB.Text:SetShown(true)
	PB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.25, "OUTLINE")
	if UnitPowerType("player") ~= 0 then
		PB.Text:SetText(ns.value(PB:GetValue()))
	else
		local powerPer = UnitPowerPercent("player", 0, true, CurveConstants.ScaleTo100)
		PB.Text:SetText(string.format("%d", powerPer))
	end
	local AB = PersonalResourceDisplayFrame.AlternatePowerBar
	if not AB.Text then
		AB.Text = AB:CreateFontString(nil, "OVERLAY")
		AB.Text:SetPoint("CENTER", AB, "CENTER", 0, -1)
		AB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.3, "OUTLINE")
		AB:HookScript("OnValueChanged", function(self)
			if not self:IsShown() then return end
			if self.powerName and self.powerName == "STAGGER" then
				local stagger = (UnitStagger and UnitStagger("player")) or 0
				if PlateColorDB.myHPStaggerUseValue then
					self.Text:SetText(ns.value(stagger))
				else
					local maxHealth = UnitHealthMax("player") or 1
					self.Text:SetText(string.format("%d", maxHealth > 0 and (stagger / maxHealth * 100) or 0))
				end
			elseif self.powerName then
				self.Text:SetText(string.format("%d",self:GetValue()))
			end
		end)
	end
	AB.Text:SetShown(true)
	AB.Text:SetFont(ns.fonts, PlateColorDB.myHPheight*1.3, "OUTLINE")
	if AB.powerName and AB.powerName == "STAGGER" then
		local stagger = (UnitStagger and UnitStagger("player")) or 0
		local maxHealth = UnitHealthMax("player") or 1
		if PlateColorDB.myHPStaggerUseValue then
			AB.Text:SetText(ns.value(stagger))
		else
			AB.Text:SetText(string.format("%d", maxHealth > 0 and (stagger / maxHealth * 100) or 0))
		end
	elseif AB.powerName then
		AB.Text:SetText(string.format("%d",AB:GetValue()))
	end
	
end

-- 额外资源
local classr, classg, classb = RAID_CLASS_COLORS[select(2, UnitClass("player"))]:GetRGBA()
local NewPowerBar

function ns.AddNewPowerBar()
	if not PlateColorDB.myHPSetup then return end
	if GetCVar("nameplateShowSelf") == "0" or PlateColorDB.myHPShowMode == 0  then 
		if NewPowerBar then NewPowerBar:Hide() end
		return
	end
	-- 创建父框架
	if not NewPowerBar then
		PersonalResourceDisplayFrame.NewPowerBar = CreateFrame("Frame", nil, PersonalResourceDisplayFrame)
		NewPowerBar = PersonalResourceDisplayFrame.NewPowerBar
	end
	NewPowerBar:SetSize(PlateColorDB.myHPwidth, PlateColorDB.myHPheight)
	
	-- 统一设置个人资源每个条位置
	local AA = PersonalResourceDisplayFrame
	local HB = PersonalResourceDisplayFrame.HealthBarsContainer
	local PB = PersonalResourceDisplayFrame.PowerBar
	local AB = PersonalResourceDisplayFrame.AlternatePowerBar
	local NB = (prdClassFrame and prdClassFrame:IsShown()) and prdClassFrame or nil
	NewPowerBar:ClearAllPoints()
	if PlateColorDB.myHPShowMode == 2 then
		if AB:IsShown() and (NB and NB:IsShown()) then
			HB:Hide()
			PB:Hide()
			AB:SetPoint("TOP",PB,"TOP",0,0)
			NewPowerBar:SetPoint("BOTTOMLEFT", PB, "TOPLEFT", -1, 1)
		elseif AB:IsShown() or (NB and NB:IsShown()) then
			HB:Hide()
			PB:Show()
			NewPowerBar:SetPoint("BOTTOMLEFT", PB, "TOPLEFT", -1, 1)
			AB:SetPoint("TOP",AA,"TOP",0,1)
		else
			HB:Show()
			PB:Show()
			AB:SetPoint("TOP",PB,"BOTTOM",0,0)
		end
	elseif PlateColorDB.myHPShowMode == 1 then
		HB:Show()
		PB:Show()
		PB:SetPoint("TOP",HB,"BOTTOM",0,0)
		AB:SetPoint("TOP",PB,"BOTTOM",0,0)
		NewPowerBar:SetPoint("TOPLEFT", AB:IsShown() and AB or PB, "BOTTOMLEFT", -1, -1)
	end
	NewPowerBar:SetShown(prdClassFrame and prdClassFrame:IsShown())
	if not prdClassFrame then return end
	prdClassFrame:SetPoint("TOP",0,-800000)

	-- 获取最大能量值
	local color = PlateColorDB.newClassBarSetColor and PlateColorDB.newClassBarColor or {r = classr, g = classg, b = classb}
	local r, g, b = color.r, color.g, color.b
	local classID = select(3, UnitClass("player"))
	local maxPower = (classID == 6) and UnitPowerMax("player", 5) or (prdClassFrame.powerType and UnitPowerMax("player", prdClassFrame.powerType) or 0)
	if not maxPower or maxPower == 0 then return end
	-- 创建或更新资源点框架
	local chargeWidth = (PlateColorDB.myHPwidth - 2 * (maxPower - 1)) / maxPower
	for i = 1, maxPower do
		if not NewPowerBar[i] then
			NewPowerBar[i] = CreateFrame("StatusBar", nil, NewPowerBar)
			NewPowerBar[i].bgTexture = NewPowerBar[i]:CreateTexture(nil, "BACKGROUND")
			NewPowerBar[i].bgTexture:SetAllPoints()
			NewPowerBar[i].bgTexture:SetTexture(130937)
			NewPowerBar[i].bgTexture:SetVertexColor(0.2, 0.2, 0.2, 0.65)
			NewPowerBar[i].shadow = CreateFrame("Frame", nil, NewPowerBar[i], "BackdropTemplate")
			NewPowerBar[i].shadow:SetFrameLevel(0)
			NewPowerBar[i].shadow:SetPoint("TOPLEFT", -1, 1)
			NewPowerBar[i].shadow:SetPoint("BOTTOMRIGHT", 1, -1)
			NewPowerBar[i].shadow:SetBackdrop({edgeFile = 'Interface\\Buttons\\WHITE8x8',edgeSize = 1})
			NewPowerBar[i].shadow:SetBackdropBorderColor(0, 0, 0, 0.8)
		end
		NewPowerBar[i]:SetStatusBarTexture(ns.HpTextures[PlateColorDB.myHPTexture] or "Interface/TargetingFrame/UI-StatusBar")
		NewPowerBar[i]:SetStatusBarColor(r, g, b, 1)
		NewPowerBar[i]:Show()
		NewPowerBar[i]:SetSize(chargeWidth, PlateColorDB.myHPheight)
	end
	
	-- 根据职业设置更新逻辑
	if classID == 6 then
		-- 死亡骑士：符文冷却处理
		for i = 1, maxPower do
			if not NewPowerBar[i].UpdateRun then
				NewPowerBar[i].UpdateRun = true
				NewPowerBar[i]:SetScript("OnUpdate", function(self)
					if not NewPowerBar:IsShown() then return end
					local start, duration, runeReady = GetRuneCooldown(i)
					if runeReady then
						self:SetMinMaxValues(0, 1)
						self:SetValue(1)
						self:SetStatusBarColor(r, g, b, 1)
					elseif start and duration and duration > 0 then
						self:SetMinMaxValues(start, start + duration)
						self:SetValue(GetTime())
						self:SetStatusBarColor(1, 0.7, 0, 1)
					end
				end)
			end
		end
		-- 符文排序函数
		local function UpdateRuneOrder()
			if not NewPowerBar or not NewPowerBar:IsShown() then return end
			local indices = {}
			for i = 1, maxPower do
				if NewPowerBar[i] then
					NewPowerBar[i]:ClearAllPoints()
					indices[#indices + 1] = i
				end
			end
			table.sort(indices, function(a, b)
				local aReady = select(3, GetRuneCooldown(a))
				local bReady = select(3, GetRuneCooldown(b))
				if aReady ~= bReady then return aReady end
				return (select(1, GetRuneCooldown(a)) or 0) < (select(1, GetRuneCooldown(b)) or 0)
			end)
			for idx, i in ipairs(indices) do
				if idx == 1 then
					NewPowerBar[i]:SetPoint("LEFT", NewPowerBar, "LEFT", 1, 0)
				else
					NewPowerBar[i]:SetPoint("LEFT", NewPowerBar[indices[idx-1]], "RIGHT", 2, 0)
				end
			end
		end
		
		UpdateRuneOrder()
		NewPowerBar:RegisterEvent("RUNE_POWER_UPDATE")
		NewPowerBar:SetScript("OnEvent", function()
			if NewPowerBar:IsShown() then UpdateRuneOrder() end
		end)
		
	elseif prdClassFrame.powerType then
		-- 其他职业：统一设置位置
		for i = 1, maxPower do
			NewPowerBar[i]:SetMinMaxValues(0, 1)
			NewPowerBar[i]:SetPoint("LEFT", i == 1 and NewPowerBar or NewPowerBar[i-1], i == 1 and "LEFT" or "RIGHT", i == 1 and 1 or 2, 0)
		end
		-- 统一用 OnUpdate 更新
		NewPowerBar:SetScript("OnUpdate", function()
			if not NewPowerBar:IsShown() then return end
			if not prdClassFrame or not prdClassFrame:IsShown() or not prdClassFrame.powerType then return end
			local power = UnitPower("player", prdClassFrame.powerType, true)
			local maxPower = UnitPowerMax("player", prdClassFrame.powerType)
			local displayMod = (UnitPowerDisplayMod and UnitPowerDisplayMod(prdClassFrame.powerType)) or 1
			if not power or ns.MM(power) or not maxPower or ns.MM(maxPower) or not displayMod or ns.MM(displayMod) then return end
			if displayMod == 0 then displayMod = 1 end
			if prdClassFrame.powerType == 19 then
				local partial = (UnitPartialPower("player", 19) or 0) / 1000.0
				power = power + partial
			end
			power = power / displayMod
			-- 统一更新所有资源点（每段 0-1 填充）
			for i = 1, maxPower do
				if NewPowerBar[i] then
					local shardStart, shardEnd = i - 1, i
					if power >= shardEnd then
						NewPowerBar[i]:SetValue(1)
						NewPowerBar[i]:SetStatusBarColor(r, g, b, 1)
					elseif power > shardStart then
						NewPowerBar[i]:SetValue(power - shardStart)
						NewPowerBar[i]:SetStatusBarColor(1, 0.7, 0, 1)
					else
						NewPowerBar[i]:SetValue(0)
						NewPowerBar[i]:SetStatusBarColor(0, 0, 0, 0)
					end
				end
			end
		end)
	end
	
	-- 隐藏超出范围的框架
	for i = maxPower + 1, 10 do
		if NewPowerBar[i] then NewPowerBar[i]:Hide() end
	end
end

function ns.AllmyPowerBar()
	ns.SetPersonalTexture()
	ns.AddNewPowerBar()
end
ns.event("PLAYER_ENTERING_WORLD", function(event)
	ns.AllmyPowerBar()
	if prdClassFrame and prdClassFrame.Setup then
		hooksecurefunc(prdClassFrame, "Setup", function()
			ns.AddNewPowerBar()
		end)
	end
	if PersonalResourceDisplayFrame then
		hooksecurefunc(PersonalResourceDisplayFrame, "UpdateAdditionalBarAnchors", function()
			ns.AddNewPowerBar()
		end)
		hooksecurefunc(PersonalResourceDisplayFrame, "SetupPowerBar", function()
			ns.AddNewPowerBar()
		end)
	end
end)

ns.event("CVAR_UPDATE", function(event, cvar,a)
	if cvar == "nameplateShowSelf" then
		ns.AllmyPowerBar()
	end
end)
ns.event("TRAIT_CONFIG_UPDATED", function(event, unit)
	ns.AddNewPowerBar()
end)

hooksecurefunc(EditModeManagerFrame, "OnSystemPositionChange", function(edit,self)
	if not PlateColorDB.myHPEdit then return end
	if not self then return end
	if self ~= PersonalResourceDisplayFrame then return end
	if InCombatLockdown() then return end

	local bottom = self:GetBottom()
	local height = self:GetHeight() or 0
	local X,Y = UIParent:GetWidth()/2, bottom + height
	self:ClearAllPoints()
	self:SetPoint("TOP",UIParent,"BOTTOMLEFT",X,Y)
	if EditModeManagerFrame and EditModeManagerFrame.UpdateSystemAnchorInfo then
		-- UpdateSystemAnchorInfo 会读取当前 SetPoint 的值并更新到 layoutInfo 缓存中
		local hasChanged = EditModeManagerFrame:UpdateSystemAnchorInfo(self)
		if hasChanged then
			-- 标记当前框体有变动，使编辑模式界面的“保存”按钮亮起
			if self.SetHasActiveChanges then
				self:SetHasActiveChanges(true)
			end
			-- 通知管理器检查整体状态
			EditModeManagerFrame:CheckForSystemActiveChanges()
		end
	end
end)