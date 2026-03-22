local _, ns = ...

local SimplifiedTypes = {--简化姓名版包含友方玩家的选项转换为不包含友方玩家防止副本内不显示
["D"] = "",
["H"] = "",
["L"] = "",
}

function ns.SetSelectedScale()
	if InCombatLockdown() then return end
	C_CVar.SetCVar("nameplateLargerScale", 1.2)	--精英
	SetCVar("namePlateMinScale", 1)	--距离缩放
	SetCVar("namePlateMaxScale", 1)	--距离缩放
	C_CVar.SetCVar("nameplateSelectedScale",PlateColorDB.SelectedScale)--目标尺寸
	C_CVar.SetCVar("nameplateOccludedAlphaMult",PlateColorDB.wallAlpha)--隔墙透明度
	C_CVar.SetCVar("nameplateMaxAlpha", PlateColorDB.allNpAlpha)--非当前目标透明度
	C_CVar.SetCVar("nameplateMinAlpha", PlateColorDB.allNpAlpha)--非当前目标透明度
	C_CVar.SetCVar("nameplateOverlapV", PlateColorDB.npOverlapV)--垂直堆叠间距
	C_CVar.SetCVar("nameplateOverlapH", PlateColorDB.npOverlapH)--水平堆叠间距
	C_CVar.SetCVar("nameplateMaxDistance", PlateColorDB.npRange)--姓名版可见范围
	
	if (PlateColorDB.onlyName or PlateColorDB.onlyNameNpc) and SimplifiedTypes[C_CVar.GetCVar("nameplateSimplifiedTypes")] then
		C_CVar.SetCVar("nameplateSimplifiedTypes",SimplifiedTypes[C_CVar.GetCVar("nameplateSimplifiedTypes")])--去除友方玩家姓名版选项防止副本内不显示
	end
	if C_CVar.GetCVar("nameplateInfoDisplay") ~="" and C_CVar.GetCVar("nameplateInfoDisplay") ~="D" then
		C_CVar.SetCVar("nameplateInfoDisplay","D")--去掉血量百分比显示
	end
	if C_CVar.GetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits") then
		local UseonlyName = PlateColorDB.onlyName and 1 or 0
		C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits",UseonlyName)--友方玩家只显示名字
	end
	if C_CVar.GetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames") then
		local UseClassColor = PlateColorDB.onlyNameClassColor and 1 or 0
		C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames",UseClassColor)--友方玩家名字使用职业颜色
	end
	if TextureLoadingGroupMixin and NamePlateFriendlyFrameOptions then--取消服务器名称显示12.0.1 (66384)
		TextureLoadingGroupMixin.RemoveTexture({ textures = NamePlateFriendlyFrameOptions }, "updateNameUsesGetUnitName")
	end
	if InCombatLockdown() then return end
	SetCVar("UnitNameFriendlyPlayerName", GetCVar("UnitNameFriendlyPlayerName"))--调用一次刷新设置
end
ns.event("PLAYER_ENTERING_WORLD", ns.SetSelectedScale)

