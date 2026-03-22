local _, ns = ...

if 1 ~= 0 then return end


local function SetAura(self,unitAuraUpdateInfo)
	if ns.MM(self) then return end
	if self:IsForbidden() then return end
	
	if self.isActive == false then
		return;
	end

	local isFriend = self:IsFriend();

	local function BuffCompare(a, b)
		return a.auraInstanceID < b.auraInstanceID;
	end

	local aurasChanged = false;
	if unitAuraUpdateInfo == nil or unitAuraUpdateInfo.isFullUpdate or self.buffList == nil then
		if self.DOT == nil then
			self.DOT = TableUtil.CreatePriorityTable(BuffCompare, TableUtil.Constants.AssociativePriorityTable);
		else
			self.DOT:Clear();
		end

		for _index, aura in ipairs(C_UnitAuras.GetUnitAuras(self.unitToken, 'HARMFUL|PLAYER', nil)) do
			if self:IsFriend() == false then
				if not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unitToken, aura.auraInstanceID,'HARMFUL|PLAYER')
					or C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unitToken, aura.auraInstanceID,'HARMFUL|INCLUDE_NAME_PLATE_ONLY') then
					self.DOT[aura.auraInstanceID] = aura
				end
			end
		end
		aurasChanged = true;
	else
		if unitAuraUpdateInfo.addedAuras ~= nil then
			local checkFilters = true;
			for _, aura in ipairs(unitAuraUpdateInfo.addedAuras) do
				if self:IsFriend() == false then
					if not C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unitToken, aura.auraInstanceID,'HARMFUL|PLAYER')
					or C_UnitAuras.IsAuraFilteredOutByInstanceID(self.unitToken, aura.auraInstanceID,'HARMFUL|INCLUDE_NAME_PLATE_ONLY') then
						self.DOT[aura.auraInstanceID] = aura
					end
					aurasChanged = true
				end
			end
		end

		if unitAuraUpdateInfo.updatedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.updatedAuraInstanceIDs) do
				if self.DOT[auraInstanceID] ~= nil then
					local newAura = C_UnitAuras.GetAuraDataByAuraInstanceID(self.unitToken, auraInstanceID);
					if newAura then
					self.DOT[auraInstanceID] = newAura;
					aurasChanged = true
					end
				end
			end
		end

		if unitAuraUpdateInfo.removedAuraInstanceIDs ~= nil then
			for _, auraInstanceID in ipairs(unitAuraUpdateInfo.removedAuraInstanceIDs) do
				if self.DOT[auraInstanceID] ~= nil then
					self.DOT[auraInstanceID] = nil
					aurasChanged = true
				end
			end
		end
	end
	

	if aurasChanged == true then
		if not self.DOTFramePool then
			local function auraItemFrameResetCallback(pool, auraItemFrame)
				Pool_HideAndClearAnchors(pool, auraItemFrame)
				auraItemFrame.layoutIndex = nil
				auraItemFrame:Hide()
			end
			self.DOTFramePool = CreateFramePool("FRAME", self:GetParent():GetParent().UnitFrame, "NameplateAuraItemTemplate", auraItemFrameResetCallback)
		end
		if not self.DOTFrame then
			self.DOTFrame = CreateFrame("Frame", nil, self:GetParent():GetParent().UnitFrame)
			self.DOTFrame:SetAllPoints(self.DebuffListFrame)
			
			-- 锚点保持不变
			--self.DOTFrame:SetSize(100, 30) -- 只要一个点作为参考
			--self.DOTFrame:SetPoint("BOTTOMLEFT", self:GetParent():GetParent().UnitFrame.HealthBarsContainer.healthBar, "TOPLEFT", 0, 20)
		end
		self.DOTFramePool:ReleaseAll();
		
		local auraIndex = 0 -- 从 0 开始方便计算偏移
		local ICON_SIZE = 30  -- 图标大小
		local SPACING = 0 -- 间距

		self.DOT:Iterate(function(auraInstanceID, aura)
			
			local auraItemFrame = self.DOTFramePool:Acquire();
			auraItemFrame.layoutIndex = auraIndex;
			auraItemFrame:SetScale(self.auraItemScale);
			auraItemFrame:SetUnit(self.unitToken);
			auraItemFrame:SetParent(self.DOTFrame);
			auraItemFrame:Show();
			
			auraItemFrame:ClearAllPoints()
			auraItemFrame:SetPoint("BOTTOMLEFT", self.DOTFrame, "BOTTOMLEFT", auraIndex * (ICON_SIZE + SPACING), 0)
			auraItemFrame:SetSize(ICON_SIZE, ICON_SIZE)
			
			auraItemFrame.auraInstanceID = aura.auraInstanceID;
			auraItemFrame.isBuff = aura.isHelpful;
			auraItemFrame.spellID = aura.spellId;
			auraItemFrame.Icon:SetTexture(aura.icon);
			auraItemFrame.CountFrame.Count:SetText(C_StringUtil.TruncateWhenZero(aura.applications));
			auraItemFrame.Cooldown:SetCooldownFromExpirationTime(aura.expirationTime,aura.duration,aura.timeMod)
			auraItemFrame.Cooldown:SetHideCountdownNumbers(false);
			
			auraIndex = auraIndex + 1;
			return auraIndex > 5;
		end);
	end
end
hooksecurefunc(NamePlateAurasMixin,"RefreshAuras",SetAura)
