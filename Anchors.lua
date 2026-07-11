local _, ns = ...

-- PTR 12.1: castBar 移到了 CastBarsContainer 下
function ns.GetCastBar(unitFrame)
	return unitFrame.CastBarsContainer and unitFrame.CastBarsContainer.castBar or unitFrame.castBar
end

-- 设置位域 CVar 的单个位（读当前掩码→改指定位→写回）用于下拉菜单的多选cvar
local function SetBitCVar(cvar, enumValue, enabled)
	local mask = 0
	for i = 1, 8 do
		if CVarCallbackRegistry:GetCVarBitfieldIndex(cvar, i) then
			mask = bit.bor(mask, bit.lshift(1, i - 1))
		end
	end
	if enabled then
		mask = bit.bor(mask, bit.lshift(1, enumValue - 1))
	else
		mask = bit.band(mask, bit.bnot(bit.lshift(1, enumValue - 1)))
	end
	CVarCallbackRegistry:SetCVarBitfieldMask(cvar, mask)
end

-- 姓名板尺寸修改
local function IsPetTrashScale(unit)
	if not unit then return false end
	-- 缩小玩家的宠物
	if UnitIsOtherPlayersPet(unit) and not UnitIsPlayer(unit) then
		return 0.75
	end
	return false
end

function ns.SetSelectedScale()
	if InCombatLockdown() then return end
	C_CVar.SetCVar("nameplateLargerScale", 1.2)	--精英
	C_CVar.SetCVar("namePlateMinScale", 1)	--距离缩放
	C_CVar.SetCVar("namePlateMaxScale", 1)	--距离缩放
	C_CVar.SetCVar("nameplateSelectedScale",PlateColorDB.SelectedScale)--目标尺寸
	C_CVar.SetCVar("nameplateOccludedAlphaMult",PlateColorDB.wallAlpha)--隔墙透明度
	C_CVar.SetCVar("nameplateMaxAlpha", PlateColorDB.allNpAlpha)--非当前目标透明度
	C_CVar.SetCVar("nameplateMinAlpha", PlateColorDB.allNpAlpha)--非当前目标透明度
	C_CVar.SetCVar("nameplateOverlapV", PlateColorDB.npOverlapV)--垂直堆叠间距
	C_CVar.SetCVar("nameplateOverlapH", PlateColorDB.npOverlapH)--水平堆叠间距
	C_CVar.SetCVar("nameplateMaxDistance", PlateColorDB.npRange)--姓名版可见范围

	
	--启用NPC名字模式时,关闭友方NPC简化姓名板
	if PlateColorDB.onlyNameNpc then
		SetBitCVar("nameplateSimplifiedTypes",Enum.NamePlateSimplifiedType.FriendlyNpc, false)
	end
	--启用友方玩家名字模式时,关闭友方玩家简化姓名板
	if PlateColorDB.onlyName then
		SetBitCVar("nameplateSimplifiedTypes",Enum.NamePlateSimplifiedType.FriendlyPlayer, false)
	end
	--去掉血量百分比因为我们自己创建了
	SetBitCVar("nameplateInfoDisplay",Enum.NamePlateInfoDisplay.CurrentHealthPercent, false)
	--去掉血量数值因为我们自己创建了
	SetBitCVar("nameplateInfoDisplay",Enum.NamePlateInfoDisplay.CurrentHealthValue, false)

	--友方玩家名字模式
	C_CVar.SetCVar("nameplateShowOnlyNameForFriendlyPlayerUnits",PlateColorDB.onlyName and 1 or 0)
	--友方玩家名字模式使用职业颜色
	C_CVar.SetCVar("nameplateUseClassColorForFriendlyPlayerUnitNames",PlateColorDB.onlyNameClassColor and 1 or 0)
	--12.1取消友方玩家的服务器名称显示
	C_CVar.SetCVar("nameplateShowFriendlyRealmName",0)
	--取消服务器名称显示12.0.1 (66384)
	if TextureLoadingGroupMixin and NamePlateFriendlyFrameOptions then
		TextureLoadingGroupMixin.RemoveTexture({ textures = NamePlateFriendlyFrameOptions }, "updateNameUsesGetUnitName")
	end
	if InCombatLockdown() then return end
	C_CVar.SetCVar("UnitNameFriendlyPlayerName", C_CVar.GetCVar("UnitNameFriendlyPlayerName"))--调用一次刷新设置
end
ns.event("PLAYER_ENTERING_WORLD", ns.SetSelectedScale)

