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

    -- --- 核心拦截点 ---
    -- 施法正常完成后，我们不再通过这个函数覆盖颜色，交给系统原生的淡出处理
    if event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP" then return end
    -- ----------------

    -- 只有在施法进行中或失败时，才执行下方的颜色覆盖
    local currentFalseColor = colorYellow
    if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
        currentFalseColor = colorRed
    elseif self.channeling then
        currentFalseColor = colorGreen
    end

	local _, _, _, _, _, _, _, CastType = UnitCastingInfo(self.unit)
	local BarType = CastType
	if BarType == nil then
		local _, _, _, _, _, _, ChannelType = UnitChannelInfo(self.unit)
		BarType = ChannelType
	end
	if BarType == nil then
		BarType = false
	end

    local barTexture = self:GetStatusBarTexture()
    if barTexture then
        barTexture:SetVertexColorFromBoolean(BarType, trueColor, currentFalseColor)
    end
end
ns.hook(NamePlateCastingBarMixin,"OnEvent",SetPlateCastBar)
ns.event("NAME_PLATE_UNIT_ADDED", function(event, unit)
	local namePlate = C_NamePlate.GetNamePlateForUnit(unit,false)
	local unitFrame = namePlate.UnitFrame
	if unitFrame.castBar then
		SetPlateCastBar(unitFrame.castBar)
	end
end)
ns.hook(NamePlateCastingBarMixin,"FinishSpell",function(self)
	if self:IsForbidden() then return end
	if not self.unit then return end
	if PlateColorDB.castTexture == "Blizzard-default" then return end--选择了原版材质就用默认的
	self:SetStatusBarTexture(ns.HpTextures[PlateColorDB.castTexture])
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