function ns.SetPoints(self)
	if not self then return end
	if not self.unit then return end
	if self:IsForbidden() then return end
	--血条材质
	if ns.HpTextures[PlateColorDB.hpbarTexture] then 
		self.HealthBarsContainer.healthBar:SetStatusBarTexture(ns.HpTextures[PlateColorDB.hpbarTexture])
	else
		self.HealthBarsContainer.healthBar:SetStatusBarTexture(ns.HpTextures["PC-White"])
	end
	--边框和背景
	if PlateColorDB.hpBorder then
		self.HealthBarsContainer.healthBar.bgTexture:SetTexture("Interface\\Addons\\PlateColor\\texture\\bgTexture.png")
		self.HealthBarsContainer.healthBar.bgTexture:SetPoint("TOPLEFT", -1 , 1)
		self.HealthBarsContainer.healthBar.bgTexture:SetPoint("BOTTOMRIGHT", 1 , -1)
		self.HealthBarsContainer.healthBar.selectedBorder:SetTexture("Interface\\Addons\\PlateColor\\texture\\selectedBorder.png")
		self.HealthBarsContainer.healthBar.selectedBorder:SetPoint("TOPLEFT", -2, 1)
		self.HealthBarsContainer.healthBar.selectedBorder:SetPoint("BOTTOMRIGHT", 2, -1)
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetTexture("Interface\\Addons\\PlateColor\\texture\\deselectedOverlay.png")
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetPoint("TOPLEFT", -2, 1)
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetPoint("BOTTOMRIGHT", 2, -1)
	else
		self.HealthBarsContainer.healthBar.bgTexture:SetAtlas("UI-HUD-CoolDownManager-Bar-BG")
		self.HealthBarsContainer.healthBar.bgTexture:SetPoint("TOPLEFT", -2 , 3)
		self.HealthBarsContainer.healthBar.bgTexture:SetPoint("BOTTOMRIGHT", 5 , -6)
		self.HealthBarsContainer.healthBar.selectedBorder:SetAtlas("UI-HUD-Nameplates-Selected")
		self.HealthBarsContainer.healthBar.selectedBorder:SetPoint("TOPLEFT",  -2, 3)
		self.HealthBarsContainer.healthBar.selectedBorder:SetPoint("BOTTOMRIGHT", 2, -3)
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetAtlas("ui-hud-nameplates-deselected-overlay")
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetPoint("TOPLEFT", 0, 1)
		self.HealthBarsContainer.healthBar.deselectedOverlay:SetPoint("BOTTOMRIGHT", 0, -1)
	end
	self.HealthBarsContainer.healthBar.bgTexture:SetAlpha(PlateColorDB.hpbgAlpha)

	if not self.HitTestFrameShow then
		self.HitTestFrameShow = self:CreateTexture(nil, "OVERLAY")
		self.HitTestFrameShow:SetTexture("Interface\\Addons\\PlateColor\\texture\\HitTexture.png")
		self.HitTestFrameShow:SetAlpha(0.8)
	end
	self.HitTestFrameShow:SetShown(PlateColorDB.HitTestShow)
	local setupOptions = NamePlateSetupOptions--暴雪的一些默认设置项
	if setupOptions.unitNameInsideHealthBar then
		local extraXOffset = 10;
		local extraYOffset = setupOptions.healthBarHeight / 2;
		self.HitTestFrameShow:SetPoint("TOPLEFT", self.HealthBarsContainer.healthBar, "TOPLEFT", -PlateColorDB.HitWidth-extraXOffset, PlateColorDB.HitHeight+extraYOffset);
		self.HitTestFrameShow:SetPoint("BOTTOMRIGHT", self.HealthBarsContainer.healthBar, "BOTTOMRIGHT", PlateColorDB.HitWidth+extraXOffset, -PlateColorDB.HitBottom-extraYOffset);
	else
		local extraXOffset = 10;
		local nameOffset = 4;
		local extraYOffset = setupOptions.healthBarHeight / 2;
		self.HitTestFrameShow:SetPoint("TOPLEFT", self.HealthBarsContainer.healthBar, "TOPLEFT", -PlateColorDB.HitWidth-extraXOffset - nameOffset, PlateColorDB.HitHeight+extraYOffset);
		self.HitTestFrameShow:SetPoint("BOTTOMRIGHT", self.HealthBarsContainer.healthBar, "BOTTOMRIGHT", PlateColorDB.HitWidth+extraXOffset, -PlateColorDB.HitBottom-extraYOffset);
	end
	if not InCombatLockdown() then
		if PlateColorDB.HitHelp and self:IsFriend() and not self.healthBar:IsShown() then
			self.HitTestFrameShow:Hide()
			C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Friendly, 10000, 10000, 10000, 10000)--左右上下
		else
			C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Friendly, -PlateColorDB.HitWidth, -PlateColorDB.HitWidth, -PlateColorDB.HitHeight, -PlateColorDB.HitBottom)
		end
		C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Enemy, -PlateColorDB.HitWidth, -PlateColorDB.HitWidth, -PlateColorDB.HitHeight, -PlateColorDB.HitBottom)
	end
	
	self.name:ClearAllPoints();
	self.HealthBarsContainer:ClearAllPoints();
	self.castBar:ClearAllPoints();
	self.castBar.Text:ClearAllPoints();
	self.castBar.Icon:ClearAllPoints();
	self.castBar.BorderShield:ClearAllPoints();
	self.castBar.CastTargetNameText:ClearAllPoints();
	
	if self:IsPlayer() then
		self.name:SetFont(self.name:GetFont(), PlateColorDB.helpNameScale,"OUTLINE");
	elseif self.unit and not UnitCanAttack("player",self.unit) then
		self.name:SetFont(self.name:GetFont(), PlateColorDB.helpNameScale*0.9, "SLUG");
	else
		self.name:SetFont(self.name:GetFont(), PlateColorDB.nameScale, PlateColorDB.nameOUTLINE and "OUTLINE,SLUG" or "SLUG");
	end
	--名字位置
	if not self.healthBar:IsShown() then
		if self.NpcFuntext and self.NpcFuntext:IsShown() then
			PixelUtil.SetPoint(self.name, "BOTTOM", self, "BOTTOM", 0, 15);
		else
			PixelUtil.SetPoint(self.name, "BOTTOM", self, "BOTTOM", 0, 0);
		end
		PixelUtil.SetPoint(self.name, "BOTTOM", self, "BOTTOM", 0, 10);
	elseif PlateColorDB.namePoint == 1 then--中上
		PixelUtil.SetPoint(self.name, "BOTTOM", self.HealthBarsContainer, "TOP", 0, PlateColorDB.nameVoffset+2);
	elseif PlateColorDB.namePoint == 2 then--左上
		PixelUtil.SetPoint(self.name, "BOTTOMLEFT", self.HealthBarsContainer, "TOPLEFT", 0, PlateColorDB.nameVoffset+2);
	elseif PlateColorDB.namePoint == 3 then--左中
		PixelUtil.SetPoint(self.name, "LEFT", self.HealthBarsContainer, "LEFT", 2, 0);
	elseif PlateColorDB.namePoint == 4 then--左下
		PixelUtil.SetPoint(self.name, "TOPLEFT", self.HealthBarsContainer, "BOTTOMLEFT", 0, PlateColorDB.nameVoffset-4);
	elseif PlateColorDB.namePoint == 5 then--中下
		PixelUtil.SetPoint(self.name, "TOP", self.HealthBarsContainer, "BOTTOM", 0, PlateColorDB.nameVoffset-4);
	end

	local hpWidht = PlateColorDB.hpWidht
	local hpHeight = PlateColorDB.hpHeight
	local castBarHeight = PlateColorDB.castBarHeight
	local castTextScales = PlateColorDB.castTextScale
	local castTargetScales = PlateColorDB.castTargetScale
	
	--部分需要尺寸调节
	if UnitIsOtherPlayersPet(self.unit) and not UnitIsPlayer(self.unit) then
		hpWidht = hpWidht-27
		hpHeight = hpHeight*0.7
		castBarHeight = castBarHeight*0.7
		castTextScales = castTextScales*0.7
		castTargetScales = castTargetScales*0.7
	end
	PixelUtil.SetPoint(self.castBar, "BOTTOMLEFT", self, "BOTTOMLEFT", -hpWidht+50, 0);--施法条宽度
	PixelUtil.SetPoint(self.castBar, "BOTTOMRIGHT", self, "BOTTOMRIGHT", hpWidht-50, 0);--施法条宽度
	PixelUtil.SetPoint(self.HealthBarsContainer, "BOTTOMLEFT", self.castBar, "TOPLEFT", 0, 2);--血条宽度跟随施法条
	PixelUtil.SetPoint(self.HealthBarsContainer, "BOTTOMRIGHT", self.castBar, "TOPRIGHT", 0, 2);--血条宽度跟随施法条
	PixelUtil.SetHeight(self.HealthBarsContainer, hpHeight);--血条高度
	PixelUtil.SetHeight(self.castBar,castBarHeight)--施法条高度
	PixelUtil.SetHeight(self.castBar.Spark,castBarHeight*2)--施法闪光高度
	if PlateColorDB.castIconBig then
		local bigsize = castBarHeight+hpHeight+3
		PixelUtil.SetSize(self.castBar.Icon,bigsize,bigsize)--施法图标大
		PixelUtil.SetSize(self.castBar.BorderShield,bigsize*0.9,bigsize)--不可打断的盾牌
	else
		PixelUtil.SetSize(self.castBar.Icon,castBarHeight,castBarHeight)--施法图标小
		PixelUtil.SetSize(self.castBar.BorderShield,castBarHeight*0.9,castBarHeight) --不可打断的盾牌
	end
	PixelUtil.SetPoint(self.castBar.Icon,"BOTTOMRIGHT", self.castBar, "BOTTOMLEFT", -2, 0);	--施法图标位置
	PixelUtil.SetPoint(self.castBar.BorderShield,"BOTTOMRIGHT", self.castBar, "BOTTOMLEFT", -2, 0);--不可打断的盾牌
	
	self.castBar.Text:SetFont(self.castBar.Text:GetFont(),castTextScales, "OUTLINE,SLUG");--施法文本尺寸
	self.castBar.CastTargetNameText:SetFont(self.castBar.CastTargetNameText:GetFont(),castTargetScales, "OUTLINE,SLUG");--施法目标尺寸
	
	if PlateColorDB.castPoint == 1 then --左
		PixelUtil.SetPoint(self.castBar.Text,"LEFT", self.castBar, "LEFT", 0, 0);--施法文本位置
	elseif PlateColorDB.castPoint == 2 then--中
		PixelUtil.SetPoint(self.castBar.Text,"CENTER", self.castBar, "CENTER", 0, 0);--施法文本位置
	end
	if PlateColorDB.castTargetPoint == 1 then--右侧内部
		PixelUtil.SetPoint(self.castBar.CastTargetNameText,"RIGHT", self.castBar, "RIGHT", 1, -1); --施法目标名字
	elseif PlateColorDB.castTargetPoint == 2 then--右侧外部
		PixelUtil.SetPoint(self.castBar.CastTargetNameText,"BOTTOMLEFT", self.castBar, "BOTTOMRIGHT", 1, -1); --施法目标名字
	elseif PlateColorDB.castTargetPoint == 3 then--右侧中
		PixelUtil.SetPoint(self.castBar.CastTargetNameText,"LEFT", self.HealthBarsContainer.healthBar, "RIGHT", 1, -1); --施法目标名字
	elseif PlateColorDB.castTargetPoint == 4 then--右上
		PixelUtil.SetPoint(self.castBar.CastTargetNameText,"BOTTOMLEFT", self.HealthBarsContainer.healthBar, "TOPRIGHT", -8, -1); --施法目标名字
	end
	--创建施法剩余时间文本
	if not self.castBar.PCCastTimeText then
		self.castBar.PCCastTimeText = self.castBar:CreateFontString(nil)
	end
	self.castBar.PCCastTimeText:ClearAllPoints();
	if PlateColorDB.castTargetPoint == 1 then
		self.castBar.PCCastTimeText:SetPoint("LEFT", self.castBar, "RIGHT", 0, 0)
	else
		self.castBar.PCCastTimeText:SetPoint("RIGHT", self.castBar, "RIGHT", 0, 0)
	end
	self.castBar.PCCastTimeText:SetFont(SystemFont_Outline_Small:GetFont(), castTextScales*1.1, "OUTLINE")	--施法时间文字大小
	----调节尺寸部分结束
	
	--隐藏和清除自带的生命值显示
	self.healthBar.Text:ClearAllPoints();
	self.healthBar.Text:Hide()
	self.healthBar.LeftText:ClearAllPoints();
	self.healthBar.LeftText:Hide()
	self.healthBar.RightText:ClearAllPoints();
	self.healthBar.RightText:Hide()
	if not self.healthBar.PCText then
		self.healthBar.PCText = self.healthBar:CreateFontString(nil, "OVERLAY")
		self.healthBar.PCText:SetVertexColor(1,1,1)
	end
	self.healthBar.PCText:SetFont(ns.fonts,PlateColorDB.HpTextScale1,"OUTLINE");
	self.healthBar.PCText:ClearAllPoints();
	if PlateColorDB.HpTextPoint == 1 then
		self.healthBar.PCText:SetPoint("LEFT", self.healthBar, "LEFT", PlateColorDB.HpTextHoffset+0, PlateColorDB.HpTextVoffset+0)
	elseif PlateColorDB.HpTextPoint == 2 then
		self.healthBar.PCText:SetPoint("CENTER",self.healthBar,"CENTER", PlateColorDB.HpTextHoffset+5, PlateColorDB.HpTextVoffset+0)
	elseif PlateColorDB.HpTextPoint == 3 then
		self.healthBar.PCText:SetPoint("RIGHT", self.healthBar, "RIGHT", PlateColorDB.HpTextHoffset+0, PlateColorDB.HpTextVoffset+0)
	end
	
	--重设debuff位置
	local debuffPadding = CVarCallbackRegistry:GetCVarNumberOrDefault(NamePlateConstants.DEBUFF_PADDING_CVAR);
	if PlateColorDB.namePoint == 3 or PlateColorDB.namePoint == 4 or PlateColorDB.namePoint == 5 then
		PixelUtil.SetPoint(self.AurasFrame.DebuffListFrame, "BOTTOM", self.HealthBarsContainer.healthBar, "TOP", 0, debuffPadding);
	else
		PixelUtil.SetPoint(self.AurasFrame.DebuffListFrame, "BOTTOM", self.name, "TOP", 0, debuffPadding);
	end

	
