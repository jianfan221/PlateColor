-- Links.lua：设置页底部链接按钮 + 复制文本条（PlateColor 特有）
-- 通过核心暴露的 ns.BuildBottom 钩子，在懒构建时把链接按钮锚定到 ns.ContactFrame 左侧，
-- 这样 AddUI/PlateColor 的联系方式、链接按钮都统一锚定到核心的 ContactFrame，各自插件各加各的。
local addonName, ns = ...

-- 可复制文本条：点击链接按钮后固定在按钮上方显示，自动全选，失焦隐藏（单行）
local copyBar = CreateFrame("EditBox", nil, UIParent, "InputBoxTemplate")
copyBar:SetSize(400, 24)
copyBar:SetFrameStrata("DIALOG")
copyBar:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
copyBar:SetScript("OnEditFocusLost", function(self) self:Hide() end)
copyBar:ClearAllPoints()
copyBar:SetPoint("BOTTOMLEFT", ns.SettingsFrame, "BOTTOMLEFT", -5, 0)
copyBar:Hide()

-- 底部链接按钮（核心已不调用 BuildBottom，直接挂到 ns.SettingsFrame 加载时创建）
local linkindex = 0
local function CreateLinkButton(iconTexture, copyContent, tooltipImage, size)
		local btn = CreateFrame("Button", nil, ns.SettingsFrame)
		btn:SetSize(20, 20)
		btn:SetPoint("BOTTOMLEFT", linkindex * 40, -33)  -- 从联系方式右侧开始横排
		linkindex = linkindex + 1

		-- 图标纹理
		local btnTexture = btn:CreateTexture(nil, "ARTWORK")
		btnTexture:SetAllPoints(btn)
		btnTexture:SetTexture(iconTexture)

		-- 高亮
		btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

		-- 悬停提示（可选图片）
		btn:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			if tooltipImage then
				GameTooltip:AddLine(" ")
				local sizescale = size or 1
				GameTooltip:AddTexture(tooltipImage, { width = 200, height = 200 * sizescale })
			end
			GameTooltip:Show()
		end)
		btn:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)

		-- 点击：把内容显示在按钮上方，自动全选可复制（单行）
		btn:SetScript("OnClick", function()
			if copyContent then
				copyBar:SetText(copyContent)
				copyBar:Show()
				copyBar:SetFocus()
			end
		end)
		return btn
	end

	-- 链接按钮列表（矢量图来源 https://www.iconfont.cn/）
	CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\curseforge.png",
		"https://legacy.curseforge.com/wow/addons/platecolor")
	CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\github.png",
		"https://github.com/jianfan221/PlateColor")

	if GetLocale() == "zhCN" then
		CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\nga.tga",
			"https://nga.178.com/read.php?tid=11477676")
		CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\bilibili.png",
			"https://space.bilibili.com/2260708")
		CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\douyin.png",
			"https://www.douyin.com/user/MS4wLjABAAAA8A4MhoUW96o3IUSKRHr7hx_lR10we68TixlVo7G6I9E?from_tab_name=main&vid=7360987693624462644",
			"Interface\\AddOns\\PlateColor\\texture\\Links\\douyin2.png")
		CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\douyin3.png",
			"140237131398", "Interface\\AddOns\\PlateColor\\texture\\Links\\douyin4.png", 1.3)
		CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\aifadian.png",
			"https://afdian.com/a/jianfan", "Interface\\AddOns\\PlateColor\\texture\\Links\\aifadian2.png", 1.5)
	end
