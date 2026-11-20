local _, ns = ...
if not C_TooltipInfo or not C_TooltipInfo.GetUnit then return end

--任务标记
local NameQuestTable = {}
local QuestTitle = {} -- questID -> 任务名（任务被移除/交付后已不在日志，用它兜底）
function ns.CreateNameQuest(unitFrame)
	if type(unitFrame) ~= "table" or not unitFrame.unit then return end
	if not PlateColorDB.questMark then
		--关闭开关时把已显示的图标收掉
		if unitFrame.NameQuest then
			unitFrame.NameQuest:Hide()
		end
		return
	end

	if not unitFrame.NameQuest then
		unitFrame.NameQuest = unitFrame:CreateTexture(nil, "OVERLAY")
		unitFrame.NameQuest:SetTexture("Interface\\Addons\\PlateColor\\texture\\questicon")
		unitFrame.NameQuest:SetSize(22,22)
	end
	
	unitFrame.NameQuest:ClearAllPoints()
	if unitFrame.healthBar:IsShown() then
		unitFrame.NameQuest:SetPoint("LEFT",unitFrame.healthBar,"RIGHT",8,0)
	elseif unitFrame.name then
		unitFrame.NameQuest:SetPoint("LEFT",unitFrame.name,"RIGHT",8,0)
	else
		unitFrame.NameQuest:SetPoint("TOP",unitFrame,"TOP",0,0)
	end
	local guid = UnitGUID(unitFrame.unit)
	if not ns.MM(guid) then
		if not unitFrame.tooltipData or unitFrame.tooltipData_guid ~= guid then
			unitFrame.tooltipData = C_TooltipInfo.GetUnit(unitFrame.unit)
			unitFrame.tooltipData_guid = guid
		end
		local tooltipData = unitFrame.tooltipData
		unitFrame.NameQuest:Hide() --先收起，取不到 tooltip 时也不会残留旧图标
		if tooltipData and tooltipData.lines then
			local lines = tooltipData.lines
			local playerGUID = UnitGUID("player")
			for i = 2, #lines do -- ipairs 从 1 开始，但我们从 2 开始，因为第一行通常是 NPC 名字，不包含任务信息
				local line = lines[i]
				local text = line.leftText
				-- 1. 匹配任务名
				if text and not ns.MM(text) and NameQuestTable[text] then
					-- 2. 一个任务可能有多条进度行（如需要多种任务物品），逐条检查玩家自己的那组
					-- 3. 队伍中会有多组进度（每组前有一行带 guid 的姓名行），只看 playerGUID 那组
					local incomplete = false
					local skipOthers = false
					for j = i + 1, #lines do
						local nextLine = lines[j]
						-- 注意：直接判断 .completed 属性，不要把 table 传给 ns.MM
						if nextLine.completed ~= nil then
							if not skipOthers and nextLine.completed == false then
								incomplete = true
								break
							end
						elseif nextLine.guid then
							skipOthers = nextLine.guid ~= playerGUID
						else
							break -- 该任务的进度行结束
						end
					end
					if incomplete then
						unitFrame.NameQuest:Show()
						break -- 找到一个未完成的任务就立刻退出循环
					end
				end
			end
		end
	else
		unitFrame.NameQuest:SetShown(C_QuestLog.UnitIsRelatedToActiveQuest and C_QuestLog.UnitIsRelatedToActiveQuest(unitFrame.unit))
	end

end

--刷新所有姓名版的任务标志（任务变化 / 设置项切换时用）
function ns.RefreshNameQuest()
	for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
		local unitFrame = namePlate.UnitFrame
		if unitFrame then
			unitFrame.tooltipData = nil
			ns.CreateNameQuest(unitFrame)
		end
	end
end



local  function QuestMarkEvent(event, IDs)
	if event == "NAME_PLATE_UNIT_ADDED" then
		local namePlate = C_NamePlate.GetNamePlateForUnit(IDs,false)
		if not namePlate then return end
		ns.CreateNameQuest(namePlate.UnitFrame)
	end
		--进入游戏获取任务
	if event == "PLAYER_ENTERING_WORLD" then
		for i = 1, C_QuestLog.GetNumQuestLogEntries() do
			local info = C_QuestLog.GetInfo(i); 
			if info and not info.isHeader and (info.isTask or not info.isHidden) then
				NameQuestTable[info.title] = not C_QuestLog.IsComplete(info.questID)
				QuestTitle[info.questID] = info.title
			end 
		end
		C_Timer.After(2, ns.RefreshNameQuest)
	end
	--任务进度更新
	if event == "QUEST_WATCH_UPDATE" then
		C_Timer.After(0.5,function()
			local title = C_QuestLog.GetTitleForQuestID(IDs)
			if not title then return end
			if NameQuestTable[title] == nil then return end --只处理已知任务（false = 已完成，也要刷新）
			NameQuestTable[title] = not C_QuestLog.IsComplete(IDs)
			ns.RefreshNameQuest()
		end)
	end
	if event == "QUEST_ACCEPTED" then
		C_Timer.After(0.5,function()
			if not C_QuestLog.GetLogIndexForQuestID(IDs) then return end
			local info = C_QuestLog.GetInfo(C_QuestLog.GetLogIndexForQuestID(IDs))
			if info and not info.isHeader and (info.isTask or not info.isHidden) then
				NameQuestTable[info.title] = not C_QuestLog.IsComplete(IDs)
				QuestTitle[IDs] = info.title
				ns.RefreshNameQuest()
			end
		end)
		
	end
	if event == "QUEST_REMOVED" then
		C_Timer.After(0.5,function()
			local title = C_QuestLog.GetTitleForQuestID(IDs) or QuestTitle[IDs]
			if title then
				NameQuestTable[title] = nil
			end
			QuestTitle[IDs] = nil
			ns.RefreshNameQuest()
		end)
	end
	--交任务后 NPC 的任务状态变了，清缓存重算
	if event == "QUEST_TURNED_IN" then
		C_Timer.After(0.5,function()
			local title = C_QuestLog.GetTitleForQuestID(IDs) or QuestTitle[IDs]
			if title then
				NameQuestTable[title] = nil
			end
			QuestTitle[IDs] = nil
			ns.RefreshNameQuest()
		end)
	end
end

ns.event("NAME_PLATE_UNIT_ADDED", QuestMarkEvent)
ns.event("PLAYER_ENTERING_WORLD", QuestMarkEvent)
ns.event("QUEST_WATCH_UPDATE", QuestMarkEvent)
ns.event("QUEST_ACCEPTED", QuestMarkEvent)
ns.event("QUEST_REMOVED", QuestMarkEvent)
ns.event("QUEST_TURNED_IN", QuestMarkEvent)