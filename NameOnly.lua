local _, ns = ...

local function SetOnlyNameScale(self)
	if not self.unit then return end
	if not PlateColorDB.onlyName and not PlateColorDB.onlyNameNpc then return end
	if self:IsForbidden() then
		SystemFont_NamePlate:SetFont(SystemFont_NamePlate:GetFont(),1,"OUTLINE")
		SystemFont_NamePlate:SetFont(SystemFont_NamePlate:GetFont(),PlateColorDB.helpNameScale,"OUTLINE")
		SystemFont_NamePlate_Outlined:SetFont(SystemFont_NamePlate_Outlined:GetFont(),1,"OUTLINE")
		SystemFont_NamePlate_Outlined:SetFont(SystemFont_NamePlate_Outlined:GetFont(),PlateColorDB.helpNameScale,"OUTLINE")
	end
end

ns.hook(NamePlateUnitFrameMixin, "OnUnitSet", function(self)
	SetOnlyNameScale(self)
end)

local function TrySetOnlyName(self)
	if not self then return end
	if not self.unit then return end
	if not PlateColorDB.onlyNameNpc then return end
	if UnitCanAttack("player", self.unit) then
		TextureLoadingGroupMixin.RemoveTexture({ textures = self }, "showOnlyName")
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.castBar }, "showOnlyName")
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.castBar }, "widgetsOnly")
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.HealthBarsContainer.healthBar }, "showOnlyName")
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.ClassificationFrame }, "showOnlyName")
		if self.healthBar and self.healthBar.show then
			self.healthBar:Hide()
			self.healthBar:Show()
		end
		if self.castBar and self.castBar.show and (UnitCastingInfo(self.unit) ~= nil or UnitChannelInfo(self.unit) ~= nil) then
			self.castBar:Show()
		end
	elseif not self:IsPlayer() and (self:IsForbidden() or not UnitCanAttack("player", self.unit)) then
		TableUtil.TrySet(self, "showOnlyName")
		TableUtil.TrySet(self.castBar, "showOnlyName")
		TableUtil.TrySet(self.castBar, "widgetsOnly")
		TableUtil.TrySet(self.HealthBarsContainer.healthBar, "showOnlyName")
		TableUtil.TrySet(self.ClassificationFrame, "showOnlyName")
		TableUtil.TrySet(self.optionTable, "colorNameBySelection")
	end
end

ns.hook(NamePlateUnitFrameMixin, "UpdateShowOnlyName", function(self)
	TrySetOnlyName(self)
end)