end

hooksecurefunc(NamePlateUnitFrameMixin,"OnUnitFactionChanged", function(self)
	ns.SetPoints(self)
end)
hooksecurefunc(NamePlateUnitFrameMixin,"UpdateAnchors", function(self)
	ns.SetPoints(self)
end)

--生命值文本
hooksecurefunc(NamePlateHealthBarMixin,"UpdateTextStringWithValues", function(self,textString, value, valueMin, valueMax)
	if self:IsForbidden() then return end
	if not self.PCText then return end
	if not self:GetParent():GetParent().unit then return end
	local HealthPercent = UnitHealthPercent(self:GetParent():GetParent().unit, true, CurveConstants.ScaleTo100)
	if PlateColorDB.hpValue and PlateColorDB.hpPercent then
		if PlateColorDB.delimiter == "( )" then
			self.PCText:SetText(string.format("%s(%d%%)", ns.value(value), HealthPercent))
		else
			self.PCText:SetText(string.format("%s%s%d%%", ns.value(value), PlateColorDB.delimiter,HealthPercent))
		end
	elseif PlateColorDB.hpValue then
		self.PCText:SetText(ns.value(value))
	elseif PlateColorDB.hpPercent then
		self.PCText:SetText(string.format("%d%%", HealthPercent))
	end
end)