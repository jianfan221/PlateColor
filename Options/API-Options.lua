local addonName,ns = ...
local L = ns.L

ns.Y = {}	--用于分页行数自动拓展

--创建主页面点击放大分类按钮
local tabbutton = {}
function ns.AddClickBC(parent,frame, id, width, text, xOffset, yOffset)
	local xOffset = xOffset or 6
    local yOffset = yOffset or -2
    local prevButton = tabbutton[id - 1] -- 获取前一个按钮

    local button = CreateFrame("Button", nil, parent, "ColumnDisplayButtonTemplate")
    button:SetSize(width, 24) -- 如果不是24，右边框体会出问题
    if prevButton then
		frame:Hide()
        button:SetPoint("BOTTOMLEFT", prevButton["A"], "BOTTOMRIGHT", 10 ,0)
		button:SetScale(.9)
		button:GetFontString():SetTextColor(1, 1, 1)
    else
        button:SetPoint("BOTTOM", parent, "TOPLEFT", xOffset, yOffset)
		button:SetScale(1.1)
		button:GetFontString():SetTextColor(1, 1, 0)
    end
    button:SetText(text)
    button:GetFontString():SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    button:GetFontString():SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
	
    tabbutton[id] = {}
	tabbutton[id]["A"] = button
	tabbutton[id]["B"] = frame
    button:SetScript("OnClick", function(self)
        for aa, row in pairs(tabbutton) do
            if self == row["A"] then -- 只对当前按钮重新定位
                row["A"]:SetScale(1.1)
				row["A"]:GetFontString():SetTextColor(1, 1, 0)
				row["B"]:Show()
            else
                row["A"]:SetScale(.9)
				row["A"]:GetFontString():SetTextColor(1, 1, 1)
				row["B"]:Hide()
            end
        end
    end)

    return button
end

