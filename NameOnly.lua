local _, ns = ...

-- 缓存"友方玩家仅显示名字"CVar 状态，避免每次读取
local ShowOnlyNameEnabled = C_CVar.GetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "1"
ns.hookcvar("nameplateShowOnlyNameForFriendlyPlayerUnits", function()
	ShowOnlyNameEnabled = C_CVar.GetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits") == "1"
end)

local function SetOnlyNameScale(self)
	if not self.unit then return end
	if not ShowOnlyNameEnabled and not PlateColorDB.onlyNameNpc then return end
	if self:IsForbidden() then
		SystemFont_NamePlate:CopyFontObject(PC_FontOutline)
		SystemFont_NamePlate:SetFontHeight(PlateColorDB.helpNameScale)
		SystemFont_NamePlate_Outlined:CopyFontObject(PC_FontOutline)
		SystemFont_NamePlate_Outlined:SetFontHeight(PlateColorDB.helpNameScale)
	end
end

ns.hook(NamePlateUnitFrameMixin, "OnUnitSet", function(self)
	SetOnlyNameScale(self)
end)

--血条显隐变化后重排名字：SetPoints 依赖 healthBar:IsShown()，
--而我们自己隐藏/恢复血条不会触发暴雪 UpdateAnchors，需要手动补一次
local function TrySetOnlyName(self)
	if not self then return end
	if not self.unit then return end
	if not PlateColorDB.onlyNameNpc then return end
	local castBar = ns.GetCastBar(self)
	local hidden  -- 本次处理后血条应有状态：true=隐藏 / false=显示 / nil=不处理
	if UnitCanAttack("player", self.unit) then
		TextureLoadingGroupMixin.RemoveTexture({ textures = self }, "showOnlyName")
		if castBar then
			TextureLoadingGroupMixin.RemoveTexture({ textures = castBar }, "showOnlyName")
			TextureLoadingGroupMixin.RemoveTexture({ textures = castBar }, "widgetsOnly")
		end
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.HealthBarsContainer.healthBar }, "showOnlyName")
		TextureLoadingGroupMixin.RemoveTexture({ textures = self.ClassificationFrame }, "showOnlyName")
		if self.healthBar then
			pcall(function()
				self.healthBar:Hide()
				self.healthBar:Show()
			end)
		end
		if castBar and (UnitCastingInfo(self.unit) ~= nil or UnitChannelInfo(self.unit) ~= nil) then
			pcall(function()
				castBar:Show()
			end)
		end
		hidden = false
	elseif not self:IsPlayer() and (self:IsForbidden() or not UnitCanAttack("player", self.unit)) then
		TableUtil.TrySet(self, "showOnlyName")
		if castBar then
			TableUtil.TrySet(castBar, "showOnlyName")
			TableUtil.TrySet(castBar, "widgetsOnly")
		end
		TableUtil.TrySet(self.HealthBarsContainer.healthBar, "showOnlyName")
		TableUtil.TrySet(self.ClassificationFrame, "showOnlyName")
		TableUtil.TrySet(self.optionTable, "colorNameBySelection")
		--如果非保护并且有血条,直接执行隐藏
		if not self:IsForbidden() and self.healthBar then
			pcall(function()
				self.healthBar:Hide()
			end)
		end
		hidden = true
	end

	--血条显隐真的变了才重排，避免每次 UpdateShowOnlyName 都跑一遍 SetPoints
	if hidden ~= nil and self.PC_BarHidden ~= hidden then
		self.PC_BarHidden = hidden
		ns.SetPoints(self)
	end
end

ns.hook(NamePlateUnitFrameMixin, "UpdateShowOnlyName", function(self)
	TrySetOnlyName(self)
	C_Timer.After(0.1, function()
		TrySetOnlyName(self)
	end)
end)

local function OnUnitFlagsChanged(event, unit)
	if not unit or not PlateColorDB.onlyNameNpc then return end
	if not string.match(unit,"nameplate") then return end
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit, false)
	if nameplate and nameplate.UnitFrame then
		C_Timer.After(0.1, function()
			TrySetOnlyName(nameplate.UnitFrame)
		end)
	end
end

ns.event("UNIT_FLAGS", OnUnitFlagsChanged)
ns.event("UNIT_FACTION", OnUnitFlagsChanged)