-- 全局姓名板点击范围（只设一次即可）
function ns.UpdateGlobalHitInsets()
	if InCombatLockdown() then return end
	if PlateColorDB.HitHelp then
		C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Friendly, 10000, 10000, 10000, 10000)
	else
		C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Friendly, -PlateColorDB.HitWidth, -PlateColorDB.HitWidth, -PlateColorDB.HitHeight, -PlateColorDB.HitBottom)
	end
	C_NamePlateManager.SetNamePlateHitTestInsets(Enum.NamePlateType.Enemy, -PlateColorDB.HitWidth, -PlateColorDB.HitWidth, -PlateColorDB.HitHeight, -PlateColorDB.HitBottom)
end
ns.event("PLAYER_ENTERING_WORLD", ns.UpdateGlobalHitInsets)

-- 选项变更时同时刷新全局+单个姓名板
function ns.RefreshHitSettings(self)
	ns.UpdateGlobalHitInsets()
	ns.SetPoints(self)
end

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
	
	self.HealthBarsContainer.healthBar.bgTexture:SetTexture("Interface\\Addons\\PlateColor\\texture\\bgTexture.png")
	self.HealthBarsContainer.healthBar.bgTexture:SetPoint("TOPLEFT", -1 , 1)
	self.HealthBarsContainer.healthBar.bgTexture:SetPoint("BOTTOMRIGHT", 1 , -1)
	self.HealthBarsContainer.healthBar.bgTexture:SetAlpha(PlateColorDB.hpbgAlpha)
	ns.BorderSetting(self.HealthBarsContainer,self.HealthBarsContainer.healthBar.selectedBorder)
	ns.BorderSetting(self.HealthBarsContainer,self.HealthBarsContainer.healthBar.deselectedOverlay)
	self.HealthBarsContainer.healthBar.deselectedOverlay:SetVertexColor(0, 0, 0, 1)
	

	local namePlateFrame = self:GetNamePlateFrame()
	if not self.HitTestClipFrame then
		self.HitTestClipFrame = CreateFrame("Frame", nil, namePlateFrame)
		self.HitTestClipFrame:SetAllPoints(namePlateFrame)
		self.HitTestClipFrame:SetClipsChildren(true)
		self.HitTestClipFrame:EnableMouse(false)
	end
	if not self.HitTestFrameShow then
		self.HitTestFrameShow = self.HitTestClipFrame:CreateTexture(nil, "OVERLAY")
		self.HitTestFrameShow:SetTexture("Interface\\Addons\\PlateColor\\texture\\HitTexture.png")
		self.HitTestFrameShow:SetAlpha(0.8)
	end
	local extraXOffset = 10
	local extraYOffset = NamePlateSetupOptions.healthBarHeight / 2
	self.HitTestFrameShow:ClearAllPoints()
	self.HitTestFrameShow:SetPoint(
		"TOPLEFT",
		self.HealthBarsContainer.healthBar,
		"TOPLEFT",
		-PlateColorDB.HitWidth - extraXOffset,
		PlateColorDB.HitHeight + extraYOffset
	)
	self.HitTestFrameShow:SetPoint(
		"BOTTOMRIGHT",
		self.HealthBarsContainer.healthBar,
		"BOTTOMRIGHT",
		PlateColorDB.HitWidth + extraXOffset,
		-PlateColorDB.HitBottom - extraYOffset
	)
	self.HitTestFrameShow:SetShown(PlateColorDB.HitTestShow and (not self:IsFriend() or not PlateColorDB.HitHelp))

	-- 单个姓名板点击区域（与 HitTestFrameShow 视觉范围同步）
	if not InCombatLockdown() then
		if self:IsFriend() and PlateColorDB.HitHelp then
			namePlateFrame:ClearAllHitTestPoints()
		else
			namePlateFrame:SetHitTestPoints({
				{ point = "TOPLEFT",     relativeTo = self.HealthBarsContainer.healthBar,
				  relativePoint = "TOPLEFT",     offsetX = -PlateColorDB.HitWidth - extraXOffset,
				  offsetY =  PlateColorDB.HitHeight + extraYOffset },
				{ point = "BOTTOMRIGHT", relativeTo = self.HealthBarsContainer.healthBar,
				  relativePoint = "BOTTOMRIGHT", offsetX =  PlateColorDB.HitWidth + extraXOffset,
				  offsetY = -PlateColorDB.HitBottom - extraYOffset },
			})
		end
	end
	
	self.name:ClearAllPoints();
	self.HealthBarsContainer:ClearAllPoints();
	local castBar = ns.GetCastBar(self)
	if castBar then
		castBar:ClearAllPoints();
		castBar.Text:ClearAllPoints();
		castBar.Icon:ClearAllPoints();
		castBar.BorderShield:ClearAllPoints();
		castBar.CastTargetNameText:ClearAllPoints();
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
	--标记位置
	if self.RaidTargetFrame then
		self.RaidTargetFrame:SetScale(PlateColorDB.markScale)
		self.RaidTargetFrame:ClearAllPoints();
		if self:IsShowOnlyName() then
			PixelUtil.SetPoint(self.RaidTargetFrame, "BOTTOM", self.name, "TOP", 0, 10);
		else
			PixelUtil.SetPoint(self.RaidTargetFrame, "BOTTOM", self.HealthBarsContainer, "CENTER", PlateColorDB.markHoffset, PlateColorDB.markVoffset - 2);
		end
	end
	if self.ClassificationFrame then
		self.ClassificationFrame:ClearAllPoints();
		PixelUtil.SetPoint(self.ClassificationFrame, "RIGHT", self.HealthBarsContainer, "LEFT", 0, 0);
	end

	local hpWidht = PlateColorDB.hpWidht
	local hpHeight = PlateColorDB.hpHeight
	local nameScale = PlateColorDB.nameScale
	local castBarHeight = PlateColorDB.castBarHeight
	local castTextScales = PlateColorDB.castTextScale
	local castTargetScales = PlateColorDB.castTargetScale
	
	--部分需要尺寸调节（其他玩家的宠物）
	local TrashScale = IsPetTrashScale(self.unit)
	if TrashScale then
		local Trashscale = TrashScale
		hpWidht = hpWidht - 80 * (1 - Trashscale)
		hpHeight = hpHeight * Trashscale
		nameScale = nameScale * Trashscale
		castBarHeight = castBarHeight * Trashscale
		castTextScales = castTextScales * Trashscale
		castTargetScales = castTargetScales * Trashscale
	end

	if self:IsPlayer() then
		self.name:SetFontObject("PC_FontOutline")
		self.name:SetFontHeight(PlateColorDB.helpNameScale)
	elseif self.unit and not UnitCanAttack("player",self.unit) then
		self.name:SetFontObject("PC_Font")
		self.name:SetFontHeight(PlateColorDB.helpNameScale*0.9)
	else
		if PlateColorDB.nameOUTLINE then
			self.name:SetFontObject("PC_FontOutline")
		else
			self.name:SetFontObject("PC_Font")
		end
		self.name:SetFontHeight(nameScale)
	end
	self.name:SetSmoothScaling(false)

	local castBar = ns.GetCastBar(self)
	-- 血条左下对准左下、右上对准右下。Y 偏移已加施法条高度,1+是让血条和施法条有间隙,保持施法条底部在UnitFrame底部
	PixelUtil.SetPoint(self.HealthBarsContainer, "BOTTOMLEFT", self, "BOTTOMLEFT", -hpWidht+50, 1+castBarHeight);
	PixelUtil.SetPoint(self.HealthBarsContainer, "TOPRIGHT", self, "BOTTOMRIGHT", hpWidht-50, 1+castBarHeight + hpHeight);
	if castBar then
		PixelUtil.SetPoint(castBar, "BOTTOMLEFT", self, "BOTTOMLEFT", -hpWidht+50, 0);
		PixelUtil.SetPoint(castBar, "TOPRIGHT", self, "BOTTOMRIGHT", hpWidht-50, castBarHeight);
		PixelUtil.SetHeight(castBar.Spark,castBarHeight*2)--施法闪光高度
		if PlateColorDB.castIconBig then
			local bigsize = castBarHeight+hpHeight+2
			PixelUtil.SetSize(castBar.Icon,bigsize,bigsize)--施法图标大
			PixelUtil.SetSize(castBar.BorderShield,bigsize*0.9,bigsize)--不可打断的盾牌
		else
			PixelUtil.SetSize(castBar.Icon,castBarHeight,castBarHeight)--施法图标小
			PixelUtil.SetSize(castBar.BorderShield,castBarHeight*0.9,castBarHeight) --不可打断的盾牌
		end
		PixelUtil.SetPoint(castBar.Icon,"BOTTOMRIGHT", castBar, "BOTTOMLEFT", -1, 0);	--施法图标位置
		PixelUtil.SetPoint(castBar.BorderShield,"BOTTOMRIGHT", castBar, "BOTTOMLEFT", -1, 0);--不可打断的盾牌

		castBar.Text:SetFontObject("PC_FontOutline");--施法文本尺寸
		castBar.Text:SetFontHeight(castTextScales)
		castBar.Text:SetSmoothScaling(false)
		castBar.CastTargetNameText:SetFontObject("PC_FontOutline");--施法目标尺寸
		castBar.CastTargetNameText:SetFontHeight(castTargetScales)
		castBar.CastTargetNameText:SetSmoothScaling(false)
		
		if PlateColorDB.castPoint == 1 then --左
			PixelUtil.SetPoint(castBar.Text,"LEFT", castBar, "LEFT", 0, 0);--施法文本位置
		elseif PlateColorDB.castPoint == 2 then--中
			PixelUtil.SetPoint(castBar.Text,"CENTER", castBar, "CENTER", 0, 0);--施法文本位置
		end
		if PlateColorDB.castTargetPoint == 1 then--右侧内部
			PixelUtil.SetPoint(castBar.CastTargetNameText,"RIGHT", castBar, "RIGHT", 1, -1); --施法目标名字
		elseif PlateColorDB.castTargetPoint == 2 then--右侧外部
			PixelUtil.SetPoint(castBar.CastTargetNameText,"BOTTOMLEFT", castBar, "BOTTOMRIGHT", 1, -1); --施法目标名字
		elseif PlateColorDB.castTargetPoint == 3 then--右侧中
			PixelUtil.SetPoint(castBar.CastTargetNameText,"LEFT", self.HealthBarsContainer.healthBar, "RIGHT", 1, -1); --施法目标名字
		elseif PlateColorDB.castTargetPoint == 4 then--右上
			PixelUtil.SetPoint(castBar.CastTargetNameText,"BOTTOMLEFT", self.HealthBarsContainer.healthBar, "TOPRIGHT", -8, -1); --施法目标名字
		end
		--创建施法剩余时间文本
		if not castBar.PCCastTimeText then
			castBar.PCCastTimeText = castBar:CreateFontString(nil)
		end
		castBar.PCCastTimeText:ClearAllPoints();
		if PlateColorDB.castTargetPoint == 1 then
			castBar.PCCastTimeText:SetPoint("LEFT", castBar, "RIGHT", 0, 0)
		else
			castBar.PCCastTimeText:SetPoint("RIGHT", castBar, "RIGHT", 0, 0)
		end
		castBar.PCCastTimeText:SetFontObject("PC_FontOutline")	--施法时间文字大小
		castBar.PCCastTimeText:SetFontHeight(castTextScales*1.1)
		castBar.PCCastTimeText:SetSmoothScaling(false)
	end
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
		self.healthBar.PCText:SetSmoothScaling(false)
	end
	self.healthBar.PCText:SetFontObject("PC_FontOutline");
	self.healthBar.PCText:SetFontHeight(PlateColorDB.HpTextScale1);
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