--点击功能按钮
function ns.AddfuncButton(parent,y,name,tip)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	local funcButton = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
	funcButton:SetText(name)
	funcButton:SetSize(230,25)
	funcButton:SetPoint("LEFT",rowFrame,"LEFT", 300, 1)
	funcButton:SetScript("OnClick", function()end)
	funcButton:SetScript("OnEnter",function(self) 
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	funcButton:SetScript("OnLeave", function(self)    
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)

	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.button = funcButton
	return funcButton
end

--色块
local defaultBtn		--挂在 ColorPickerFrame 左上角的"设为默认"按钮（本插件色块打开时显示）
local defaultBtnHandler	--当前色块的默认设置回调
function ns.AddColorFrame(parent, x, y, tip,width,height,DB,setfun,texture)
	local parent = parent or UIParent	--父框体
	local x, y = x or 0, y or 0	--锚点坐标
	local tip = tip or L["点击更改颜色"]
	local width,height = width or 75,height or 15

	local btn = CreateFrame("Button", nil, parent, "GameMenuButtonTemplate");
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y);
    btn:SetSize(width,height);
    btn:SetAlpha(0)
    btn:SetNormalFontObject("GameFontNormalLarge");
    btn:SetHighlightFontObject("GameFontHighlightLarge");
	btn.color = parent:CreateTexture(nil, "ARTWORK")
    btn.color:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    btn.color:SetSize(width,height)
	-- 传入 texture 时用该材质代替纯色块，并用所选颜色着色
	if texture then
		btn.color:SetTexture(texture)
		btn.color:SetVertexColor(PlateColorDB[DB]["r"], PlateColorDB[DB]["g"], PlateColorDB[DB]["b"], PlateColorDB[DB]["a"] or 1)
	else
		btn.color:SetColorTexture(PlateColorDB[DB]["r"], PlateColorDB[DB]["g"], PlateColorDB[DB]["b"], PlateColorDB[DB]["a"] or 1)
	end

	local savedColor = {}	--打开前存储的 DB 值快照（用于取消回退）

	-- 懒创建 ColorPickerFrame 左上角外部的"设为默认"按钮（全局字符串 RETURN_TO_DEFAULT）
	if not defaultBtn then
		defaultBtn = CreateFrame("Button", nil, ColorPickerFrame, "UIPanelButtonTemplate")
		defaultBtn:SetSize(90, 22)
		defaultBtn:SetPoint("LEFT", ColorPickerFrame, "TOPLEFT", 9, -7)
		defaultBtn:SetText(RETURN_TO_DEFAULT)
		defaultBtn:SetScript("OnClick", function()
			if defaultBtnHandler then defaultBtnHandler() end
		end)
		defaultBtn:Hide()
		-- ColorPickerFrame 隐藏时同步隐藏按钮（其他插件打开时不会显示，仅本插件 OnClick 时 Show）
		ColorPickerFrame:HookScript("OnHide", function()
			defaultBtn:Hide()
		end)
	end
	
    local onUpdate = function(restore)
        local r, g, b = ColorPickerFrame:GetColorRGB()
        if texture then
            btn.color:SetVertexColor(r, g, b, PlateColorDB[DB]["a"] or 1)
        else
            btn.color:SetColorTexture(r, g, b, PlateColorDB[DB]["a"] or 1)
        end
		PlateColorDB[DB]["r"] = r
		PlateColorDB[DB]["g"] = g
		PlateColorDB[DB]["b"] = b
		-- 仅当默认 DB 中有 a 字段时才保存透明度
		if ns.PlateColorDB[DB] and ns.PlateColorDB[DB].a ~= nil then
			PlateColorDB[DB]["a"] = ColorPickerFrame:GetColorAlpha()
		end
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
    end
    local onCancel = function()
        local r, g, b, a = savedColor.r, savedColor.g, savedColor.b, savedColor.a or 1
        -- 回退 DB 值（取消时不保存改动）
        PlateColorDB[DB]["r"] = r
        PlateColorDB[DB]["g"] = g
        PlateColorDB[DB]["b"] = b
        if ns.PlateColorDB[DB] and ns.PlateColorDB[DB].a ~= nil then
            PlateColorDB[DB]["a"] = a
        end
        -- 恢复色块显示
        if texture then
            btn.color:SetVertexColor(r, g, b, a)
        else
            btn.color:SetColorTexture(r, g, b, a)
        end

		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
    end

    btn:SetScript("OnClick", function(self, button, down)
       -- 仅当默认 DB 中存在 a 字段时才启用透明度滑动条
       local hasOpacity = ns.PlateColorDB[DB] and ns.PlateColorDB[DB].a ~= nil
       ColorPickerFrame.swatchFunc = onUpdate
       ColorPickerFrame.opacityFunc = onUpdate
       ColorPickerFrame.cancelFunc = onCancel
       ColorPickerFrame.hasOpacity = hasOpacity
       -- 保存打开前的 DB 值（取消时回退到这里）
       savedColor.r = PlateColorDB[DB]["r"]
       savedColor.g = PlateColorDB[DB]["g"]
       savedColor.b = PlateColorDB[DB]["b"]
       savedColor.a = PlateColorDB[DB]["a"] or 1
       -- 取消回退目标 = 存储的 DB 值
       ColorPickerFrame.previousValues = {
            r = PlateColorDB[DB]["r"],
            g = PlateColorDB[DB]["g"],
            b = PlateColorDB[DB]["b"],
            a = PlateColorDB[DB]["a"] or 1,
       }
       -- 打开时正常显示存储值
       if hasOpacity then
            ColorPickerFrame.opacity = PlateColorDB[DB]["a"] or 1
       end
       local picker = ColorPickerFrame.Content and ColorPickerFrame.Content.ColorPicker or ColorPickerFrame
       picker:SetColorRGB(PlateColorDB[DB]["r"], PlateColorDB[DB]["g"], PlateColorDB[DB]["b"])
       -- 设置"设为默认"按钮：点击时把当前色块设为默认值
       if defaultBtn then
            defaultBtnHandler = function()
                local d = ns.PlateColorDB[DB]
                -- 写回默认值
                PlateColorDB[DB]["r"] = d.r
                PlateColorDB[DB]["g"] = d.g
                PlateColorDB[DB]["b"] = d.b
                if ns.PlateColorDB[DB].a ~= nil then PlateColorDB[DB]["a"] = d.a or 1 end
                -- 更新选择器显示为默认值（先设透明度再设 RGB，保证 onUpdate 正确保存 a）
                if hasOpacity then
                    ColorPickerFrame.opacity = d.a or 1
                    picker:SetColorAlpha(d.a or 1)
                end
                picker:SetColorRGB(d.r, d.g, d.b)
                -- 更新色块
                if texture then
                    btn.color:SetVertexColor(d.r, d.g, d.b, d.a or 1)
                else
                    btn.color:SetColorTexture(d.r, d.g, d.b, d.a or 1)
                end
                -- 刷新姓名板
                if setfun then
                    setfun()
                    for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
                        if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
                    end
                end
            end
            defaultBtn:Show()
       end
       ColorPickerFrame:Show()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tip, 1, 1, 1)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
	return btn
