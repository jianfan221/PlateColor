local _, ns = ...

--施法条
local trueColor = CreateColor(0.6,0.6,0.6)--不可打断
local colorYellow = CreateColor(0.9,0.9,0) -- 施法中
local colorGreen = CreateColor(0, 1, 0)  -- 引导中
local colorRed = CreateColor(1, 0, 0, 1)    -- 失败/打断

--设置施法条颜色
function ns.SetCastBarInitColor()
	trueColor:SetRGB(PlateColorDB.nointerrupcolor.r, PlateColorDB.nointerrupcolor.g, PlateColorDB.nointerrupcolor.b)
	colorYellow:SetRGB(PlateColorDB.castcolor.r, PlateColorDB.castcolor.g, PlateColorDB.castcolor.b)
	colorGreen:SetRGB(PlateColorDB.channelcolor.r, PlateColorDB.channelcolor.g, PlateColorDB.channelcolor.b)
end
ns.event("PLAYER_ENTERING_WORLD", ns.SetCastBarInitColor)

local function SetPlateCastBar(self, event)
    if event == "PLAYER_ENTERING_WORLD" then return end
    if self:IsForbidden() or not self.unit then return end

    --选择了原版材质就用默认的
    if PlateColorDB.castTexture == "Blizzard-default" then return end

	--设定施法条材质和背景
	self:SetStatusBarTexture(ns.HpTextures[PlateColorDB.castTexture])
    self.Background:SetTexture(130937)
    self.Background:SetVertexColor(0.1, 0.1, 0.1, 0.9)

	--获取施法条材质用于设置颜色
	local barTexture = self:GetStatusBarTexture()
	if not barTexture then return end

	-- 失败/中断直接设红色并返回，不走后续颜色逻辑
	if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
		barTexture:SetVertexColor(colorRed:GetRGB())
		return
	end
	-- UNIT_SPELLCAST_STOP 会和失败中断同时触发,避免污染失败中断的红色直接返回
	if event == "UNIT_SPELLCAST_STOP" then
        return
    end

    -- 默认读条使用黄色,如果是引导使用绿色,中断状态是false时使用这里的颜色
    local currentFalseColor = colorYellow
    if event == "UNIT_SPELLCAST_CHANNEL_START" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        currentFalseColor = colorGreen
    end

	-- 在可能改变可中断状态的事件时更新缓存，结束时 API 已返回 nil 不再重新查
	if event == "NAME_PLATE_UNIT_ADDED"
	   or event == "UNIT_SPELLCAST_START"
	   or event == "UNIT_SPELLCAST_CHANNEL_START"
	   or event == "UNIT_SPELLCAST_EMPOWER_START"
	   or event == "UNIT_SPELLCAST_INTERRUPTIBLE"
	   or event == "UNIT_SPELLCAST_NOT_INTERRUPTIBLE" then
		local _, _, _, _, _, _, _, CastType = UnitCastingInfo(self.unit)
		self.IsBarType = CastType
		if self.IsBarType == nil then
			local _, _, _, _, _, _, ChannelType = UnitChannelInfo(self.unit)
			self.IsBarType = ChannelType
		end
		if self.IsBarType == nil then
			self.IsBarType = false
		end
	end
	if self.IsBarType == nil then return end
	--可中断信息是秘密值,self.IsBarType == true时使用trueColor
    barTexture:SetVertexColorFromBoolean(self.IsBarType, trueColor, currentFalseColor)
end
ns.hook(NamePlateCastingBarMixin,"OnEvent",SetPlateCastBar)
ns.hook(NamePlateCastingBarMixin,"FinishSpell", SetPlateCastBar)
if NamePlateCastingBarMixin.UpdateBarFillTexture then
	ns.hook(NamePlateCastingBarMixin, "UpdateBarFillTexture", SetPlateCastBar)
end
ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	local castBar = ns.GetCastBar(unitFrame)
	if castBar then
		SetPlateCastBar(castBar, event)
	end
end)

--施法时间,获取施法剩余时间API抄的Platynator\Display\CastTimeText.lua
ns.hook(NamePlateCastingBarMixin,"OnUpdate", function(self,elapsed)
	if not PlateColorDB.castTime then 
		if self.PCCastTimeText then
			self.PCCastTimeText:SetText("")
		end
		return 
	end
	if not self then return end
	if not self.unit then return end
	if self:IsForbidden() then return end
	if not self.PCCastTimeText then return end
	
	if self.casting and UnitCastingDuration and UnitCastingDuration(self.unit) then
		self.PCCastTimeText:SetText(string.format("%.1f", UnitCastingDuration(self.unit):GetRemainingDuration()))
	elseif self.channeling and UnitChannelDuration and UnitChannelDuration(self.unit) then
		self.PCCastTimeText:SetText(string.format("%.1f", UnitChannelDuration(self.unit):GetRemainingDuration()))
	end
end)