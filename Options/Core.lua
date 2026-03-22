local addonName,ns = ...
local DB = ns.PlateColorDB
local L = ns.L

ns.CVarFrames = {TextFrames = {},Frames = {}}--记录CVar框体
ns.Y = {}	--用于分页行数自动拓展

local addontext = ns.RCTexts(addonName)
local PCGUI = CreateFrame("Frame")
local category = Settings.RegisterCanvasLayoutCategory(PCGUI, addontext)
Settings.RegisterAddOnCategory(category)

SlashCmdList["PLATECOLOR"] = function()
	ns.COMBAT(Settings.OpenToCategory,category:GetID())
end
SLASH_PLATECOLOR1 = "/pc"
SLASH_PLATECOLOR2 = "/platecolor"

local creattrue = false
ns.event("PLAYER_LOGIN", function(event)
if creattrue then return end
creattrue = true

--标题文本
local TiText = PCGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
TiText:SetPoint("TOPLEFT",PCGUI,"TOPLEFT", 0, -10)
TiText:SetText(addontext)
TiText:SetFont(ns.fonts, 50, "OUTLINE")
--标题文本2
local TiText2 = PCGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
TiText2:SetPoint("BOTTOMLEFT",TiText,"BOTTOMRIGHT", 5, 8)
TiText2:SetFont(ns.fonts, 20, "OUTLINE")
TiText2:SetText(SHOW_TARGET_CASTBAR_IN_V_KEY)
TiText2:SetVertexColor(1.0, 1.0, 1.0)

--版本信息
local versiontext = PCGUI:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
versiontext:SetPoint("TOPRIGHT", 0, 5)
versiontext:SetText("|cff00FFFF"..C_AddOns.GetAddOnMetadata(addonName,"Version"))
versiontext:SetJustifyH("RIGHT")
versiontext:SetVertexColor(0, 1, 1)


-- 创建主背景框架
local parentBackdrop = CreateFrame("Frame", "PCparentFrame", PCGUI, "BackdropTemplate")
parentBackdrop:SetSize(680, 500)
parentBackdrop:SetPoint("BOTTOMLEFT",-14,-2)
parentBackdrop:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
parentBackdrop:SetBackdropColor(0, 0, 0, 0.5)
parentBackdrop:SetBackdropBorderColor(0.7, 0.7, 0.7)

--创建ns.tabframe分页
ns.tabframe1 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe2 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe3 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe4 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe5 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe6 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe7 = CreateFrame("Frame", nil, parentBackdrop)
ns.tabframe1:SetAllPoints(parentBackdrop)
ns.tabframe2:SetAllPoints(parentBackdrop)
ns.tabframe3:SetAllPoints(parentBackdrop)
ns.tabframe4:SetAllPoints(parentBackdrop)
ns.tabframe5:SetAllPoints(parentBackdrop)
ns.tabframe6:SetAllPoints(parentBackdrop)
ns.tabframe7:SetAllPoints(parentBackdrop)
--绑定到放大按钮
ns.AddClickBC(parentBackdrop,ns.tabframe1,1,72, L["基础"],42)
ns.AddClickBC(parentBackdrop,ns.tabframe2,2,72, L["指示器"])
ns.AddClickBC(parentBackdrop,ns.tabframe3,3,72, L["仇恨"])
ns.AddClickBC(parentBackdrop,ns.tabframe4,4,100,L["NPC颜色"])
ns.AddClickBC(parentBackdrop,ns.tabframe5,5,90, L["辅助功能"])
ns.AddClickBC(parentBackdrop,ns.tabframe6,6,72, L["配置"])--重置
ns.AddClickBC(parentBackdrop,ns.tabframe7,7,100, UPDATE..GUILD_BANK_LOG)--重更新
--重载按钮
local reload = CreateFrame("Button", nil, PCGUI, "UIPanelButtonTemplate")
reload:SetText("重载")
reload:SetWidth(92)
reload:SetHeight(22)
reload:SetPoint("BOTTOMRIGHT", -132, -31)
reload:SetScript("OnClick", function()
	 ReloadUI()
end)

-- ========== 通用链接按钮生成函数 (导出样式) ==========
-- 参数说明：
-- xOffset: X坐标偏移量
-- iconTexture: 图标纹理路径（按钮图标）
-- copyContent: 弹窗中要复制的内容
-- tooltipImage: 鼠标悬停时显示的图片路径
local linkindex = 0
local function CreateLinkButton(iconTexture, copyContent, tooltipImage,size)
	local btn = CreateFrame("Button", nil, PCGUI)
	btn:SetWidth(20)
	btn:SetHeight(20)
	btn:SetPoint("BOTTOMLEFT", linkindex*40 + 60, -35)
	linkindex = linkindex + 1
	
	-- 设置纹理
	local btnTexture = btn:CreateTexture(nil, "ARTWORK")
	btnTexture:SetAllPoints(btn)
	btnTexture:SetTexture(iconTexture)
	
	-- 添加高亮效果
	btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	
	-- 鼠标提示
	btn:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		
		-- 如果提供了tooltipImage，显示图片；否则显示文本
		if tooltipImage then
			GameTooltip:AddLine(" ")
            local sizescale = size or 1
			GameTooltip:AddTexture(tooltipImage,{width = 200, height = 200*sizescale})
		end
		
		GameTooltip:Show()
	end)
	btn:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	
	-- 点击事件：显示导出样式弹窗
	btn:SetScript("OnClick", function(self)
        if copyContent then
		    ns.ShowBox(copyContent)
        end
	end)
	
	return btn
end

-- ========== 创建具体的链接按钮 ==========
---矢量图来源https://www.iconfont.cn/?spm=a313x.search_index.i3.d4d0a486a.70603a81WbKJak
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
        "140237131398", "Interface\\AddOns\\PlateColor\\texture\\Links\\douyin4.png",1.3)

    CreateLinkButton("Interface\\AddOns\\PlateColor\\texture\\Links\\aifadian.png", 
        "https://afdian.com/a/jianfan", "Interface\\AddOns\\PlateColor\\texture\\Links\\aifadian2.png",1.5)

end


end)