end

--创建主页面编辑框
function ns.AddEditBox(parent,x,y,size,Numeric,scale)
	local Box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	Box:SetSize(size, 30)
	Box:SetScale(scale or 1)
	Box:SetPoint("TOPLEFT", x,y)
	Box:SetAutoFocus(false)
	Box:SetNumeric(Numeric)
	local ClearBox = CreateFrame("Button", nil, Box)
	ClearBox:SetPoint("RIGHT", -5, 0)
	ClearBox:SetSize(13, 13)
	ClearBox:SetNormalTexture("common-search-clearbutton")
	ClearBox:SetHighlightTexture("common-search-clearbutton")
	Box:SetScript("OnEnterPressed", function() end)
	--Box:SetScript("OnTextChanged", function() end)
	Box:SetScript("OnTextChanged", function(self)
		ClearBox:SetShown(self:GetText() ~= "")
	end)
	ClearBox:SetScript("OnClick", function() Box:SetText("") Box:GetScript("OnTextChanged")(Box)  end)
	return Box
end

--创建主页面点击按钮
function ns.AddButtons(parent,name,x,y,width,height,Numeric,scale)
	local Button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	Button:SetPoint("TOPLEFT", x,y)
	Button:SetSize(width,height)
	Button:SetText(name)
	Button:SetScript("OnClick", function() end)
	return Button
end

--设置主页面分类标题文本
function ns.AddSetTiText(parent,y,texts)
	local Text = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	Text:SetPoint("TOPLEFT",parent,"TOPLEFT", 30, -20+ns.Y[y]*-35)
	Text:SetText(texts)
	Text:SetFontObject("PC_FontOutline")