ns.hook(NamePlateUnitFrameMixin,"OnUnitFactionChanged", function(self)
	ns.SetPoints(self)
end)
ns.hook(NamePlateUnitFrameMixin,"UpdateAnchors", function(self)
	ns.SetPoints(self)
end)

--生命值文本
ns.hook(NamePlateHealthBarMixin,"UpdateTextStringWithValues", function(self,textString, value, valueMin, valueMax)
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
		--self.PCText:SetText(string.format("%d%%", HealthPercent))
		self.PCText:SetText(string.format("%s", ns.percent(HealthPercent)))
	end
end)

--[[自定义分类图标显示逻辑：绕过 Blizzard 的 raidTargetIndex 隐藏检查
local function PC_GetClassificationAtlas(unitToken)
	if not unitToken then return nil end
	local classification = UnitClassification(unitToken)
	if classification == "elite" or classification == "worldboss" then
		return "nameplates-icon-elite-gold"
	elseif classification == "rare" then
		return "UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Star"
	elseif classification == "rareelite" then
		return "nameplates-icon-elite-silver"
	end
	return nil
end

--接管显示：Blizzard 因 raidTargetIndex 清掉了 atlas，我们重新设置
ns.hook(NamePlateClassificationFrameMixin, "UpdateShownState", function(self)
	if self:IsForbidden() then return end
	if not self.unitToken then return end
	if self:IsShowOnlyName() then return end
	if self:IsWidgetsOnlyMode() then return end

	if self.raidTargetIndex and not self.classificationAtlasElement then
		local atlas = PC_GetClassificationAtlas(self.unitToken)
		if atlas then
			self.classificationAtlasElement = atlas
			self.classificationIndicator:SetAtlas(atlas)
			self:Show()
		end
	end
end)]]