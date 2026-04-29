local _, ns = ...

--名字模式功能文本
function ns.PlateOnlyName(unitFrame)
	if not unitFrame then return end
	if not unitFrame.unit then return end

	if not unitFrame.NpcFuntext then
		unitFrame.NpcFuntext = unitFrame:CreateFontString(nil, "ARTWORK")
		unitFrame.NpcFuntext:SetPoint("TOP",unitFrame.name,"BOTTOM",0,0)
		unitFrame.NpcFuntext:SetVertexColor(1,1,1)
		unitFrame.NpcFuntext:SetSmoothScaling(false)
		unitFrame.NpcFuntext:SetAlpha(0.9)
	end
	if ns.MM(UnitGUID(unitFrame.unit)) then
		unitFrame.NpcFuntext:Hide()
		return
	end
	local text = ""
	if PlateColorDB.showGuildName and unitFrame:IsPlayer() then
		unitFrame.NpcFuntext:SetFont(ns.fonts, PlateColorDB.helpNameScale * 0.9, "OUTLINE")
		text = GetGuildInfo(unitFrame.unit) or ""
		unitFrame.NpcFuntext:SetText(text)
	elseif not unitFrame:IsPlayer() then
		local tooltipData = C_TooltipInfo.GetUnit(unitFrame.unit)
		if tooltipData and tooltipData.lines[2] and not string.match(tooltipData.lines[2].leftText,LEVEL) and not unitFrame:IsPlayer() then
			unitFrame.NpcFuntext:SetFont(ns.fonts, PlateColorDB.helpNameScale * 0.8, "")
			text = tooltipData.lines[2].leftText or ""
			unitFrame.NpcFuntext:SetText(text)
		end
	end
	unitFrame.NpcFuntext:SetShown(text ~= "" and unitFrame.name:IsShown() and not unitFrame.healthBar:IsShown())
end

--设置时更新
function ns.SetOnlyNames(unitFrame)
	ns.PlateOnlyName(unitFrame)
	ns.SetSelectedScale()
	ns.SetPoints(unitFrame)
end
local function ShowhealthBar(unitFrame)
	if not PlateColorDB.onlyNameNpc then return end
	if UnitCanAttack("player",unitFrame.unit) and not unitFrame.HealthBarsContainer.healthBar:IsShown() then
		if unitFrame.showOnlyName then
			unitFrame.showOnlyName = nil
		end
		if unitFrame.HealthBarsContainer.healthBar.showOnlyName then
			unitFrame.HealthBarsContainer.healthBar.showOnlyName = nil
			unitFrame.HealthBarsContainer.healthBar:Show()
		end
		if unitFrame.castBar then
			if unitFrame.castBar.showOnlyName then
				unitFrame.castBar.showOnlyName = nil
			end
			if unitFrame.castBar.widgetsOnly then
				unitFrame.castBar.widgetsOnly = nil
			end
		end
	end
end

hooksecurefunc("CompactUnitFrame_UpdateName", function(unitFrame)
	if unitFrame:IsForbidden() then return end
	if not string.match(unitFrame.unit,"nameplate") then return end
	ns.PlateOnlyName(unitFrame)
	ShowhealthBar(unitFrame)
end)


local function TrySetOnlyName(self)
	if not self.unit then return end
	if self:IsForbidden() then
		SystemFont_NamePlate:SetFont(SystemFont_NamePlate:GetFont(),1,"OUTLINE")
		SystemFont_NamePlate_Outlined:SetFont(SystemFont_NamePlate_Outlined:GetFont(),1,"OUTLINE")
		SystemFont_NamePlate:SetFont(SystemFont_NamePlate:GetFont(),PlateColorDB.helpNameScale,"OUTLINE")
		SystemFont_NamePlate_Outlined:SetFont(SystemFont_NamePlate_Outlined:GetFont(),PlateColorDB.helpNameScale,"OUTLINE")
	end
	if not PlateColorDB.onlyNameNpc then return end
	if not self:IsPlayer() and (self:IsForbidden() or not UnitCanAttack("player",self.unit)) then
		TableUtil.TrySet(self, "showOnlyName")
		if not self:IsForbidden() and self.HealthBarsContainer.healthBar:IsShown() then
			self.HealthBarsContainer.healthBar:Hide()
		end
	end
end
ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	TrySetOnlyName(unitFrame)
	ShowhealthBar(unitFrame)
end)
hooksecurefunc(NamePlateUnitFrameMixin, "OnUnitSet", function(self)
	TrySetOnlyName(self)
end)
hooksecurefunc(NamePlateUnitFrameMixin, "OnUnitFactionChanged", function(self)
	if not self.unit then return end
	TrySetOnlyName(self)
end)

hooksecurefunc(NamePlateUnitFrameMixin, "UpdateNameClassColor", function(self)
	if not self.unit then return end
	if not PlateColorDB.onlyNameNpc then return end
	if not self:IsPlayer() and (self:IsForbidden() or not UnitCanAttack("player",self.unit)) then
		TableUtil.TrySet(self.optionTable, "colorNameBySelection")
		TableUtil.TrySet(self.castBar, "showOnlyName")
		TableUtil.TrySet(self.castBar, "widgetsOnly")
		TableUtil.TrySet(self.HealthBarsContainer.healthBar, "showOnlyName")
		TableUtil.TrySet(self.ClassificationFrame, "showOnlyName")
	end
end)