Text:SetFontHeight(20)
	Text:SetTextColor(1,1,1)
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	return Text
end
--设置主页面点击按钮
function ns.AddSetClickB(parent,y,name,tip,db,setfun,spare1,spare2)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("LEFT", 297, 0)
	check:SetSize(30,30)
	check:SetChecked(PlateColorDB[db])
	check:SetScript("OnEnter",function(self) 
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	check:SetScript("OnLeave", function(self)    
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	check:SetScript("OnClick", function ( ... )
		PlateColorDB[db] = check:GetChecked()
		if InCombatLockdown() then return end
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
	end)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)

		
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.check = check
	return cleckandtext
	
end

--基于 CVar 的复选框开关（不保存到 DB，初始状态由 CVar 决定）
--cvarName: CVar 名称
--enumValue: (可选) 位域 CVar 的位索引，传此值则用 ns.GetCVar/ns.SetCVar 读写位域
--setfun: (可选) 切换后回调
function ns.AddCVarClickB(parent, y, name, tip, cvarName, enumValue, setfun)
	-- 无效的 CVar 不创建控件
	if not C_CVar.GetCVar(cvarName) then return end
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetColorTexture(0, 0, 0, 0)
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("LEFT", 297, 0)
	check:SetSize(30,30)
	
	-- 从 CVar 读取初始状态
	local function GetCVarState()
		if enumValue then
			return ns.GetCVar(cvarName, enumValue)
		else
			return GetCVar(cvarName) == "1"
		end
	end
	check:SetChecked(GetCVarState())
	
	check:SetScript("OnEnter",function(self) 
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r")
			-- 显示暴雪默认值（换行，值为浅蓝色）
			local defaultStr = "?"
			if enumValue then
				local num = tonumber(C_CVar.GetCVarDefault(cvarName)) or 0
				defaultStr = (bit.band(num, bit.lshift(1, enumValue - 1)) ~= 0) and "1" or "0"
			else
				defaultStr = C_CVar.GetCVarDefault(cvarName) or ""
			end
			if defaultStr == "1" then
				defaultStr = ACTIVATE
			elseif defaultStr == "0" then
				defaultStr = DISABLE
			end
			GameTooltip:AddLine("|cffFFFFFF"..L["暴雪默认值"]..": |cff87CEEB"..defaultStr.."|r")
			GameTooltip:Show()
		end
	end)
	check:SetScript("OnLeave", function(self)    
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	check:SetScript("OnClick", function ( ... )
		local checked = check:GetChecked()
		if enumValue then
			ns.SetCVar(cvarName, enumValue, checked)
		else
			C_CVar.SetCVar(cvarName, checked and "1" or "0")
		end
		if InCombatLockdown() then return end
		if setfun then
			setfun()
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
	end)
	
	-- 监听 CVar 外部变化，自动同步 UI
	ns.hookcvar(cvarName, function()
		check:SetChecked(GetCVarState())
	end)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)

	ns.Y[y] = ns.Y[y] + 1
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.check = check
	return cleckandtext
end

--基于 CVar 的滑动条（不保存到 DB，初始值/当前值由 CVar 决定）
--cvarName: CVar 名称
--setfun: (可选) 值变化后回调，收到当前值（用于同步关联 CVar）
function ns.AddCVarSlider(parent,y, name, tip, minValue, maxValue, valueStep, varformat, cvarName, setfun)
	-- 无效的 CVar 不创建控件
	if not C_CVar.GetCVar(cvarName) then return end
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)

	local function GetCVarValue()
		return tonumber(C_CVar.GetCVar(cvarName)) or minValue
	end

	local PCSlider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	PCSlider:SetPoint("LEFT",SliderBackground,"LEFT", 300, 0)
	PCSlider:SetSize(220,20)
	PCSlider.lefttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	PCSlider.lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	PCSlider.lefttext:SetText(name)
	PCSlider.lefttext:SetFontObject("PC_FontOutline")
	PCSlider.lefttext:SetFontHeight(14)
	PCSlider.lefttext:SetTextColor(1,.82,0)
	PCSlider.righttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	PCSlider.righttext:SetPoint("LEFT",PCSlider,"RIGHT",10, 0)
	PCSlider.righttext:SetFontObject("PC_FontOutline")
	PCSlider.righttext:SetFontHeight(17)
	PCSlider.righttext:SetTextColor(0,1,0)
	PCSlider.righttext:SetText(string.format(varformat, GetCVarValue()))

	PCSlider:Init(GetCVarValue(), minValue, maxValue, (maxValue - minValue) / (valueStep or 1))
	PCSlider:RegisterCallback("OnValueChanged", function(self, value)
		value = tonumber(string.format(varformat, value))
		PCSlider.righttext:SetText(string.format(varformat, value))
		if InCombatLockdown() then return end
		C_CVar.SetCVar(cvarName, value)
		if setfun then setfun(value) end
	end)
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	-- 简化的tooltip处理函数
	local function setupTooltip(frame, background, tip)
		frame:SetScript("OnEnter", function(self)
			background:SetColorTexture(0.5, 0.5, 0.5, 0.2)
			if tip then
				GameTooltip:SetOwner(PCSlider, "ANCHOR_TOP")
				GameTooltip:AddLine("|cffFFFFFF" .. tip .. "|r")
				local defaultVal = tonumber(C_CVar.GetCVarDefault(cvarName) or "")
				if defaultVal ~= nil then
					GameTooltip:AddLine("|cffFFFFFF"..L["暴雪默认值"]..": |cff87CEEB"..string.format(varformat, defaultVal).."|r")
				end
				GameTooltip:Show()
			end
		end)
		frame:SetScript("OnLeave", function(self)
			background:SetColorTexture(0, 0, 0, 0)
			if tip then
				GameTooltip:Hide()
			end
		end)
	end
	setupTooltip(PCSlider.Slider, SliderBackground, tip)
	setupTooltip(PCSlider.Back, SliderBackground, tip)
	setupTooltip(PCSlider.Forward, SliderBackground, tip)

	-- 监听 CVar 外部变化，自动同步 UI
	ns.hookcvar(cvarName, function()
		local v = GetCVarValue()
		PCSlider:SetValue(v)
		PCSlider.righttext:SetText(string.format(varformat, v))
	end)

	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local PCSliders = {}
	PCSliders.check = PCSlider
	PCSliders.text = PCSlider.lefttext
	PCSliders.righttext = PCSlider.righttext
	return PCSliders
