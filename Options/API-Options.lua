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
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
	lefttext:SetTextColor(1,.82,0)

	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.button = funcButton
	return funcButton
end

--色块
function ns.AddColorFrame(parent, x, y, tip,width,height,DB,setfun)
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
    btn.color:SetColorTexture(PlateColorDB[DB]["r"], PlateColorDB[DB]["g"], PlateColorDB[DB]["b"])
	
    local onUpdate = function(restore)
        local r, g, b = ColorPickerFrame:GetColorRGB()
        btn.color:SetColorTexture(r, g, b)
		PlateColorDB[DB]["r"] = r
		PlateColorDB[DB]["g"] = g
		PlateColorDB[DB]["b"] = b
		if setfun then--设置姓名版对应功能
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
			end
		end
    end
    local onCancel = function()
        local r, g, b = ColorPickerFrame:GetPreviousValues()
		ColorPickerFrame.Content.ColorPicker:SetColorRGB(r, g, b)
        btn.color:SetColorTexture(r, g, b)

		if setfun then--设置姓名版对应功能
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
			end
		end
    end

    btn:SetScript("OnClick", function(self, button, down)
       ColorPickerFrame.swatchFunc = onUpdate
       ColorPickerFrame.previousValues = {r = PlateColorDB[DB]["r"], g = PlateColorDB[DB]["g"], b = PlateColorDB[DB]["b"]}
       ColorPickerFrame.cancelFunc = onCancel
       ColorPickerFrame.Content.ColorPicker:SetColorRGB(ns.PlateColorDB[DB]["r"], ns.PlateColorDB[DB]["g"], ns.PlateColorDB[DB]["b"])
       ColorPickerFrame:Show()
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(tip)
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
	Text:SetFont(ns.fonts, 20, "OUTLINE")
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
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
			end
		end
	end)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
	lefttext:SetTextColor(1,.82,0)

		
	
	ns.Y[y] = ns.Y[y] + 1	--最后增加一次起始位置
	local cleckandtext = {}
	cleckandtext.text = lefttext
	cleckandtext.check = check
	return cleckandtext
	
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
	PCSlider:SetMinMaxValues(minValue, maxValue)
	PCSlider:SetValue(PlateColorDB[db])
	PCSlider:SetValueStep(valueStep)
	PCSlider:SetObeyStepOnDrag(true)
	PCSlider.lefttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	PCSlider.lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	PCSlider.lefttext:SetText(name)
	PCSlider.lefttext:SetFont(ns.fonts, 14, "OUTLINE")
	PCSlider.lefttext:SetTextColor(1,.82,0)
	PCSlider.righttext = PCSlider:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	PCSlider.righttext:SetPoint("LEFT",PCSlider,"RIGHT",10, 0)
	PCSlider.righttext:SetFont(ns.fonts, 17, "OUTLINE")
	PCSlider.righttext:SetTextColor(0,1,0)
	PCSlider.righttext:SetText(tonumber(string.format(varformat,PlateColorDB[db])))

	PCSlider:Init(PlateColorDB[db], minValue, maxValue, (maxValue - minValue) / (valueStep or 1))
	PCSlider:RegisterCallback("OnValueChanged", function(self, value)
		PCSlider.righttext:SetText(string.format(varformat,value))
		PlateColorDB[db] = tonumber(string.format(varformat,value))
		if InCombatLockdown() then return end
		if setfun then--设置姓名版对应功能
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
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
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
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
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
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
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
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
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
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
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
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
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
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
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
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
			for i, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
				setfun(namePlate.UnitFrame)
			end
		end
	end)
	local lefttext = rowFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	lefttext:SetPoint("LEFT", SliderBackground, "LEFT", 90, 0)
	lefttext:SetText(name)
	lefttext:SetFont(ns.fonts, 14, "OUTLINE")
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