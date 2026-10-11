local addonName, ns = ...

-- ═══════════════════════════════════════════════════════════════════
-- 光环设置共用窗口（外壳）
-- 插件里这几个设置界面共用同一个窗口，各自占一页，点不同按钮只切换显示哪一页；
-- 窗口的标题与尺寸随页走（尺寸不同不冲突，切页时窗口跟着变），窗口位置只记一份。
--   注册（文件加载期）：ns.RegisterAuraPage(key, { title = , width = , height = , build = function(page) end })
--   打开：ns.OpenAuraPage(key) —— 隐藏其它页、套用该页标题尺寸、首次打开才 build（懒构建）
-- 页框与窗口同尺寸同坐标原点（SetAllPoints），所以页内可以直接沿用原窗口的坐标写法。
-- ⚠️ build 里只建页面内容，别自己建窗口外壳（背板/标题/关闭按钮/拖动都在这里统一管）。
-- ⚠️ 页框是懒构建的：页面内的 OnShow 会在每次切到该页时触发，适合挂"刷新列表"。
-- ═══════════════════════════════════════════════════════════════════

local WINDOW_NAME = "PlateAurasWindow"
local WINDOW_WIDTH = 460
local WINDOW_HEIGHT = 430

local pages = {}	-- [key] = cfg（注册的页配置）
local built = {}	-- [key] = page（已构建的页框）
local window

local function GetWindow()
	if window then
		return window
	end

	local f = CreateFrame("Frame", WINDOW_NAME, UIParent, "BackdropTemplate")
	f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
	f:SetPoint("CENTER")
	f:SetFrameStrata("DIALOG")
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", f.StartMoving)
	f:SetScript("OnDragStop", f.StopMovingOrSizing)
	f:SetClampedToScreen(true)
	f:Hide()
	f:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	f:SetBackdropColor(0.08, 0.08, 0.08, 1)

	local background = f:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints(f)
	background:SetColorTexture(0.08, 0.08, 0.08, 1)

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
	title:SetPoint("TOP", 0, -8)
	f.title = title

	local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", 2, 2)

	window = f
	return f
end

-- 注册一页：只登记标题/尺寸/构建函数，UI 等第一次打开时才建
function ns.RegisterAuraPage(key, cfg)
	pages[key] = cfg
end

-- 打开某一页：窗口里只显示这一页
function ns.OpenAuraPage(key)
	local cfg = pages[key]
	if not cfg then return end

	local win = GetWindow()

	for _, page in pairs(built) do
		page:Hide()--只留被点的这一页（页的 OnShow 会顺带刷新内容）
	end

	local page = built[key]
	if not page then
		page = CreateFrame("Frame", nil, win)
		page:SetAllPoints(win)--与窗口同坐标原点，页内沿用原窗口的锚点写法
		built[key] = page
		cfg.build(page)
	end

	win.title:SetText(cfg.title or "")
	win:SetSize(cfg.width or WINDOW_WIDTH, cfg.height or WINDOW_HEIGHT)
	page:Show()
	win:Show()
	win:Raise()
end