end

--设置主页面滑动条
local OptionFrames = {}
local OptionFrameid = 1
function ns.AddSetSlider(parent,y, name, tip, minValue, maxValue, valueStep,varformat, db,setfun,spare)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)
	
	local PCSlider = CreateFrame("Slider", nil, rowFrame, "MinimalSliderWithSteppersTemplate")
	PCSlider:SetPoint("LEFT",SliderBackground,"LEFT", 300, 0)
	PCSlider:SetSize(220,20)
	PCSlider.lefttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	PCSlider.lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	PCSlider.lefttext:SetText(name)
	PCSlider.lefttext:SetFontObject("PC_FontOutline")
	PCSlider.lefttext:SetFontHeight(14)
	PCSlider.lefttext:SetTextColor(1,.82,0)
	PCSlider.righttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	PCSlider.righttext:SetPoint("LEFT",PCSlider,"RIGHT",10, 0)
	PCSlider.righttext:SetFontObject("PC_FontOutline")
	PCSlider.righttext:SetFontHeight(17)
	PCSlider.righttext:SetTextColor(0,1,0)
	PCSlider.righttext:SetText(string.format(varformat,PlateColorDB[db]))

	PCSlider:Init(PlateColorDB[db], minValue, maxValue, (maxValue - minValue) / (valueStep or 1))
	PCSlider:RegisterCallback("OnValueChanged", function(self, value)
		PCSlider.righttext:SetText(string.format(varformat,value))
		PlateColorDB[db] = tonumber(string.format(varformat,value))
		if InCombatLockdown() then return end
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
	end)
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	-- 简化的tooltip处理函数
	local function setupTooltip(frame, background, tip)
		frame:SetScript("OnEnter", function(self)
			background:SetColorTexture(0.5, 0.5, 0.5, 0.2)
			if tip then
				GameTooltip:SetOwner(PCSlider, "ANCHOR_TOP")
				GameTooltip:AddLine("|cffFFFFFF" .. tip .. "|r")
				GameTooltip:Show()
			end
		end)
		frame:SetScript("OnLeave", function(self)
			background:SetColorTexture(0, 0, 0, 0)
			if tip then
				GameTooltip:Hide()
			end
		end)
	end
	setupTooltip(PCSlider.Slider, SliderBackground, tip)
	setupTooltip(PCSlider.Back, SliderBackground, tip)
	setupTooltip(PCSlider.Forward, SliderBackground, tip)

	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local PCSliders = {}
	PCSliders.check = PCSlider
	PCSliders.text = PCSlider.lefttext
	PCSliders.righttext = PCSlider.righttext
	return PCSliders
end

--设置主页面血条材质下拉菜单
function ns.AddSetDropdTexture(parent,y,name,tip,db,TextureTable,setfun)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)
	
	--下拉菜单
    local RadioDropdown = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
    RadioDropdown:SetPoint("LEFT",SliderBackground, 300, 0)
	RadioDropdown:SetDefaultText(PlateColorDB[db])
    RadioDropdown:SetWidth(200)
	RadioDropdown:HookScript("OnEnter", function(self)
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	RadioDropdown:HookScript("OnLeave", function(self)
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	RadioDropdown.selectTexture = RadioDropdown:CreateTexture(nil, "ARTWORK")--选中材质
	RadioDropdown.selectTexture:SetPoint("TOPLEFT",RadioDropdown,"TOPLEFT", 5, -5)
	RadioDropdown.selectTexture:SetPoint("BOTTOMRIGHT",RadioDropdown,"BOTTOMRIGHT", -15, 5)
	RadioDropdown.selectTexture:SetVertexColor(1,1,1,1)
	if not TextureTable[PlateColorDB[db]] then
		PlateColorDB[db] = "PC-White" --因为用了lib的材质,如果找不到就重新定义
	end
	if string.match(TextureTable[PlateColorDB[db]],"Interface\\")then 
		RadioDropdown.selectTexture:SetTexture(TextureTable[PlateColorDB[db]])
	else
		RadioDropdown.selectTexture:SetAtlas(TextureTable[PlateColorDB[db]])
	end
	
    local function IsSelected(value)
        return value == PlateColorDB[db]
    end
    local function SetSelected(value)
        PlateColorDB[db] = value
		if string.match(TextureTable[PlateColorDB[db]],"Interface\\")then 
			RadioDropdown.selectTexture:SetTexture(TextureTable[PlateColorDB[db]])
		else
			RadioDropdown.selectTexture:SetAtlas(TextureTable[PlateColorDB[db]])
		end
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
    end
	--先对表格进行排序
	local sortedTable = {}
	for k in pairs(TextureTable) do
		table.insert(sortedTable, k)
	end
	table.sort(sortedTable)
    -- 菜单项生成函数使用排序后的表格
    local function GeneratorFunction(dropdown, rootDescription)
		rootDescription:SetScrollMode(400);
        for _, text in pairs(sortedTable) do
			local texts = text
			if string.match(TextureTable[text],"PlateColor\\texture")then 
				texts = "|cff00FFFF"..text
			end
            local radio = rootDescription:CreateRadio(texts, IsSelected, SetSelected, text)
            radio:AddInitializer(function(button, description, menu)
                local bgTexture = button:AttachTexture()
				bgTexture:SetSize(200,16)
                bgTexture:SetPoint("LEFT",15,0);
				if string.match(TextureTable[text],"Interface\\")then 
					bgTexture:SetTexture(TextureTable[text])
				else
					bgTexture:SetAtlas(TextureTable[text])
				end
				bgTexture:SetDrawLayer("BACKGROUND")--12.0
            end)
        end
    end
    RadioDropdown:SetupMenu(GeneratorFunction)
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	return check
end

--设置主页面材质下拉菜单
function ns.AddSetDropdTexture2(parent,y,name,tip,db,TextureTable,setfun)
	
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)
	
	--下拉菜单
    local RadioDropdown = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
    RadioDropdown:SetPoint("LEFT",SliderBackground, 300, 0)
	RadioDropdown:SetDefaultText(PlateColorDB[db])
    RadioDropdown:SetWidth(200)
	RadioDropdown:HookScript("OnEnter", function(self)
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	RadioDropdown:HookScript("OnLeave", function(self)
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	RadioDropdown.selectTexture = RadioDropdown:CreateTexture(nil, "ARTWORK")--选中材质
	RadioDropdown.selectTexture:SetPoint("RIGHT",RadioDropdown,"RIGHT", -30, 0)
	RadioDropdown.selectTexture:SetSize(25,25)
	RadioDropdown.selectTexture:SetVertexColor(1,1,1,1)
	RadioDropdown.selectTexture:SetTexture(TextureTable[PlateColorDB[db]])

    local function IsSelected(value)
        return value == PlateColorDB[db]
    end
    local function SetSelected(value)
        PlateColorDB[db] = value
		RadioDropdown.selectTexture:SetTexture(TextureTable[PlateColorDB[db]])
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
    end
	
	--先对表格进行排序
	local sortedTable = {}
	for k in pairs(TextureTable) do
		table.insert(sortedTable, k)
	end
	table.sort(sortedTable)
    -- 菜单项生成函数使用排序后的表格
    local function GeneratorFunction(dropdown, rootDescription)
		rootDescription:SetScrollMode(400);
        for name, text in pairs(sortedTable) do
            local radio = rootDescription:CreateRadio(text, IsSelected, SetSelected, text)
            radio:AddInitializer(function(button, description, menu)
                local bgTexture = button:AttachTexture()
				bgTexture:SetSize(20,20)
                bgTexture:SetPoint("RIGHT", 0,0);
                bgTexture:SetTexture(TextureTable[text])
				bgTexture:SetDrawLayer("BACKGROUND")--12.0
            end)
        end
    end
    RadioDropdown:SetupMenu(GeneratorFunction)
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	return check
end

--设置主页面下拉菜单
function ns.AddSetDropdM(parent,y,name,tip,optionstext,db,setfun)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)
	
	--下拉菜单
	local RadioDropdown = CreateFrame("DropdownButton", nil, rowFrame, "WowStyle1DropdownTemplate")
	RadioDropdown:SetPoint("LEFT",SliderBackground,300, 0)
	RadioDropdown:HookScript("OnEnter", function(self)
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	RadioDropdown:HookScript("OnLeave", function(self)
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	local function IsSelected(value)
		return value == PlateColorDB[db]
	end

	local function SetSelected(value)
		PlateColorDB[db] = value
		if setfun then--设置姓名版对应功能
			setfun()--先无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
	end
	MenuUtil.CreateRadioMenu(RadioDropdown,IsSelected, SetSelected,unpack(optionstext))
		
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	return check
end

--设置主页面界面颜色选项
function ns.AddSetColorF(parent,y,name,tip,DB,setfun)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)
	
	local Color = ns.AddColorFrame(rowFrame, 301, -3, "",217,20,DB,setfun)
	Color:HookScript("OnEnter", function(self)
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	Color:HookScript("OnLeave", function(self)
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	
	return Color
end

--设置主页面点击+颜色选项
function ns.AddClickColor(parent,y,name,tip,db,db2,setfun)
	local rowFrame = CreateFrame("Frame", nil, parent)
    rowFrame:SetSize(630, 26)
    rowFrame:SetPoint("TOPLEFT", 10, -10+ns.Y[y]*-35)
	local SliderBackground = rowFrame:CreateTexture(nil, "BACKGROUND")
	SliderBackground:SetTexture(130937)
	SliderBackground:SetAllPoints(rowFrame)
	SliderBackground:SetColorTexture(0, 0, 0, 0) -- 设置背景颜色为黑色，透明度为0.5
	SliderBackground:SetScript("OnEnter", function(self)
		self:SetColorTexture(0.5, 0.5, 0.5, .2)
	end)
	SliderBackground:SetScript("OnLeave", function(self)
		self:SetColorTexture(0, 0, 0, 0)
	end)
	local check = CreateFrame("CheckButton", nil, rowFrame, "InterfaceOptionsCheckButtonTemplate")
	check:SetPoint("LEFT", 297, 0)
	check:SetSize(30,30)
	check:SetChecked(PlateColorDB[db])
	check:SetScript("OnEnter",function(self) 
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	check:SetScript("OnLeave", function(self)    
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	check:SetScript("OnClick", function ( ... )
		PlateColorDB[db] = check:GetChecked()
		if InCombatLockdown() then return end
		if setfun then--设置姓名版对应功能
			setfun()--无参调用一次，确保无姓名板时也能触发全局回调
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				if namePlate.UnitFrame then setfun(namePlate.UnitFrame) end
			end
		end
	end)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFontObject("PC_FontOutline")
	lefttext:SetFontHeight(14)
	lefttext:SetTextColor(1,.82,0)

	local Color = ns.AddColorFrame(rowFrame, 351, -3, tip,167,20,db2,setfun)
	Color:HookScript("OnEnter", function(self)
		SliderBackground:SetColorTexture(0.5, 0.5, 0.5, .2)
		if tip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:AddLine("|cffFFFFFF"..tip.."|r") 
			GameTooltip:Show()
		end
	end)
	Color:HookScript("OnLeave", function(self)
		SliderBackground:SetColorTexture(0, 0, 0, 0)
		if tip then
			GameTooltip:Hide()
		end
	end)
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.check = check
	return cleckandtext
end